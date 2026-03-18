import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:file_selector/file_selector.dart';
import 'package:document_search/design/responsive_design.dart';
import 'package:document_search/services/index_service.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:excel/excel.dart' as excel;

class IndexedFile {
  final String path;
  String content;
  String snippet;
  IndexedFile({required this.path, this.content = '', this.snippet = ''});
}

class ResponsiveSearchField extends StatefulWidget {
  const ResponsiveSearchField({super.key});

  @override
  State<ResponsiveSearchField> createState() => _ResponsiveSearchFieldState();
}

class _ResponsiveSearchFieldState extends State<ResponsiveSearchField> {
  static const bool _enablePersistentIndex = false;
  final TextEditingController _controller = TextEditingController();
  bool _isFocused = false;
  bool _isLoading = false;
  bool _hasScanned = false;
  bool _preloadAfterScan = true;
  bool _isPreloading = false;
  bool _cancelPreload = false;
  int _preloadedCount = 0;
  bool _cancelScan = false;
  bool _autoScanRequested = false;
  String _scanStatus = '';
  int _activeSearchFileCounter = 0;
  static const int _searchUpdateEveryNFiles = 5;
  bool _searchContentLoading = false;
  int _searchContentToken = 0;
  Timer? _searchDebounce;
  bool _isSearching = false;
  int _searchToken = 0;
  int _scanUpdateCounter = 0;

  List<IndexedFile> _allFiles = [];
  List<IndexedFile> _results = [];
  bool _hasPersistentIndex = false;

  bool get _isDesktopPlatform =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    _enabledExtensions = {
      '.pdf',
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
    };
    _initializeIndexAndCache();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  static const int _maxTextBytes = 20 * 1024 * 1024;
  static const Set<String> _supportedExtensions = {
    '.pdf',
    '.docx',
    '.doc',
    '.xlsx',
    '.xls',
    '.txt',
    '.csv',
    '.md',
  };
  static const Map<String, Set<String>> _typeGroups = {
    'PDF': {'.pdf'},
    'DOC': {'.doc', '.docx'},
    'XLS': {'.xls', '.xlsx'},
    'TXT': {'.txt'},
    'CSV': {'.csv'},
    'MD': {'.md'},
  };

  late Set<String> _enabledExtensions;

