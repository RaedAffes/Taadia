import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

enum QuestionRangeType { allQuran, hizbRange, surahs, surahAyahRange, quarter, surahPages }

class QuestionRange {
  final QuestionRangeType type;
  final int? hizbFrom;
  final int? hizbTo;
  final List<int>? surahNumbers;
  final int? ayaFrom;
  final int? ayaTo;
  final List<int>? quarterNumbers;
  final int? pageFrom;
  final int? pageTo;

  QuestionRange({
    required this.type,
    this.hizbFrom,
    this.hizbTo,
    this.surahNumbers,
    this.ayaFrom,
    this.ayaTo,
    this.quarterNumbers,
    this.pageFrom,
    this.pageTo,
  });

  List<Map<String, dynamic>> buildPool(List<Map<String, dynamic>> verses) {
    switch (type) {
      case QuestionRangeType.allQuran:
        return List<Map<String, dynamic>>.from(verses);

      case QuestionRangeType.hizbRange:
        final hFrom = hizbFrom ?? 1;
        final hTo = hizbTo ?? 60;
        return verses.where((v) {
          final h = (v['hizb_no'] as num).toInt();
          return h >= hFrom && h <= hTo;
        }).toList();

      case QuestionRangeType.surahs: {
        final nums = surahNumbers;
        if (nums == null || nums.isEmpty) return [];
        final set = nums.toSet();
        return verses
            .where((v) => set.contains((v['sura_no'] as num).toInt()))
            .toList();
      }

      case QuestionRangeType.surahAyahRange: {
        final nums = surahNumbers;
        if (nums == null || nums.isEmpty) return [];
        final suraNo = nums.first;
        final aFrom = ayaFrom;
        final aTo = ayaTo;
        return verses.where((v) {
          if ((v['sura_no'] as num).toInt() != suraNo) return false;
          final aya = (v['aya_no'] as num).toInt();
          if (aFrom != null && aya < aFrom) return false;
          if (aTo != null && aya > aTo) return false;
          return true;
        }).toList();
      }

      case QuestionRangeType.quarter: {
        final qs = quarterNumbers;
        if (qs == null || qs.isEmpty) return [];
        const surahRanges = [
          (1, 6),     // Q1: Al-Fatiha to Al-An'am
          (7, 18),    // Q2: Al-A'raf to Al-Kahf
          (19, 35),   // Q3: Maryam to Fatir
          (36, 114),  // Q4: Ya-Sin to An-Nas
        ];
        final result = <Map<String, dynamic>>[];
        final seen = <int>{};
        for (final q in qs) {
          final idx = q.clamp(1, 4) - 1;
          final suraFrom = surahRanges[idx].$1;
          final suraTo = surahRanges[idx].$2;
          for (final v in verses) {
            final sura = (v['sura_no'] as num).toInt();
            if (sura >= suraFrom && sura <= suraTo) {
              final id = v['id'] as int;
              if (seen.add(id)) result.add(v);
            }
          }
        }
        return result;
      }

      case QuestionRangeType.surahPages: {
        final nums = surahNumbers;
        if (nums == null || nums.isEmpty) return [];
        final suraNo = nums.first;
        final pFrom = pageFrom;
        final pTo = pageTo;
        return verses.where((v) {
          if ((v['sura_no'] as num).toInt() != suraNo) return false;
          final rawPage = '${v['page']}';
          final pageStr = rawPage.contains('-') ? rawPage.split('-')[0] : rawPage;
          final page = int.tryParse(pageStr) ?? 0;
          if (pFrom != null && page < pFrom) return false;
          if (pTo != null && page > pTo) return false;
          return true;
        }).toList();
      }
    }
  }
}

class AiService {
  static List<Map<String, dynamic>>? _allVerses;
  static List<Map<String, dynamic>>? _surahList;
  static Map<int, String>? _surahNameArMap;
  static Map<int, int>? _surahAyaCount;
  static Map<int, (int start, int end)>? _surahPageRange;

