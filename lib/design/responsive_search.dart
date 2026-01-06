import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:file_selector/file_selector.dart';
import 'package:document_search/design/responsive_design.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class IndexedFile {
  final String path;
  String content;
  IndexedFile({required this.path, this.content = ''});
}

class ResponsiveSearchField extends StatefulWidget {
  @override
  State<ResponsiveSearchField> createState() => _ResponsiveSearchFieldState();
}

class _ResponsiveSearchFieldState extends State<ResponsiveSearchField> {
  final TextEditingController _controller = TextEditingController();
  bool _isFocused = false;
  bool _isLoading = false;
  bool _hasScanned = false;

  List<IndexedFile> _allFiles = [];
  List<IndexedFile> _results = [];

  @override
  void initState() {
    super.initState();
  }

  /// Recursively scan a directory asynchronously
  Future<void> _scanDirectory(Directory dir, StreamController<IndexedFile> stream) async {
    try {
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final pathLower = entity.path.toLowerCase();
          if (pathLower.endsWith('.pdf') ||
              pathLower.endsWith('.docx') ||
              pathLower.endsWith('.doc')) {
            print('Document found: ${entity.path}');
            stream.add(IndexedFile(path: entity.path));
          }
        }
      }
    } catch (_) {
      // Ignore permission errors
    }
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


  /// Scan a selected directory
  void _scanSelectedDirectory(Directory dir) async {
    setState(() {
      _isLoading = true;
      _allFiles.clear();
      _results.clear();
      _hasScanned = true;
    });

    final controller = StreamController<IndexedFile>();

    controller.stream.listen((file) {
      setState(() {
        _allFiles.add(file);
        _results = List.from(_allFiles);
      });
    }, onDone: () {
      setState(() => _isLoading = false);
    });

    await _scanDirectory(dir, controller);
    await controller.close();
  }

  /// Perform search (lazy load content)
  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = List.from(_allFiles));
      return;
    }

    final normalizedQuery = normalizeText(query);
    List<IndexedFile> filtered = [];

    for (var file in _allFiles) {
      // 1️⃣ Check file name
      if (file.path.toLowerCase().contains(normalizedQuery)) {
        filtered.add(file);
        continue;
      }

      // 2️⃣ Extract text lazily
      if (file.content.isEmpty) {
        try {
          String rawContent = '';

          if (file.path.toLowerCase().endsWith('.pdf')) {
            // Use Syncfusion PDF text extraction
            final bytes = File(file.path).readAsBytesSync();
            final document = PdfDocument(inputBytes: bytes);

            rawContent = PdfTextExtractor(document).extractText();

            document.dispose();
          } else if (file.path.toLowerCase().endsWith('.docx') ||
              file.path.toLowerCase().endsWith('.doc')) {
            rawContent = docxToText(
              File(file.path).readAsBytesSync(),
            );
          }

          file.content = normalizeText(rawContent);
        } catch (e) {
          // Ignore files that fail
          continue;
        }
      }

      // 3️⃣ Search normalized content
      if (file.content.contains(normalizedQuery)) {
        filtered.add(file);
      }
    }

    setState(() => _results = filtered);
  }


  TextSpan _highlight(String text, String query) {
    if (query.isEmpty) return TextSpan(text: text);

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    List<TextSpan> spans = [];
    int start = 0;
    int index;
    while ((index = lowerText.indexOf(lowerQuery, start)) != -1) {
      spans.add(TextSpan(text: text.substring(start, index)));
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: const TextStyle(
          backgroundColor: Colors.yellow,
          fontWeight: FontWeight.bold,
        ),
      ));
      start = index + query.length;
    }
    spans.add(TextSpan(text: text.substring(start)));
    return TextSpan(children: spans);
  }

  Icon _getFileIcon(String path) {
    final pathLower = path.toLowerCase();
    if (pathLower.endsWith('.pdf')) return const Icon(Icons.picture_as_pdf, color: Colors.red);
    if (pathLower.endsWith('.doc') || pathLower.endsWith('.docx')) return const Icon(Icons.description, color: Colors.blue);
    return const Icon(Icons.insert_drive_file);
  }

  /// Open folder picker
  Future<void> _pickDirectory() async {
    final directoryPath = await getDirectoryPath();
    if (directoryPath != null) {
      _scanSelectedDirectory(Directory(directoryPath));
    }
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

    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _pickDirectory,
          icon: const Icon(Icons.folder_open),
          label: const Text('Select Drive / Folder to Scan'),
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
                    onChanged: _performSearch,
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
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Scanning documents...'),
            ],
          ),
        ),
      );
    }

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
                final fileName = file.path.split('/').last;
                final query = _controller.text;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  elevation: 1,
                  child: ListTile(
                    leading: _getFileIcon(file.path),
                    title: RichText(
                      text: _highlight(fileName, query),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.path,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        if (file.content.isNotEmpty && query.isNotEmpty)
                          const SizedBox(height: 4),
                        if (file.content.isNotEmpty && query.isNotEmpty)
                          RichText(
                            text: _highlight(
                              file.content.length > 100
                                  ? '${file.content.substring(0, 100)}...'
                                  : file.content,
                              query,
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