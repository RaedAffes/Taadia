import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

class QuranCache {
  static const _prefix = 'quran_svg_';
  static const _metaKey = 'quran_completed';

  Future<void> init() async {}

  Future<String?> getPage(int page) async {
    try {
      return html.window.localStorage['$_prefix$page'];
    } catch (_) {
      return null;
    }
  }

  Future<void> savePage(int page, String svg) async {
    try {
      html.window.localStorage['$_prefix$page'] = svg;
    } catch (_) {}
  }

  Future<Set<int>> getCompletedPages() async {
    try {
      final raw = html.window.localStorage[_metaKey];
      if (raw == null || raw.isEmpty) return {};
      final list = (jsonDecode(raw) as List).map((e) => (e as num).toInt());
      return list.toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> saveCompletedPages(Set<int> pages) async {
    try {
      html.window.localStorage[_metaKey] = jsonEncode(pages.toList());
    } catch (_) {}
  }
}
