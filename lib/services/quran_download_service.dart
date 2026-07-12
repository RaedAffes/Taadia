import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class QuranDownloadService {
  static const _baseUrl =
      'https://raw.githubusercontent.com/quranpedia/quran-svg/main/mushafs/qalon/kfqc/svg';
  static const totalPages = 604;
  static const _concurrency = 6;

  final Set<int> _downloading = {};
  final Set<int> _completed = {};
  final Map<int, String> _memoryCache = {};
  int _downloadedCount = 0;

  int get downloadedCount => _downloadedCount;
  int get totalToDownload => totalPages;
  bool get isComplete => _completed.length >= totalPages;

  double get progress => totalPages > 0 ? _completed.length / totalPages : 0;

  static final instance = QuranDownloadService._();
  QuranDownloadService._();

  Future<void> init() async {
    debugPrint('QuranDownloadService: init done (${_completed.length}/$totalPages cached)');
  }

  Future<String?> getLocalSvg(int page) async {
    return _memoryCache[page];
  }

  Future<void> downloadPage(int page) async {
    if (page < 1 || page > totalPages) return;
    if (_completed.contains(page) || _downloading.contains(page)) return;

    _downloading.add(page);
    try {
      final url = '$_baseUrl/${page.toString().padLeft(3, '0')}.svg';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        _memoryCache[page] = response.body;
        _completed.add(page);
        _downloadedCount = _completed.length;
        debugPrint('QuranDownloadService: page $page downloaded (${_completed.length}/$totalPages)');
      }
    } catch (e) {
      debugPrint('QuranDownloadService: failed to download page $page: $e');
    } finally {
      _downloading.remove(page);
    }
  }

  Future<void> startBackgroundDownload() async {
    final pagesToDownload = <int>[];
    for (var p = 1; p <= totalPages; p++) {
      if (!_completed.contains(p)) {
        pagesToDownload.add(p);
      }
    }

    if (pagesToDownload.isEmpty) {
      debugPrint('QuranDownloadService: all pages already cached');
      return;
    }

    debugPrint('QuranDownloadService: downloading ${pagesToDownload.length} pages in background');

    for (var i = 0; i < pagesToDownload.length; i += _concurrency) {
      final batch = pagesToDownload.sublist(
        i,
        (i + _concurrency).clamp(0, pagesToDownload.length),
      );
      await Future.wait(batch.map(downloadPage));
    }

    debugPrint('QuranDownloadService: background download complete! ${_completed.length}/$totalPages');
  }
}