  static Future<List<Map<String, dynamic>>> loadVerses() async {
    if (_allVerses != null) return _allVerses!;
    final jsonStr = kIsWeb
        ? await http.read(Uri.parse('/assets/ai/QaloonData.json'))
        : await rootBundle.loadString('assets/ai/QaloonData.json');
    final List<dynamic> data = json.decode(jsonStr);
    _allVerses = data.cast<Map<String, dynamic>>();

    final seen = <int>{};
    _surahList = [];
    _surahNameArMap = {};
    _surahAyaCount = {};
    for (final v in _allVerses!) {
      final no = (v['sura_no'] as num).toInt();
      if (seen.add(no)) {
        _surahList!.add({
          'number': no,
          'nameAr': v['sura_name_ar'] as String? ?? '',
          'nameEn': v['sura_name_en'] as String? ?? '',
        });
      }
      _surahNameArMap![no] = v['sura_name_ar'] as String? ?? '';
      _surahAyaCount![no] = (_surahAyaCount![no] ?? 0) + 1;
    }

    // Compute page range per surah
    _surahPageRange = {};
    for (final v in _allVerses!) {
      final no = (v['sura_no'] as num).toInt();
      final rawPage = '${v['page']}';
      final pageStr = rawPage.contains('-') ? rawPage.split('-')[0] : rawPage;
      final page = int.tryParse(pageStr) ?? 0;
      if (page <= 0) continue;
      final existing = _surahPageRange![no];
      if (existing == null) {
        _surahPageRange![no] = (page, page);
      } else {
        final start = page < existing.$1 ? page : existing.$1;
        final end = page > existing.$2 ? page : existing.$2;
        _surahPageRange![no] = (start, end);
      }
    }

    // Assign hizb_no per verse: split each juz's verses into two halves
    final juzCount = <int, int>{};
    for (final v in _allVerses!) {
      final j = (v['jozz'] as num).toInt();
      juzCount[j] = (juzCount[j] ?? 0) + 1;
    }
    final juzSeen = <int, int>{};
    for (final v in _allVerses!) {
      final j = (v['jozz'] as num).toInt();
      final idx = juzSeen[j] ?? 0;
      juzSeen[j] = idx + 1;
      final total = juzCount[j]!;
      v['hizb_no'] = (j - 1) * 2 + (idx < total ~/ 2 ? 1 : 2);
    }

    return _allVerses!;
  }

  static List<Map<String, dynamic>> get surahList => _surahList ?? [];

  static String? surahNameAr(int no) => _surahNameArMap?[no];

  static int? surahAyaCount(int no) => _surahAyaCount?[no];

  static (int start, int end)? surahPageRange(int no) {
    _ensurePageRanges();
    return _surahPageRange?[no];
  }

  static void _ensurePageRanges() {
    if (_surahPageRange != null) return;
    if (_allVerses == null || _allVerses!.isEmpty) return;
    _surahPageRange = {};
    for (final v in _allVerses!) {
      final no = (v['sura_no'] as num).toInt();
      final rawPage = '${v['page']}';
      final pageStr = rawPage.contains('-') ? rawPage.split('-')[0] : rawPage;
      final page = int.tryParse(pageStr) ?? 0;
      if (page <= 0) continue;
      final existing = _surahPageRange![no];
      if (existing == null) {
        _surahPageRange![no] = (page, page);
      } else {
        final start = page < existing.$1 ? page : existing.$1;
        final end = page > existing.$2 ? page : existing.$2;
        _surahPageRange![no] = (start, end);
      }
    }
  }

  static List<Map<String, dynamic>> get allVerses => _allVerses ?? [];

  static String questionText(Map<String, dynamic> verse) {
    final sura = verse['sura_name_ar'] ?? verse['sura_name_en'] ?? '';
    final aya = verse['aya_no'];
    return 'سورة $sura (الآية $aya): ${verse['aya_text'] as String? ?? ''}';
  }

