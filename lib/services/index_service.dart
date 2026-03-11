import 'dart:io';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class IndexService {
  IndexService._();
  static final IndexService instance = IndexService._();

  File? _cacheFile;
  final Map<String, _IndexedDoc> _docsByPath = {};
  bool _isLoaded = false;

  Future<void> init() async {
    if (_isLoaded) return;
    final dir = await getApplicationSupportDirectory();
    _cacheFile = File(p.join(dir.path, 'document_search_index.json'));
    if (await _cacheFile!.exists()) {
      final raw = await _cacheFile!.readAsString();
      if (raw.trim().isNotEmpty) {
        final parsed = jsonDecode(raw) as Map<String, dynamic>;
        final docs = (parsed['docs'] as List<dynamic>? ?? const []);
        for (final item in docs) {
          final doc = _IndexedDoc.fromJson(item as Map<String, dynamic>);
          _docsByPath[doc.path] = doc;
        }
      }
    }
    _isLoaded = true;
  }

  Future<void> clearCache() async {
    await init();
    _docsByPath.clear();
    final file = _cacheFile;
    if (file != null && await file.exists()) {
      await file.delete();
    }
  }

  Future<void> indexFile({
    required String path,
    required String name,
    required String content,
  }) async {
    if (!_isLoaded) {
      await init();
    }
    _docsByPath[path] = _IndexedDoc(path: path, name: name, content: content);
    await _save();
  }

  Future<List<String>> getIndexedPaths() async {
    if (!_isLoaded) {
      await init();
    }
    final paths = _docsByPath.keys.toList(growable: false)..sort();
    return paths;
  }

  Future<List<SearchHit>> search(String query, {int limit = 0}) async {
    if (!_isLoaded) {
      await init();
    }
    final terms = _buildTerms(query);
    if (terms.isEmpty) return [];
    final hits = <SearchHit>[];
    for (final doc in _docsByPath.values) {
      final searchable = '${doc.path} ${doc.name} ${doc.content}'.toLowerCase();
      final hasAllTerms = terms.every(searchable.contains);
      if (!hasAllTerms) continue;
      hits.add(
        SearchHit(
          path: doc.path,
          snippet: _snippet(doc.content, terms),
        ),
      );
      if (limit > 0 && hits.length >= limit) break;
    }
    return hits;
  }

  List<String> _buildTerms(String raw) {
    final cleaned = raw
        .toLowerCase()
        .replaceAll('"', ' ')
        .replaceAll("'", ' ')
        .trim();
    if (cleaned.isEmpty) return const [];
    return cleaned
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList(growable: false);
  }

  String _snippet(String content, List<String> terms) {
    if (content.isEmpty) return '';
    final lower = content.toLowerCase();
    int firstMatch = -1;
    for (final term in terms) {
      final idx = lower.indexOf(term);
      if (idx != -1 && (firstMatch == -1 || idx < firstMatch)) {
        firstMatch = idx;
      }
    }
    if (firstMatch == -1) return '';
    final start = (firstMatch - 40).clamp(0, content.length);
    final end = (firstMatch + 120).clamp(0, content.length);
    final text = content.substring(start, end).trim();
    return start > 0 ? '…$text' : text;
  }

  Future<void> _save() async {
    final file = _cacheFile;
    if (file == null) return;
    final docs = _docsByPath.values.map((e) => e.toJson()).toList(growable: false);
    await file.writeAsString(jsonEncode({'docs': docs}));
  }
}

class SearchHit {
  final String path;
  final String? snippet;
  SearchHit({required this.path, this.snippet});
}

class _IndexedDoc {
  final String path;
  final String name;
  final String content;

  _IndexedDoc({
    required this.path,
    required this.name,
    required this.content,
  });

  factory _IndexedDoc.fromJson(Map<String, dynamic> json) {
    return _IndexedDoc(
      path: (json['path'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'content': content,
    };
  }
}