  Future<void> _initializeIndexAndCache() async {
    if (!_isDesktopPlatform) return;
    if (_enablePersistentIndex) {
      await IndexService.instance.init();
      final cachedPaths = await IndexService.instance.getIndexedPaths();
      if (!mounted) return;
      if (cachedPaths.isNotEmpty) {
        setState(() {
          _allFiles = cachedPaths.map((p) => IndexedFile(path: p)).toList();
          _results = _allFiles.where((f) => _isTypeEnabled(f.path)).toList();
          _hasScanned = true;
          _hasPersistentIndex = true;
        });
      }
    } else {
      await IndexService.instance.clearCache();
      if (!mounted) return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_enablePersistentIndex && _hasPersistentIndex) {
        _syncMissingFromSystem();
      } else {
        _autoScanAllDrivesOnFirstLaunch();
      }
    });
  }

  /// Recursively scan a directory asynchronously
  Future<void> _scanDirectory(Directory dir, StreamController<IndexedFile> stream) async {
    try {
      final queue = <Directory>[dir];
      while (queue.isNotEmpty) {
        if (_cancelScan) break;
        final current = queue.removeLast();
        await for (var entity in current.list(followLinks: false)) {
          if (_cancelScan) break;
          if (entity is Directory) {
            if (_shouldSkipDir(entity.path)) continue;
            queue.add(entity);
            continue;
          }
          if (entity is File) {
            final pathLower = entity.path.toLowerCase();
            final ext = _getExtension(pathLower);
            if (_supportedExtensions.contains(ext)) {
              stream.add(IndexedFile(path: entity.path));
            }
          }
        }
      }
    } catch (_) {
      // Ignore permission errors
    }
  }

  Future<void> _scanDirectoryForMissing(
    Directory dir,
    Set<String> knownPaths,
    List<IndexedFile> discovered,
  ) async {
    try {
      final queue = <Directory>[dir];
      while (queue.isNotEmpty) {
        if (_cancelScan) break;
        final current = queue.removeLast();
        await for (final entity in current.list(followLinks: false)) {
          if (_cancelScan) break;
          if (entity is Directory) {
            if (_shouldSkipDir(entity.path)) continue;
            queue.add(entity);
            continue;
          }
          if (entity is! File) continue;
          final pathLower = entity.path.toLowerCase();
          final ext = _getExtension(pathLower);
          if (!_supportedExtensions.contains(ext)) continue;
          if (knownPaths.contains(pathLower)) continue;
          knownPaths.add(pathLower);
          discovered.add(IndexedFile(path: entity.path));
        }
      }
    } catch (_) {
      // Ignore permission errors.
    }
  }

  String _getExtension(String pathLower) {
    final lastDot = pathLower.lastIndexOf('.');
    if (lastDot == -1) return '';
    return pathLower.substring(lastDot);
  }

  bool _isTypeEnabled(String path) {
    final ext = _getExtension(path.toLowerCase());
    return _enabledExtensions.contains(ext);
  }

  bool _shouldSkipDir(String path) {
    return false;
  }

  String normalizeText(String text) {
    return text
        .toLowerCase()
    // Remove hyphenated line breaks: com-\nplete → complete
        .replaceAll(RegExp(r'-\s*\n\s*'), '')
    // Replace all newlines/tabs with space
        .replaceAll(RegExp(r'[\n\r\t]+'), ' ')
    // Replace multiple spaces with single space
        .replaceAll(RegExp(r'\s{2,}'), ' ')
    // Remove non-breaking spaces
        .replaceAll('\u00A0', ' ')
        .trim();
  }

  String _readTextFile(String path) {
    final bytes = File(path).readAsBytesSync();
    if (bytes.length > _maxTextBytes) {
      return '';
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  String _extractExcelText(String path) {
    final bytes = File(path).readAsBytesSync();
    if (bytes.length > _maxTextBytes) {
      return '';
    }
    final book = excel.Excel.decodeBytes(bytes);
    final buffer = StringBuffer();
    for (final table in book.tables.values) {
      for (final row in table.rows) {
        for (final cell in row) {
          if (cell != null && cell.value != null) {
            buffer.write(cell.value.toString());
            buffer.write(' ');
          }
        }
      }
    }
    return buffer.toString();
  }

  String _extractContent(String path) {
    String rawContent = '';
    final lower = path.toLowerCase();
    final file = File(path);
    final fileSize = file.lengthSync();
    if (fileSize > _maxTextBytes) {
      return '';
    }
    if (lower.endsWith('.pdf')) {
      final bytes = file.readAsBytesSync();
      final document = PdfDocument(inputBytes: bytes);
      rawContent = PdfTextExtractor(document).extractText();
      document.dispose();
    } else if (lower.endsWith('.docx') || lower.endsWith('.doc')) {
      rawContent = docxToText(file.readAsBytesSync());
    } else if (lower.endsWith('.xlsx') || lower.endsWith('.xls')) {
      rawContent = _extractExcelText(path);
    } else if (lower.endsWith('.txt') ||
        lower.endsWith('.csv') ||
        lower.endsWith('.md')) {
      rawContent = _readTextFile(path);
    }
    return rawContent;
  }

  /// Scan a selected directory
  void _scanSelectedDirectory(Directory dir) async {
    setState(() {
      _isLoading = true;
      _allFiles.clear();
      _results.clear();
      _hasScanned = true;
      _isPreloading = false;
      _cancelPreload = false;
      _preloadedCount = 0;
      _cancelScan = false;
      _scanUpdateCounter = 0;
      _hasPersistentIndex = false;
      _scanStatus = 'Scanning: ${dir.path}';
    });

    final controller = StreamController<IndexedFile>();

    controller.stream.listen((file) {
      _allFiles.add(file);
      _scanUpdateCounter += 1;
      final query = _controller.text.trim();
      if (mounted && query.isEmpty) {
        setState(() {
          _results = _allFiles.where((f) => _isTypeEnabled(f.path)).toList();
        });
      }
      _processFileForActiveSearch(file);
    }, onDone: () async {
      setState(() {
        if (_controller.text.trim().isEmpty) {
          _results = _allFiles.where((f) => _isTypeEnabled(f.path)).toList();
        }
        _isLoading = false;
        _scanStatus = '';
      });
      if (_controller.text.trim().isNotEmpty) {
        _scheduleSearch(_controller.text);
      }
      await _preloadAllContents(keepInMemory: _preloadAfterScan);
    });

    await _scanDirectory(dir, controller);
    await controller.close();
  }

  Future<void> _scanMultipleDirectories(List<Directory> dirs) async {
    setState(() {
      _isLoading = true;
      _allFiles.clear();
      _results.clear();
      _hasScanned = true;
      _isPreloading = false;
      _cancelPreload = false;
      _preloadedCount = 0;
      _cancelScan = false;
      _scanUpdateCounter = 0;
      _hasPersistentIndex = false;
      _scanStatus = '';
    });

    final controller = StreamController<IndexedFile>();

    controller.stream.listen((file) {
      _allFiles.add(file);
      _scanUpdateCounter += 1;
      final query = _controller.text.trim();
      if (mounted && query.isEmpty) {
        setState(() {
          _results = _allFiles.where((f) => _isTypeEnabled(f.path)).toList();
        });
      }
      _processFileForActiveSearch(file);
    }, onDone: () async {
      setState(() {
        if (_controller.text.trim().isEmpty) {
          _results = _allFiles.where((f) => _isTypeEnabled(f.path)).toList();
        }
        _isLoading = false;
        _scanStatus = '';
      });
      if (_controller.text.trim().isNotEmpty) {
        _scheduleSearch(_controller.text);
      }
      await _preloadAllContents(keepInMemory: _preloadAfterScan);
    });

    for (final dir in dirs) {
      if (_cancelScan) break;
      if (mounted) {
        setState(() {
          _scanStatus = 'Scanning: ${dir.path}';
        });
      }
      await _scanDirectory(dir, controller);
      final query = _controller.text.trim();
      if (mounted && query.isEmpty) {
        setState(() {
          _results = _allFiles.where((f) => _isTypeEnabled(f.path)).toList();
        });
      }
    }
    await controller.close();
  }

  Future<void> _preloadAllContents({bool keepInMemory = true}) async {
    if (_allFiles.isEmpty) return;
    setState(() {
      _isPreloading = true;
      _cancelPreload = false;
      _preloadedCount = 0;
    });

    var lastUiUpdate = DateTime.now();
    for (final file in _allFiles) {
      if (_cancelPreload) break;
      if (file.content.isEmpty) {
        try {
          final rawContent = _extractContent(file.path);
          file.content = normalizeText(rawContent);
        } catch (_) {
          // Ignore files that fail
        }
      }
      if (_enablePersistentIndex) {
        try {
          await IndexService.instance.indexFile(
            path: file.path,
            name: p.basename(file.path),
            content: file.content,
          );
        } catch (_) {
          // Ignore index failures and keep app responsive.
        }
      }
      if (!keepInMemory) {
        file.content = '';
      }
      _preloadedCount += 1;
      if (mounted) {
        final now = DateTime.now();
        if (_preloadedCount % 50 == 0 ||
            now.difference(lastUiUpdate).inMilliseconds > 200) {
          lastUiUpdate = now;
          setState(() {});
        }
      }
    }

    if (mounted) {
      setState(() {
        _isPreloading = false;
        _hasPersistentIndex = true;
      });
    }
  }

  Future<void> _preloadFiles(List<IndexedFile> files, {bool keepInMemory = true}) async {
    if (files.isEmpty) return;
    setState(() {
      _isPreloading = true;
      _cancelPreload = false;
      _preloadedCount = 0;
    });

    var lastUiUpdate = DateTime.now();
    for (final file in files) {
      if (_cancelPreload) break;
      if (file.content.isEmpty) {
        try {
          final rawContent = _extractContent(file.path);
          file.content = normalizeText(rawContent);
        } catch (_) {
          // Ignore files that fail
        }
      }
      if (_enablePersistentIndex) {
        try {
          await IndexService.instance.indexFile(
            path: file.path,
            name: p.basename(file.path),
            content: file.content,
          );
        } catch (_) {
          // Ignore index failures and keep app responsive.
        }
      }
      if (!keepInMemory) {
        file.content = '';
      }
      _preloadedCount += 1;
      if (mounted) {
        final now = DateTime.now();
        if (_preloadedCount % 50 == 0 ||
            now.difference(lastUiUpdate).inMilliseconds > 200) {
          lastUiUpdate = now;
          setState(() {});
        }
      }
    }

    if (mounted) {
      setState(() {
        _isPreloading = false;
        _hasPersistentIndex = true;
      });
    }
  }

  /// Perform search (lazy load content)
  void _performSearch(String query) async {
    final activeFiles = _allFiles.where((f) => _isTypeEnabled(f.path)).toList();

    if (query.trim().isEmpty) {
      setState(() {
        _results = List.from(activeFiles);
        _isSearching = false;
      });
      return;
    }

    final normalizedQuery = normalizeText(query);
    setState(() => _isSearching = true);
    final token = ++_searchToken;
    _startSearchContentLoad(query);

    if (_isDesktopPlatform && _enablePersistentIndex && _hasPersistentIndex) {
      try {
        final hits = await IndexService.instance.search(query);
        if (!mounted || token != _searchToken) return;
        final byPath = {for (final f in activeFiles) f.path: f};
        final filtered = <IndexedFile>[];
        for (final hit in hits) {
          final file = byPath[hit.path];
          if (file == null) continue;
          file.snippet = hit.snippet ?? '';
          filtered.add(file);
        }
        setState(() {
          _results = filtered;
          _isSearching = false;
        });
        return;
      } catch (_) {
        // Fall back to in-memory search if DB is unavailable.
      }
    }

    final items = activeFiles.map((f) {
      return {
        'path': f.path,
        'pathLower': f.path.toLowerCase(),
        'content': f.content,
      };
    }).toList(growable: false);

    final matches = await compute(_searchInIsolate, {
      'query': normalizedQuery,
      'items': items,
    });

    if (!mounted || token != _searchToken) return;

    final byPath = {for (final f in activeFiles) f.path: f};
    final filtered = <IndexedFile>[];
    for (final path in matches) {
      final file = byPath[path];
      if (file != null) filtered.add(file);
    }

    setState(() {
      _results = filtered;
      _isSearching = false;
    });
  }

  void _scheduleSearch(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _performSearch(query);
    });
  }

  void _processFileForActiveSearch(IndexedFile file) {
    final query = _controller.text.trim();
    if (query.isEmpty || _cancelScan) return;
    _activeSearchFileCounter += 1;
    final shouldTriggerSearch =
        _activeSearchFileCounter % _searchUpdateEveryNFiles == 0;
    if (file.content.isNotEmpty) {
      if (shouldTriggerSearch) {
        _scheduleSearch(query);
      }
      return;
    }
    Future(() {
      if (_cancelScan) return;
      try {
        final rawContent = _extractContent(file.path);
        file.content = normalizeText(rawContent);
      } catch (_) {
        // Ignore extraction failures for live search.
      }
    }).then((_) {
      if (!mounted) return;
      if (_controller.text.trim() == query && shouldTriggerSearch) {
        _scheduleSearch(query);
      }
    });
  }

  void _startSearchContentLoad(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    if (_searchContentLoading) return;
    _searchContentLoading = true;
    final token = ++_searchContentToken;

    Future(() async {
      final activeFiles = _allFiles.where((f) => _isTypeEnabled(f.path)).toList();
      var processed = 0;
      for (final file in activeFiles) {
        if (!mounted) break;
        if (_controller.text.trim() != trimmed) break;
        if (token != _searchContentToken) break;
        if (file.content.isEmpty) {
          try {
            final rawContent = _extractContent(file.path);
            file.content = normalizeText(rawContent);
          } catch (_) {
            // Ignore extraction failures during live search.
          }
        }
        processed += 1;
        if (processed % _searchUpdateEveryNFiles == 0) {
          _scheduleSearch(trimmed);
          await Future.delayed(const Duration(milliseconds: 1));
        }
      }
    }).whenComplete(() {
      _searchContentLoading = false;
    });
  }


  TextSpan _highlight(String text, String query, Color baseColor) {
    if (query.isEmpty) {
      return TextSpan(text: text, style: TextStyle(color: baseColor));
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    List<TextSpan> spans = [];
    int start = 0;
    int index;
    while ((index = lowerText.indexOf(lowerQuery, start)) != -1) {
      spans.add(TextSpan(
        text: text.substring(start, index),
        style: TextStyle(color: baseColor),
      ));
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          color: Colors.black,
          backgroundColor: Colors.yellow,
          fontWeight: FontWeight.bold,
        ),
      ));
      start = index + query.length;
    }
    spans.add(TextSpan(
      text: text.substring(start),
      style: TextStyle(color: baseColor),
    ));
    return TextSpan(style: TextStyle(color: baseColor), children: spans);
  }

  String _snippetFromContent(String content, String query) {
    final trimmed = query.trim();
    if (content.isEmpty || trimmed.isEmpty) return '';
    final lowerContent = content.toLowerCase();
    final terms = trimmed
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList(growable: false);
    if (terms.isEmpty) return '';
    int firstMatch = -1;
    for (final term in terms) {
      final idx = lowerContent.indexOf(term);
      if (idx != -1 && (firstMatch == -1 || idx < firstMatch)) {
        firstMatch = idx;
      }
    }
    if (firstMatch == -1) return '';
    final start = (firstMatch - 40).clamp(0, content.length);
    final end = (firstMatch + 120).clamp(0, content.length);
    final snippet = content.substring(start, end).trim();
    return start > 0 ? '…$snippet' : snippet;
  }

  Icon _getFileIcon(String path) {
    final pathLower = path.toLowerCase();
    if (pathLower.endsWith('.pdf')) return const Icon(Icons.picture_as_pdf, color: Colors.red);
    if (pathLower.endsWith('.doc') || pathLower.endsWith('.docx')) return const Icon(Icons.description, color: Colors.blue);
    if (pathLower.endsWith('.xlsx') || pathLower.endsWith('.xls')) return const Icon(Icons.table_chart, color: Colors.green);
    if (pathLower.endsWith('.txt') || pathLower.endsWith('.csv') || pathLower.endsWith('.md')) return const Icon(Icons.text_snippet, color: Colors.teal);
    return const Icon(Icons.insert_drive_file);
  }

  /// Open folder picker
  Future<void> _pickDirectory() async {
    final directoryPath = await getDirectoryPath();
    if (directoryPath != null) {
      _scanSelectedDirectory(Directory(directoryPath));
    }
  }

  Future<void> _scanSystemDocuments() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan all drives?'),
        content: const Text(
          'This can take a long time and may use a lot of CPU.\n'
          'Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final roots = _getSystemRoots();
    if (roots.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No system roots found to scan.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    await _scanMultipleDirectories(roots);
  }

  Future<void> _autoScanAllDrivesOnFirstLaunch() async {
    if (_autoScanRequested) return;
    if (!_isDesktopPlatform) return;
    _autoScanRequested = true;

    final roots = _getSystemRoots();
    if (roots.isEmpty) return;
    await _scanMultipleDirectories(roots);
  }

  Future<void> _clearCacheManually() async {
    if (_isLoading || _isPreloading) return;
    await IndexService.instance.clearCache();
    if (!mounted) return;
    setState(() {
      _allFiles.clear();
      _results.clear();
      _hasScanned = false;
      _hasPersistentIndex = false;
      _scanStatus = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache cleared. Please scan again.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _syncMissingFromSystem() async {
    if (_autoScanRequested) return;
    if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) return;
    _autoScanRequested = true;

    final roots = _getSystemRoots();
    if (roots.isEmpty) return;

    setState(() {
      _isLoading = true;
      _cancelScan = false;
      _scanStatus = '';
    });

    final knownPaths = _allFiles.map((f) => f.path.toLowerCase()).toSet();
    final discovered = <IndexedFile>[];
    for (final root in roots) {
      if (_cancelScan) break;
      if (mounted) {
        setState(() {
          _scanStatus = 'Scanning: ${root.path}';
        });
      }
      await _scanDirectoryForMissing(root, knownPaths, discovered);
    }

    if (!mounted) return;
    setState(() {
      if (discovered.isNotEmpty) {
        _allFiles.addAll(discovered);
        _hasScanned = true;
        _hasPersistentIndex = false;
      }
      _results = _allFiles.where((f) => _isTypeEnabled(f.path)).toList();
      _isLoading = false;
      _scanStatus = '';
    });

    if (discovered.isNotEmpty) {
      await _preloadFiles(discovered, keepInMemory: _preloadAfterScan);
    }
  }

  List<Directory> _getSystemRoots() {
    final roots = <Directory>[];
    final seen = <String>{};

    void addIfExists(String path) {
      if (path.isEmpty) return;
      final normalized = path.toLowerCase();
      if (seen.contains(normalized)) return;
      final dir = Directory(path);
      if (dir.existsSync()) {
        roots.add(dir);
        seen.add(normalized);
      }
    }

    if (Platform.isWindows) {
      final systemDrive = (Platform.environment['SystemDrive'] ?? 'C:')
          .replaceAll('\\', '')
          .replaceAll('/', '')
          .toUpperCase();
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null && userProfile.isNotEmpty) {
        addIfExists('$userProfile\\Documents');
        addIfExists('$userProfile\\Downloads');
        addIfExists('$userProfile\\Desktop');
      }
      addIfExists('$systemDrive:\\');
      for (var i = 65; i <= 90; i++) {
        final letter = String.fromCharCode(i);
        if (letter == systemDrive) continue;
        final path = '$letter:\\';
        addIfExists(path);
      }
      return roots;
    }
    if (Platform.isMacOS || Platform.isLinux) {
      final home = Platform.environment['HOME'] ?? '';
      if (home.isNotEmpty) {
        addIfExists('$home/Documents');
        addIfExists('$home/Downloads');
        addIfExists('$home/Desktop');
      }
      if (Platform.isMacOS) {
        addIfExists('/');
        addIfExists('/Volumes');
        return roots;
      }
      addIfExists('/home');
      addIfExists('/');
      addIfExists('/media');
      addIfExists('/mnt');
      return roots;
    }
    return [];
  }
  Future<void> _openFileFromPath(String filePath) async {
    try {
      // Create File object from the path
      final file = File(filePath);

      // Check if file exists
      if (await file.exists()) {
        // Use open_file package to open the file
        final result = await OpenFile.open(file.path);

        // If open_file fails, try url_launcher as fallback
        if (result.type != ResultType.done) {
          final uri = Uri.file(file.path);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          } else {
            // Show error if both methods fail
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cannot open file: ${file.path}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } else {
        // Show error if file doesn't exist
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File not found: ${file.path}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Show error if any exception occurs
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    final isNarrow = width < 700;

    return Column(
      children: [
        Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveDesign.searchFieldWidth(context),
            ),
            child: isNarrow
                ? Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _pickDirectory,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Select Drive / Folder'),
                        ),
                      ),
                      if (isDesktop) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _scanSystemDocuments,
                            icon: const Icon(Icons.storage),
                            label: const Text('Scan All Drives'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _clearCacheManually,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Delete Cache'),
                          ),
                        ),
                      ],
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickDirectory,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Select Drive / Folder'),
                        ),
                      ),
                      if (isDesktop) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _scanSystemDocuments,
                            icon: const Icon(Icons.storage),
                            label: const Text('Scan All Drives'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _clearCacheManually,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Delete Cache'),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: ResponsiveDesign.searchFieldWidth(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Keep document text in memory after scan (faster search)',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              Switch(
                value: _preloadAfterScan,
                onChanged: (value) {
                  setState(() => _preloadAfterScan = value);
                },
              ),
            ],
          ),
        ),
        if (_isLoading || _isPreloading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isPreloading
                      ? 'Indexing in background (${_preloadedCount}/${_allFiles.length})'
                      : (_scanStatus.isNotEmpty
                          ? _scanStatus
                          : 'Scanning in background...'),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (_isLoading)
                  TextButton(
                    onPressed: () {
                      setState(() => _cancelScan = true);
                    },
                    child: const Text('Stop'),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        if (_hasScanned)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveDesign.searchFieldHorizontalPadding(context),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _enabledExtensions.length == _supportedExtensions.length,
                  onSelected: (value) {
                    setState(() {
                      _enabledExtensions = value
                          ? Set.of(_supportedExtensions)
                          : <String>{};
                    });
                    _performSearch(_controller.text);
                  },
                ),
                for (final entry in _typeGroups.entries)
                  FilterChip(
                    label: Text(entry.key),
                    selected: entry.value.every(_enabledExtensions.contains),
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _enabledExtensions.addAll(entry.value);
                        } else {
                          _enabledExtensions.removeAll(entry.value);
                        }
                      });
                      _performSearch(_controller.text);
                    },
                  ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveDesign.searchFieldHorizontalPadding(context),
          ),
          child: Container(
            width: ResponsiveDesign.searchFieldWidth(context),
            height: ResponsiveDesign.searchFieldHeight(context),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isFocused ? Colors.blue.shade400 : Colors.grey.shade300,
                width: _isFocused ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(
                  Icons.search,
                  color: Colors.grey.shade500,
                  size: ResponsiveDesign.iconSize(context),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      hintText: 'Search...',
                      hintStyle: TextStyle(
                        fontSize: ResponsiveDesign.textFieldFontSize(context),
                      ),
                    ),
                    style: TextStyle(
                      fontSize: ResponsiveDesign.textFieldFontSize(context),
                    ),
                    onChanged: _scheduleSearch,
                    onTap: () => setState(() => _isFocused = true),
                    onSubmitted: _performSearch,
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.clear,
                      size: ResponsiveDesign.iconSize(context),
                      color: Colors.grey.shade500,
                    ),
                    onPressed: () {
                      _controller.clear();
                      _performSearch('');
                    },
                  ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
        if (_isSearching)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Searching...',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        const SizedBox(height: 16),

        // RESULTS SECTION - MOVED OUTSIDE THE SEARCH FIELD
        if (_hasScanned || _results.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveDesign.searchFieldHorizontalPadding(context),
            ),
            child: _buildResultsSection(),
          ),
        ],
      ],
    );
  }

  Widget _buildResultsSection() {
    if (_results.isEmpty && _hasScanned) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Text(
            'No documents found',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Search Results (${_results.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  Text(
                    'Search: "${_controller.text}"',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final file = _results[index];
                final fileName = p.basename(file.path);
                final query = _controller.text;
                final querySnippet = _snippetFromContent(file.content, query);
                final subtitlePreview = query.isNotEmpty
                    ? querySnippet
                    : (file.content.length > 100
                        ? '${file.content.substring(0, 100)}...'
                        : file.content);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  elevation: 1,
                  child: ListTile(
                    leading: _getFileIcon(file.path),
                    title: RichText(
                      text: _highlight(fileName, query, Colors.blue.shade800),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: _highlight(
                            file.path,
                            query,
                            Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitlePreview.isNotEmpty && query.isNotEmpty)
                          const SizedBox(height: 4),
                        if (subtitlePreview.isNotEmpty && query.isNotEmpty)
                          RichText(
                            text: _highlight(
                              subtitlePreview,
                              query,
                              Colors.blue.shade700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    onTap: () {
                      // TODO: Implement file opening or preview
                      print('Tapped: ${file.path}');
                      _openFileFromPath(file.path);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

List<String> _searchInIsolate(Map<String, dynamic> args) {
  final query = args['query'] as String;
  final terms = query
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList(growable: false);
  final items = args['items'] as List<dynamic>;
  final matches = <String>[];

  for (final item in items) {
    final map = item as Map<String, dynamic>;
    final path = map['path'] as String;
    final pathLower = map['pathLower'] as String;
    final content = map['content'] as String;

    if (pathLower.contains(query)) {
      matches.add(path);
      continue;
    }
    if (content.isNotEmpty && content.contains(query)) {
      matches.add(path);
      continue;
    }
    if (terms.isNotEmpty) {
      final searchable = '$pathLower $content';
      final hasAllTerms = terms.every(searchable.contains);
      if (hasAllTerms) {
        matches.add(path);
      }
    }
  }

  return matches;
}