  /// Returns (questionTexts, verseIndices)
  static Future<(List<String>, List<int>)> generateDetailed({
    required List<QuestionRange> ranges,
    required int count,
    int? nearVerseIndex,
  }) async {
    if (count <= 0 || ranges.isEmpty) return (<String>[], <int>[]);
    final verses = await loadVerses();

    int? nearSura;
    if (nearVerseIndex != null && nearVerseIndex >= 0 && nearVerseIndex < verses.length) {
      nearSura = (verses[nearVerseIndex]['sura_no'] as num).toInt();
    }

    final pools = ranges.map((r) {
      final seen = <int>{};
      var pool = r.buildPool(verses).where((v) {
        final id = v['id'] as int;
        if (!seen.add(id)) return false;
        final sura = (v['sura_no'] as num).toInt();
        if (sura == 1) return false;
        final hizb = (v['hizb_no'] as num).toInt();
        if (hizb == 59 || hizb == 60) return false;
        return true;
      }).toList();
      if (nearSura != null) {
        final nearPool = pool.where((v) {
          final sura = (v['sura_no'] as num).toInt();
          return (sura - nearSura!).abs() <= 1;
        }).toList();
        if (nearPool.isNotEmpty) pool = nearPool;
      }
      pool.sort((a, b) {
        final cmp = (a['sura_no'] as num).compareTo(b['sura_no'] as num);
        if (cmp != 0) return cmp;
        return (a['aya_no'] as num).compareTo(b['aya_no'] as num);
      });
      return pool;
    }).toList();

    final validIndices = <int>[];
    for (int i = 0; i < pools.length; i++) {
      if (pools[i].isNotEmpty) validIndices.add(i);
    }
    if (validIndices.isEmpty) return (List.filled(count, ''), List.filled(count, -1));

    validIndices.sort((a, b) {
      final aIsSurah = ranges[a].type == QuestionRangeType.surahs ||
          ranges[a].type == QuestionRangeType.surahAyahRange;
      final bIsSurah = ranges[b].type == QuestionRangeType.surahs ||
          ranges[b].type == QuestionRangeType.surahAyahRange;
      if (aIsSurah && !bIsSurah) return -1;
      if (!aIsSurah && bIsSurah) return 1;
      return 0;
    });

    final counts = <int, int>{};
    int remaining = count;
    for (final i in validIndices) {
      final isSurah = ranges[i].type == QuestionRangeType.surahs ||
          ranges[i].type == QuestionRangeType.surahAyahRange ||
          ranges[i].type == QuestionRangeType.surahPages;
      if (isSurah && remaining > 0) {
        counts[i] = 1;
        remaining--;
      }
    }
    if (remaining > 0) {
      final nonSurah = validIndices.where((i) =>
          ranges[i].type != QuestionRangeType.surahs &&
          ranges[i].type != QuestionRangeType.surahAyahRange &&
          ranges[i].type != QuestionRangeType.surahPages).toList();
      if (nonSurah.isNotEmpty) {
        final perNonSurah = remaining ~/ nonSurah.length;
        int extra = remaining % nonSurah.length;
        for (final i in nonSurah) {
          counts[i] = (counts[i] ?? 0) + perNonSurah + (extra > 0 ? 1 : 0);
          if (extra > 0) extra--;
        }
      } else {
        counts[validIndices.first] = (counts[validIndices.first] ?? 0) + remaining;
      }
    }

    final rng = Random();
    final allSelected = <Map<String, dynamic>>[];
    final hasQuarter4 = ranges.any(
      (r) => r.type == QuestionRangeType.quarter && r.quarterNumbers?.contains(4) == true,
    );
    final surahCounts = <int, int>{};
    final surahAyahs = <int, List<int>>{};
    const rob3SurahRanges = [(1, 6), (7, 18), (19, 35), (36, 114)];
    for (final i in validIndices) {
      var pool = pools[i];
      final n = counts[i] ?? 0;
      if (n == 0) continue;
      final selected = <Map<String, dynamic>>[];
      final isQ4 = hasQuarter4 &&
          ranges[i].type == QuestionRangeType.quarter &&
          ranges[i].quarterNumbers?.contains(4) == true;
      final isQuarter = ranges[i].type == QuestionRangeType.quarter;

      pool = pool.where((v) {
        final sura = (v['sura_no'] as num).toInt();
        if (sura == 1) return false;
        final hizb = (v['hizb_no'] as num).toInt();
        if (hizb == 59 || hizb == 60) return false;
        if (!isQuarter) {
          final aya = (v['aya_no'] as num).toInt();
          final juz = (v['jozz'] as num).toInt();
          final totalAya = surahAyaCount(sura) ?? 0;
          final skipCount = (totalAya * 0.1).ceil().clamp(1, 5);
          if (juz < 29 && aya <= skipCount) return false;
          if (aya > totalAya - skipCount) return false;
        }
        return true;
      }).toList();

      if (pool.isEmpty) continue;
      if (!isQuarter) {
        final hasEarlySurahs = pool.any((v) => (v['sura_no'] as num).toInt() < 78);
        if (hasEarlySurahs) {
          pool.removeWhere((v) => (v['sura_no'] as num).toInt() >= 78);
        }
      }
      if (pool.isEmpty) continue;

      if (isQuarter) {
        final qNums = ranges[i].quarterNumbers ?? [];
        if (qNums.length > 1) {
          final perQ = n ~/ qNums.length;
          int r = n % qNums.length;
          for (final qn in qNums) {
            final idx = qn.clamp(1, 4) - 1;
            final sFrom = rob3SurahRanges[idx].$1;
            final sTo = rob3SurahRanges[idx].$2;
            final needed = perQ + (r > 0 ? 1 : 0);
            if (r > 0) r--;
            if (needed <= 0) continue;
            final qPool = pool.where((v) {
              final sura = (v['sura_no'] as num).toInt();
              return sura >= sFrom && sura <= sTo;
            }).toList();
            if (qPool.isEmpty) continue;
            selected.addAll(_pickFromPool(qPool, needed, isQ4, rng,
                surahCounts: surahCounts,
                surahAyahs: surahAyahs));
          }
        } else {
          final perSub = n ~/ 4;
          int extra = n % 4;
          for (final (sFrom, sTo) in rob3SurahRanges) {
            final needed = perSub + (extra > 0 ? 1 : 0);
            if (extra > 0) extra--;
            if (needed <= 0) continue;
            final subPool = pool.where((v) {
              final sura = (v['sura_no'] as num).toInt();
              return sura >= sFrom && sura <= sTo;
            }).toList();
            if (subPool.isEmpty) continue;
            selected.addAll(_pickFromPool(subPool, needed, isQ4, rng,
                surahCounts: surahCounts,
                surahAyahs: surahAyahs));
          }
          if (selected.isEmpty) {
            selected.addAll(_pickFromPool(pool, n, isQ4, rng,
                surahCounts: surahCounts,
                surahAyahs: surahAyahs));
          }
        }
      } else if (ranges[i].type == QuestionRangeType.allQuran ||
          ranges[i].type == QuestionRangeType.hizbRange) {
        final List<(int, int)> subRanges;
        if (ranges[i].type == QuestionRangeType.allQuran) {
          subRanges = rob3SurahRanges;
        } else {
          final hFrom = ranges[i].hizbFrom ?? 1;
          final hTo = ranges[i].hizbTo ?? 60;
          final totalHizbs = hTo - hFrom + 1;
          final chunkSize = (totalHizbs / 4).ceil().clamp(1, totalHizbs);
          subRanges = [];
          for (int h = hFrom; h <= hTo; h += chunkSize) {
            final end = (h + chunkSize - 1).clamp(h, hTo);
            subRanges.add((h, end));
          }
        }
        final perSub = n ~/ subRanges.length;
        int extra = n % subRanges.length;
        for (final (sFrom, sTo) in subRanges) {
          final needed = perSub + (extra > 0 ? 1 : 0);
          if (extra > 0) extra--;
          if (needed <= 0) continue;
          final subPool = pool.where((v) {
            final sura = (v['sura_no'] as num).toInt();
            if (ranges[i].type == QuestionRangeType.allQuran) {
              return sura >= sFrom && sura <= sTo;
            } else {
              final hizb = (v['hizb_no'] as num).toInt();
              return hizb >= sFrom && hizb <= sTo;
            }
          }).toList();
          if (subPool.isEmpty) continue;
          selected.addAll(_pickFromPool(subPool, needed, isQ4, rng,
              surahCounts: surahCounts,
              surahAyahs: surahAyahs));
        }
      } else {
        selected.addAll(_pickFromPool(pool, n, isQ4, rng,
            surahCounts: surahCounts,
            surahAyahs: surahAyahs));
      }
      allSelected.addAll(selected);
    }

    if (allSelected.length < count) {
      final seenIds = allSelected.map((v) => v['id'] as int).toSet();
      final remaining = <Map<String, dynamic>>[];
      for (final pool in pools) {
        for (final v in pool) {
          if (seenIds.add(v['id'] as int)) remaining.add(v);
        }
      }
      if (remaining.isNotEmpty) {
        allSelected.addAll(_pickFromPool(remaining, count - allSelected.length, hasQuarter4, rng,
            surahCounts: surahCounts,
            surahAyahs: surahAyahs));
      }
    }

    allSelected.sort((a, b) {
      final cmp = (a['sura_no'] as num).compareTo(b['sura_no'] as num);
      if (cmp != 0) return cmp;
      return (a['aya_no'] as num).compareTo(b['aya_no'] as num);
    });

    final texts = allSelected.map(questionText).toList();
    final indices = allSelected.map((v) => verses.indexOf(v)).toList();
    return (texts, indices);
  }

