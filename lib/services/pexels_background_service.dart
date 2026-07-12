import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PexelsBackgroundService {
  static const _apiKey = 'TAX5AQ6Abeg8jke8sVjAqMJSQmn2qsmlDi8RTY43kYYvu019Aar9RpBr';
  static const _baseUrl = 'https://api.pexels.com/v1/search';

  static final _queries = [
    'mosque interior',
    'grand mosque',
    'islamic architecture',
    'blue mosque',
    'mosque at sunset',
    'mosque dome minaret',
    'quran pages',
    'quran on stand',
    'open quran reading',
    'prayer mat mosque',
    'muslim praying silhouette',
    'ramadan lantern',
    'ramadan kareem lights',
    'crescent moon mosque',
    'eid mubarak celebration',
    'arabic calligraphy allah',
    'islamic geometric pattern',
    'arabesque ornament',
    'tasbih prayer beads',
    'kaaba mecca',
    'masjid al haram',
    'medina mosque',
    'masjid an nabawi',
    'hajj pilgrimage',
    'umrah tawaf',
    'mosque courtyard',
    'mihrab prayer hall',
    'stained glass mosque',
    'sunrise mosque',
    'sunset mosque',
    'desert mosque',
    'islamic arches',
    'ottoman mosque',
    'mosque minaret night',
    'bismillah calligraphy',
  ];

  static final instance = PexelsBackgroundService._();
  PexelsBackgroundService._();

  String? _cachedUrl;
  bool _loading = false;

  final ValueNotifier<String?> imageUrlNotifier = ValueNotifier<String?>(null);

  String? get imageUrl => _cachedUrl;

  Future<void> init() async {
    if (_loading) return;
    _loading = true;
    _cachedUrl = null;
    imageUrlNotifier.value = null;
    try {
      final rng = Random();
      final query = _queries[rng.nextInt(_queries.length)];
      final uri = Uri.parse('$_baseUrl?query=${Uri.encodeComponent(query)}&per_page=15&orientation=landscape');
      final response = await http.get(uri, headers: {'Authorization': _apiKey});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final photos = data['photos'] as List?;
        if (photos != null && photos.isNotEmpty) {
          final photo = photos[rng.nextInt(photos.length)];
          _cachedUrl = photo['src']['large2x'] ?? photo['src']['large'];
          imageUrlNotifier.value = _cachedUrl;
          debugPrint('PexelsBackgroundService: loaded image from "$query" -> $_cachedUrl');
        }
      } else {
        debugPrint('PexelsBackgroundService: API error ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('PexelsBackgroundService: failed to load: $e');
    } finally {
      _loading = false;
    }
  }
}