  static Future<List<String>> generateQuestions({
    required List<QuestionRange> ranges,
    required int count,
  }) async {
    if (count <= 0 || ranges.isEmpty) return [];
    final verses = await loadVerses();

    // Build a sorted, deduplicated pool per range
    final pools = ranges.map((r) {
      final seen = <int>{};
      final pool = r.buildPool(verses).where((v) {
        final id = v['id'] as int;
        if (!seen.add(id)) return false;
        final sura = (v['sura_no'] as num).toInt();
        if (sura == 1) return false;
        final hizb = (v['hizb_no'] as num).toInt();
        if (hizb == 59 || hizb == 60) return false;
        return true;
      }).toList();
      pool.sort((a, b) {
        final cmp = (a['sura_no'] as num).compareTo(b['sura_no'] as num);
        if (cmp != 0) return cmp;
        return (a['aya_no'] as num).compareTo(b['aya_no'] as num);
      });
      return pool;
    }).toList();

    // Only keep ranges with at least one verse
    final validIndices = <int>[];
    for (int i = 0; i < pools.length; i++) {
      if (pools[i].isNotEmpty) validIndices.add(i);
    }
    if (validIndices.isEmpty) return List.filled(count, '');

    // Prioritize surah-based ranges so they always get questions when possible
    validIndices.sort((a, b) {
      final aIsSurah = ranges[a].type == QuestionRangeType.surahs ||
          ranges[a].type == QuestionRangeType.surahAyahRange;
      final bIsSurah = ranges[b].type == QuestionRangeType.surahs ||
          ranges[b].type == QuestionRangeType.surahAyahRange;
      if (aIsSurah && !bIsSurah) return -1;
      if (!aIsSurah && bIsSurah) return 1;
      return 0;
    });

    final counts = <int, int>{};
    int remaining = count;
    for (final i in validIndices) {
      final isSurah = ranges[i].type == QuestionRangeType.surahs ||
          ranges[i].type == QuestionRangeType.surahAyahRange ||
          ranges[i].type == QuestionRangeType.surahPages;
      if (isSurah && remaining > 0) {
        counts[i] = 1;
        remaining--;
      }
    }
    if (remaining > 0) {
      final nonSurah = validIndices.where((i) =>
          ranges[i].type != QuestionRangeType.surahs &&
          ranges[i].type != QuestionRangeType.surahAyahRange &&
          ranges[i].type != QuestionRangeType.surahPages).toList();
      if (nonSurah.isNotEmpty) {
        final perNonSurah = remaining ~/ nonSurah.length;
        int extra = remaining % nonSurah.length;
        for (final i in nonSurah) {
          counts[i] = (counts[i] ?? 0) + perNonSurah + (extra > 0 ? 1 : 0);
          if (extra > 0) extra--;
        }
      } else {
        counts[validIndices.first] = (counts[validIndices.first] ?? 0) + remaining;
      }
    }

    final rng = Random();
    final allSelected = <Map<String, dynamic>>[];

    final hasQuarter4 = ranges.any(
      (r) => r.type == QuestionRangeType.quarter && r.quarterNumbers?.contains(4) == true,
    );

    final surahCounts = <int, int>{};
    final surahAyahs = <int, List<int>>{};
    const rob3SurahRanges2 = [(1, 6), (7, 18), (19, 35), (36, 114)];

    for (final i in validIndices) {
      var pool = pools[i];
      final n = counts[i] ?? 0;
      if (n == 0) continue;
      final selected = <Map<String, dynamic>>[];
      final isQ4 = hasQuarter4 &&
          ranges[i].type == QuestionRangeType.quarter &&
          ranges[i].quarterNumbers?.contains(4) == true;
      final isQuarter = ranges[i].type == QuestionRangeType.quarter;

      pool = pool.where((v) {
        final sura = (v['sura_no'] as num).toInt();
        if (sura == 1) return false;
        final hizb = (v['hizb_no'] as num).toInt();
        if (hizb == 59 || hizb == 60) return false;
        if (!isQuarter) {
          final aya = (v['aya_no'] as num).toInt();
          final juz = (v['jozz'] as num).toInt();
          final totalAya = surahAyaCount(sura) ?? 0;
          final skipCount = (totalAya * 0.1).ceil().clamp(1, 5);
          if (juz < 29 && aya <= skipCount) return false;
          if (aya > totalAya - skipCount) return false;
        }
        return true;
      }).toList();

      if (pool.isEmpty) continue;
      if (!isQuarter) {
        final hasEarlySurahs = pool.any((v) => (v['sura_no'] as num).toInt() < 78);
        if (hasEarlySurahs) {
          pool.removeWhere((v) => (v['sura_no'] as num).toInt() >= 78);
        }
      }
      if (pool.isEmpty) continue;

      if (isQuarter) {
        final qNums = ranges[i].quarterNumbers ?? [];
        if (qNums.length > 1) {
          final perQ = n ~/ qNums.length;
          int r = n % qNums.length;
          for (final qn in qNums) {
            final idx = qn.clamp(1, 4) - 1;
            final sFrom = rob3SurahRanges2[idx].$1;
            final sTo = rob3SurahRanges2[idx].$2;
            final needed = perQ + (r > 0 ? 1 : 0);
            if (r > 0) r--;
            if (needed <= 0) continue;
            final qPool = pool.where((v) {
              final sura = (v['sura_no'] as num).toInt();
              return sura >= sFrom && sura <= sTo;
            }).toList();
            if (qPool.isEmpty) continue;
            selected.addAll(_pickFromPool(qPool, needed, isQ4, rng,
                surahCounts: surahCounts,
                surahAyahs: surahAyahs));
          }
        } else {
          final perSub = n ~/ 4;
          int extra = n % 4;
          for (final (sFrom, sTo) in rob3SurahRanges2) {
            final needed = perSub + (extra > 0 ? 1 : 0);
            if (extra > 0) extra--;
            if (needed <= 0) continue;
            final subPool = pool.where((v) {
              final sura = (v['sura_no'] as num).toInt();
              return sura >= sFrom && sura <= sTo;
            }).toList();
            if (subPool.isEmpty) continue;
            selected.addAll(_pickFromPool(subPool, needed, isQ4, rng,
                surahCounts: surahCounts,
                surahAyahs: surahAyahs));
          }
          if (selected.isEmpty) {
            selected.addAll(_pickFromPool(pool, n, isQ4, rng,
                surahCounts: surahCounts,
                surahAyahs: surahAyahs));
          }
        }
      } else if (ranges[i].type == QuestionRangeType.allQuran ||
          ranges[i].type == QuestionRangeType.hizbRange) {
        final List<(int, int)> subRanges;
        if (ranges[i].type == QuestionRangeType.allQuran) {
          subRanges = rob3SurahRanges2;
        } else {
          final hFrom = ranges[i].hizbFrom ?? 1;
          final hTo = ranges[i].hizbTo ?? 60;
          final totalHizbs = hTo - hFrom + 1;
          final chunkSize = (totalHizbs / 4).ceil().clamp(1, totalHizbs);
          subRanges = [];
          for (int h = hFrom; h <= hTo; h += chunkSize) {
            final end = (h + chunkSize - 1).clamp(h, hTo);
            subRanges.add((h, end));
          }
        }
        final perSub = n ~/ subRanges.length;
        int extra = n % subRanges.length;
        for (final (sFrom, sTo) in subRanges) {
          final needed = perSub + (extra > 0 ? 1 : 0);
          if (extra > 0) extra--;
          if (needed <= 0) continue;
          final subPool = pool.where((v) {
            if (ranges[i].type == QuestionRangeType.allQuran) {
              final sura = (v['sura_no'] as num).toInt();
              return sura >= sFrom && sura <= sTo;
            } else {
              final hizb = (v['hizb_no'] as num).toInt();
              return hizb >= sFrom && hizb <= sTo;
            }
          }).toList();
          if (subPool.isEmpty) continue;
          selected.addAll(_pickFromPool(subPool, needed, isQ4, rng,
              surahCounts: surahCounts,
              surahAyahs: surahAyahs));
        }
      } else {
        selected.addAll(_pickFromPool(pool, n, isQ4, rng,
            surahCounts: surahCounts,
            surahAyahs: surahAyahs));
      }
      allSelected.addAll(selected);
    }

    if (allSelected.length < count) {
      final seenIds = allSelected.map((v) => v['id'] as int).toSet();
      final remaining = <Map<String, dynamic>>[];
      for (final pool in pools) {
        for (final v in pool) {
          if (seenIds.add(v['id'] as int)) remaining.add(v);
        }
      }
      if (remaining.isNotEmpty) {
        allSelected.addAll(_pickFromPool(remaining, count - allSelected.length, hasQuarter4, rng,
            surahCounts: surahCounts,
            surahAyahs: surahAyahs));
      }
    }

    allSelected.sort((a, b) {
      final cmp = (a['sura_no'] as num).compareTo(b['sura_no'] as num);
      if (cmp != 0) return cmp;
      return (a['aya_no'] as num).compareTo(b['aya_no'] as num);
    });

    return allSelected.map(questionText).toList();
  }

  static String truncateVerse(String text, {int maxWords = 20}) {
    final words = text.split(RegExp(r'\s+'));
    if (words.length <= maxWords) return text;
    return '${words.take(maxWords).join(' ')}...';
  }

  static List<Map<String, dynamic>> _pickFromPool(
      List<Map<String, dynamic>> pool, int n, bool isQ4, Random rng,
      {Map<int, int>? surahCounts,
      Map<int, List<int>>? surahAyahs}) {
    final sCounts = surahCounts ?? <int, int>{};
    final sAyahs = surahAyahs ?? <int, List<int>>{};
    final selected = <Map<String, dynamic>>[];
    final bySurah = <int, List<Map<String, dynamic>>>{};
    for (final v in pool) {
      bySurah.putIfAbsent((v['sura_no'] as num).toInt(), () => []).add(v);
    }

    // Max 1 question per surah; only allow 2nd if surah has >100 verses
    bySurah.removeWhere((sura, verses) {
      final count = sCounts[sura] ?? 0;
      final totalAya = surahAyaCount(sura) ?? 0;
      final limit = totalAya > 100 ? 2 : 1;
      return count >= limit;
    });

    final surahKeys = bySurah.keys.toList();
    if (surahKeys.isEmpty) return selected;
    // Shuffle so picks are spread across different surahs
    surahKeys.shuffle(rng);
    final actualN = n > surahKeys.length ? surahKeys.length : n;
    for (int si = 0; si < actualN; si++) {
      final sura = surahKeys[si];
      final verse = _pickVerse(
          bySurah[sura]!, isQ4, rng,
          surahAyahs: sAyahs);
      _trackVerse(verse, sCounts, sAyahs);
      selected.add(verse);
    }
    return selected;
  }

  static void _trackVerse(Map<String, dynamic> verse, Map<int, int> counts,
      Map<int, List<int>> ayahs) {
    final sura = (verse['sura_no'] as num).toInt();
    counts[sura] = (counts[sura] ?? 0) + 1;
    ayahs.putIfAbsent(sura, () => []).add((verse['aya_no'] as num).toInt());
  }

  static Map<String, dynamic> _pickVerse(
      List<Map<String, dynamic>> verses, bool weighted, Random rng,
      {Map<int, List<int>>? surahAyahs}) {
    var candidates = verses;
    if (surahAyahs != null && surahAyahs.isNotEmpty) {
      candidates = verses.where((v) {
        final sura = (v['sura_no'] as num).toInt();
        final aya = (v['aya_no'] as num).toInt();
        final existing = surahAyahs[sura];
        if (existing == null || existing.isEmpty) return true;
        final totalAya = surahAyaCount(sura) ?? 100;
        final gap = (totalAya * 0.4).ceil().clamp(2, totalAya);
        return existing.every((e) => (aya - e).abs() >= gap);
      }).toList();
      if (candidates.isEmpty) candidates = verses;
    }
    final weights = candidates.map((v) {
      final sura = (v['sura_no'] as num).toInt();
      if (sura >= 67) return 0.05;
      return 1.0;
    }).toList();
    final total = weights.fold(0.0, (s, w) => s + w);
    double r = rng.nextDouble() * total;
    for (int i = 0; i < candidates.length; i++) {
      r -= weights[i];
      if (r <= 0) return candidates[i];
    }
    return candidates.last;
  }
}
