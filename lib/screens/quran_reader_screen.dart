import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:ta3dia/services/pexels_background_service.dart';
import 'package:ta3dia/services/quran_download_service.dart';
import 'package:ta3dia/services/string_utils.dart';

class QuranReaderScreen extends StatefulWidget {
  final int? initialSurah;
  final int? initialAyah;
  final String? pageKey;

  const QuranReaderScreen({super.key, this.initialSurah, this.initialAyah, this.pageKey});

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _PageMeta {
  final int page;
  final String surahNameAr;
  final int surahNo;
  final int juz;
  _PageMeta({
    required this.page,
    required this.surahNameAr,
    required this.surahNo,
    required this.juz,
  });
}

const _surahNamesAr = [
  '', 'الفاتحة', 'البقرة', 'آل عمران', 'النساء', 'المائدة', 'الأنعام',
  'الأعراف', 'الأنفال', 'التوبة', 'يونس', 'هود', 'يوسف', 'الرعد',
  'إبراهيم', 'الحجر', 'النحل', 'الإسراء', 'الكهف', 'مريم', 'طه',
  'الأنبياء', 'الحج', 'المؤمنون', 'النور', 'الفرقان', 'الشعراء',
  'النمل', 'القصص', 'العنكبوت', 'الروم', 'لقمان', 'السجدة',
  'الأحزاب', 'سبأ', 'فاطر', 'يس', 'الصافات', 'ص', 'الزمر',
  'غافر', 'فصلت', 'الشورى', 'الزخرف', 'الدخان', 'الجاثية',
  'الأحقاف', 'محمد', 'الفتح', 'الحجرات', 'ق', 'الذاريات',
  'الطور', 'النجم', 'القمر', 'الرحمن', 'الواقعة', 'الحديد',
  'المجادلة', 'الحشر', 'الممتحنة', 'الصف', 'الجمعة', 'المنافقون',
  'التغابن', 'الطلاق', 'التحريم', 'الملك', 'القلم', 'الحاقة',
  'المعارج', 'نوح', 'الجن', 'المزمل', 'المدثر', 'القيامة',
  'الإنسان', 'المرسلات', 'النبأ', 'النازعات', 'عبس', 'التكوير',
  'الانفطار', 'المطففين', 'الانشقاق', 'البروج', 'الطارق',
  'الأعلى', 'الغاشية', 'الفجر', 'البلد', 'الشمس', 'الليل',
  'الضحى', 'الشرح', 'التين', 'العلق', 'القدر', 'البينة',
  'الزلزلة', 'العاديات', 'القارعة', 'التكاثر', 'العصر',
  'الهمزة', 'الفيل', 'قريش', 'الماعون', 'الكوثر', 'الكافرون',
  'النصر', 'المسد', 'الإخلاص', 'الفلق', 'الناس',
];

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  static final _savedPages = <String?, int>{};
  int _currentPage = _savedPages[null] ?? 1;
  late PageController _pageController;
  bool _loading = true;
  final _failedPages = <int>{};
  final _loadingPages = <int>{};
  final _svgCache = <int, String>{};
  final _pageMeta = <int, _PageMeta>{};
  String? _highlightAyah;

  static const _totalPages = 604;
  static const _baseUrl =
      'https://raw.githubusercontent.com/quranpedia/quran-svg/main/mushafs/qalon/kfqc/svg';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _buildPageMeta();
    int? targetPage;
    String? targetHighlight;
    if (widget.initialSurah != null && widget.initialAyah != null) {
      final json = await rootBundle.loadString('assets/ai/QaloonData.json');
      final allData = jsonDecode(json) as List;
      for (final v in allData) {
        if ((v['sura_no'] as int) == widget.initialSurah &&
            (v['aya_no'] as int) == widget.initialAyah) {
          targetPage = int.parse((v['page'] as String).split('-')[0]);
          targetHighlight = '${widget.initialSurah.toString().padLeft(3, '0')}${widget.initialAyah.toString().padLeft(3, '0')}';
          break;
        }
      }
    }
    final initialPage = targetPage ?? _savedPages[widget.pageKey] ?? _currentPage;
    _currentPage = initialPage;
    _pageController = PageController(initialPage: initialPage - 1);
    if (targetHighlight != null) {
      _highlightAyah = targetHighlight;
    }
    _savedPages[widget.pageKey] = initialPage;
    _loading = false;
    if (mounted) setState(() {});
    _preload(_currentPage);
  }

  Future<void> _buildPageMeta() async {
    final json = await rootBundle.loadString('assets/ai/QaloonData.json');
    final data = jsonDecode(json) as List;
    for (final v in data) {
      final page = int.parse((v['page'] as String).split('-')[0]);
      final suraNo = v['sura_no'] as int;
      if (!_pageMeta.containsKey(page)) {
        _pageMeta[page] = _PageMeta(
          page: page,
          surahNameAr: suraNo >= 0 && suraNo < _surahNamesAr.length ? _surahNamesAr[suraNo] : '',
          surahNo: suraNo,
          juz: v['jozz'] as int? ?? 1,
        );
      }
    }
    for (var p = 1; p <= _totalPages; p++) {
      _pageMeta.putIfAbsent(p, () {
        for (var d = 1; d <= _totalPages; d++) {
          if (p - d >= 1 && _pageMeta.containsKey(p - d)) return _pageMeta[p - d]!;
          if (p + d <= _totalPages && _pageMeta.containsKey(p + d)) return _pageMeta[p + d]!;
        }
        return _PageMeta(page: p, surahNameAr: '', surahNo: 1, juz: 1);
      });
    }
  }

  String _pageUrl(int p) =>
      '$_baseUrl/${p.toString().padLeft(3, '0')}.svg';

  final _downloadService = QuranDownloadService.instance;

  Future<void> _preload(int page) async {
    for (var p = page; p <= (page + 3).clamp(1, _totalPages); p++) {
      if (_loadingPages.contains(p) || _svgCache.containsKey(p)) continue;
      _loadingPages.add(p);
      try {
        String? svg;
        svg = await _downloadService.getLocalSvg(p);
        if (svg == null) {
          final r = await http.get(Uri.parse(_pageUrl(p)));
          if (r.statusCode == 200) {
            svg = r.body;
          }
        }
        if (svg != null) {
          _svgCache[p] = svg;
          if (mounted) setState(() => _failedPages.remove(p));
        } else {
          if (mounted) setState(() => _failedPages.add(p));
        }
      } catch (_) {
        if (mounted) setState(() => _failedPages.add(p));
      } finally {
        _loadingPages.remove(p);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page, {String? highlightAyah}) {
    if (page < 1 || page > _totalPages) return;
    _pageController.jumpToPage(page - 1);
    setState(() {
      _currentPage = page;
      _savedPages[widget.pageKey] = page;
      _highlightAyah = highlightAyah;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pexelsUrl = PexelsBackgroundService.instance.imageUrl;
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFFEFC),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final meta = _pageMeta[_currentPage];
    final pageArabic = _arabicNumeral(_currentPage);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFC),
      body: Stack(
        children: [
          if (pexelsUrl != null)
            Positioned.fill(
              child: Image.network(pexelsUrl, fit: BoxFit.cover),
            ),
          if (pexelsUrl != null)
            Positioned.fill(
              child: Container(color: const Color(0xFFFFFEFC).withValues(alpha: 0.80)),
            ),
          SafeArea(
            child: Column(
          children: [
            _PageHeader(
              pageNumber: pageArabic,
              surahName: meta?.surahNameAr ?? '',
              juz: meta?.juz ?? 1,
            ),
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) {
                    final p = i + 1;
                    setState(() {
                      _currentPage = p;
                      _savedPages[widget.pageKey] = p;
                    });
                    _preload(p);
                  },
                  itemCount: _totalPages,
                  itemBuilder: (_, i) {
                    final p = i + 1;
                    return _MushafPage(
                      key: ValueKey('page-$p'),
                      svgContent: _svgCache[p],
                      hasError: _failedPages.contains(p),
                      highlightAyah: _highlightAyah,
                    );
                  },
                ),
              ),
            ),
            _PageSlider(
              currentPage: _currentPage,
              totalPages: _totalPages,
              onChanged: (p) => _goToPage(p),
            ),
            _BottomBar(
              onBack: () => Navigator.pop(context),
              onSearch: _showSearchPanel,
            ),
          ],
        ),
        ),
      ],
      ),
    );
  }

  Future<void> _showSearchPanel() async {
    final jsonStr = await rootBundle.loadString('assets/ai/QaloonData.json');
    final allData = jsonDecode(jsonStr) as List;
    final surahPages = <int, int>{};
    for (final v in allData) {
      final sn = v['sura_no'] as int;
      final pg = int.parse((v['page'] as String).split('-')[0]);
      surahPages.putIfAbsent(sn, () => pg);
    }
    final surahList = surahPages.entries.map((e) => _PageMeta(
      page: e.value,
      surahNameAr: e.key >= 0 && e.key < _surahNamesAr.length ? _surahNamesAr[e.key] : '',
      surahNo: e.key,
      juz: 1,
    )).toList()..sort((a, b) => a.surahNo.compareTo(b.surahNo));

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFDF8F0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SearchPanel(
        surahList: surahList,
        pageMeta: _pageMeta,
        onGoToPage: (page, {String? highlight}) {
          Navigator.pop(context);
          _goToPage(page, highlightAyah: highlight);
        },
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final String pageNumber;
  final String surahName;
  final int juz;
  const _PageHeader({
    required this.pageNumber,
    required this.surahName,
    required this.juz,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF6C5A3B),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4E402B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'الجزء ${_arabicNumeral(juz)}',
              style: const TextStyle(
                fontFamily: 'Amiri', fontSize: 14, color: Color(0xFFD3BF90),
              ),
            ),
          ),
          const Spacer(),
          Text(
            pageNumber,
            style: const TextStyle(
              fontFamily: 'Amiri', fontSize: 24, fontWeight: FontWeight.bold,
              color: Color(0xFFD3BF90),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4E402B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              surahName,
              style: const TextStyle(
                fontFamily: 'Amiri', fontSize: 14, color: Color(0xFFD3BF90),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Page Slider ──────────────────────────────────────────────────────────────

class _PageSlider extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onChanged;

  const _PageSlider({
    required this.currentPage,
    required this.totalPages,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          const Text('﴿', style: TextStyle(fontFamily: 'Amiri', fontSize: 12, color: Color(0xFF8B7D6B))),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                activeTrackColor: const Color(0xFFCDBA95),
                inactiveTrackColor: const Color(0xFFCDBA95).withAlpha(80),
                thumbColor: const Color(0xFFC79B49),
                overlayColor: const Color(0xFFC79B49).withAlpha(30),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Slider(
                  value: currentPage.toDouble(),
                  min: 1,
                  max: totalPages.toDouble(),
                  onChanged: (v) => onChanged(v.round()),
                ),
              ),
            ),
          ),
          const Text('﴾', style: TextStyle(fontFamily: 'Amiri', fontSize: 12, color: Color(0xFF8B7D6B))),
        ],
      ),
    );
  }
}

// ─── Mushaf Page ──────────────────────────────────────────────────────────────

String _preprocessSvg(String svg, {String? highlightAyah}) {
  // Color the ayah separator polygons for clear verse distinction
  if (highlightAyah == null) {
    return svg.replaceAllMapped(
      RegExp(r'<path class="ayahPolygon"([^>]*)/>'),
      (m) {
        final attrs = m[1] ?? '';
        return '<path$attrs style="fill:#8A8479;fill-opacity:0.06" />';
      },
    );
  } else {
    return svg.replaceAllMapped(
      RegExp(r'<path class="ayahPolygon"([^>]*)/>'),
      (m) {
        final attrs = m[1] ?? '';
        if (attrs.contains('number="$highlightAyah"')) {
          return '<path$attrs style="fill:#C79B49;fill-opacity:0.3" />';
        }
        return '<path$attrs style="fill:#8A8479;fill-opacity:0.06" />';
      },
    );
  }
}

class _MushafPage extends StatelessWidget {
  final String? svgContent;
  final bool hasError;
  final String? highlightAyah;

  const _MushafPage({
    super.key,
    this.svgContent,
    required this.hasError,
    this.highlightAyah,
  });

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (hasError) {
      body = const _ErrorPage();
    } else if (svgContent != null) {
      final svg = SvgPicture.string(
        _preprocessSvg(svgContent!, highlightAyah: highlightAyah),
        fit: BoxFit.contain,
      );
      body = svg;
    } else {
      body = const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFEFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDDD3C3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(9), child: body),
      ),
    );
  }
}

class _ErrorPage extends StatelessWidget {
  const _ErrorPage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFF8B7D6B)),
          const SizedBox(height: 8),
          const Text(
            'تعذر تحميل الصفحة',
            style: TextStyle(fontFamily: 'Amiri', fontSize: 16, color: Color(0xFF6C5A3B)),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onSearch;

  const _BottomBar({
    required this.onBack,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF6C5A3B),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            _NavButton(icon: Icons.arrow_back, label: 'عودة', onTap: onBack, textColor: const Color(0xFFF0E9DA)),
            Expanded(
              child: Center(
                child: _NavButton(icon: Icons.search, label: 'بحث', onTap: onSearch, textColor: const Color(0xFFF0E9DA)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? textColor;

  const _NavButton({required this.icon, required this.label, this.onTap, this.textColor});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final effectiveTextColor = textColor ?? (enabled ? const Color(0xFFD3BF90) : const Color(0xFFD3BF90).withAlpha(80));
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22,
                color: enabled ? const Color(0xFFD3BF90) : const Color(0xFFD3BF90).withAlpha(80),
              ),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(
                fontFamily: 'Amiri', fontSize: 14,
                color: effectiveTextColor,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Search Panel ─────────────────────────────────────────────────────────────

typedef _GoToPage = void Function(int page, {String? highlight});

class _SearchPanel extends StatefulWidget {
  final List<_PageMeta> surahList;
  final Map<int, _PageMeta> pageMeta;
  final _GoToPage onGoToPage;

  const _SearchPanel({
    required this.surahList,
    required this.pageMeta,
    required this.onGoToPage,
  });

  @override
  State<_SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<_SearchPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _surahCtrl = TextEditingController();
  final _verseCtrl = TextEditingController();
  String _surahQuery = '';
  String _verseQuery = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _surahCtrl.addListener(() => setState(() => _surahQuery = _surahCtrl.text));
    _verseCtrl.addListener(() => setState(() => _verseQuery = _verseCtrl.text));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _surahCtrl.dispose();
    _verseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD4C9A8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabCtrl,
            indicatorColor: const Color(0xFF6C5A3B),
            labelColor: const Color(0xFF6C5A3B),
            unselectedLabelColor: const Color(0xFF8B7D6B),
            labelStyle: const TextStyle(fontFamily: 'Amiri', fontSize: 16, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'بحث بالسورة'),
              Tab(text: 'بحث بالآية'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _SurahSearchTab(
                  surahList: widget.surahList,
                  query: _surahQuery,
                  ctrl: _surahCtrl,
                  onGoToPage: widget.onGoToPage,
                ),
                _VerseSearchTab(
                  query: _verseQuery,
                  ctrl: _verseCtrl,
                  onGoToPage: widget.onGoToPage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahSearchTab extends StatelessWidget {
  final List<_PageMeta> surahList;
  final String query;
  final TextEditingController ctrl;
  final _GoToPage onGoToPage;

  const _SurahSearchTab({
    required this.surahList,
    required this.query,
    required this.ctrl,
    required this.onGoToPage,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = normalizeArabic(query);
    final filtered = query.isEmpty
        ? surahList
        : surahList.where((s) =>
            normalizeArabic(s.surahNameAr).contains(normalizedQuery) ||
            s.surahNo.toString() == query).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: 'اسم السورة أو الرقم',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6C5A3B)),
                filled: true,
                fillColor: const Color(0xFFE9E0CF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontFamily: 'Amiri', fontSize: 16),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final s = filtered[i];
                return ListTile(
                  tileColor: i.isEven ? const Color(0xFFFDF8F0) : const Color(0xFFF8F0E0),
                  title: Text(
                    '${s.surahNameAr} (${_arabicNumeral(s.surahNo)})',
                    style: const TextStyle(fontFamily: 'Amiri', fontSize: 18),
                  ),
                  subtitle: Text(
                    'الصفحة ${s.page}',
                    style: const TextStyle(fontFamily: 'Amiri', color: Color(0xFF8B7D6B)),
                  ),
                  trailing: const Icon(Icons.arrow_back, color: Color(0xFFD5BC7C)),
                  onTap: () => onGoToPage(s.page),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VerseSearchTab extends StatefulWidget {
  final String query;
  final TextEditingController ctrl;
  final _GoToPage onGoToPage;

  const _VerseSearchTab({
    required this.query,
    required this.ctrl,
    required this.onGoToPage,
  });

  @override
  State<_VerseSearchTab> createState() => _VerseSearchTabState();
}

class _VerseSearchTabState extends State<_VerseSearchTab> {
  List<Map<String, dynamic>>? _results;
  bool _loading = false;
  static List? _cachedData;

  @override
  void initState() {
    super.initState();
    if (widget.query.isNotEmpty) _search();
  }

  @override
  void didUpdateWidget(_VerseSearchTab old) {
    super.didUpdateWidget(old);
    if (widget.query != old.query) _search();
  }

  Future<List> _getData() async {
    if (_cachedData != null) return _cachedData!;
    final json = await rootBundle.loadString('assets/ai/QaloonData.json');
    _cachedData = jsonDecode(json) as List;
    return _cachedData!;
  }

  Future<void> _search() async {
    if (widget.query.isEmpty) {
      setState(() { _results = null; _loading = false; });
      return;
    }
    setState(() => _loading = true);
    final normalizedQuery = normalizeArabic(widget.query);
    final data = await _getData();
    final matches = <Map<String, dynamic>>[];
    for (final v in data) {
      final text = (v['aya_text'] as String?) ?? '';
      final nText = normalizeArabic(text);
      if (nText.split(' ').any((w) => w.contains(normalizedQuery))) {
        matches.add(v as Map<String, dynamic>);
        if (matches.length >= 50) break;
      }
    }
    setState(() { _results = matches; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: widget.ctrl,
              decoration: InputDecoration(
                hintText: 'ابحث في نص الآيات',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6C5A3B)),
                filled: true,
                fillColor: const Color(0xFFE9E0CF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontFamily: 'Amiri', fontSize: 16),
            ),
          ),
          if (_results != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${_results!.length} نتيجة',
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 14,
                      color: Color(0xFF6C5A3B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_results == null) {
      return const Center(child: Text(
        'ابدأ الكتابة للبحث',
        style: TextStyle(fontFamily: 'Amiri', color: Color(0xFF8B7D6B)),
      ));
    }
    if (_results!.isEmpty) {
      return const Center(child: Text(
        'لا توجد نتائج',
        style: TextStyle(fontFamily: 'Amiri', color: Color(0xFF8B7D6B)),
      ));
    }
    return ListView.builder(
      itemCount: _results!.length,
      itemBuilder: (_, i) {
        final v = _results![i];
        final suraNo = v['sura_no'] as int;
        final ayaNo = v['aya_no'] as int;
        final page = int.parse((v['page'] as String).split('-')[0]);
        final text = v['aya_text'] as String;
        final suraName = v['sura_name_ar'] as String;
        final highlightKey = '${suraNo.toString().padLeft(3, '0')}${ayaNo.toString().padLeft(3, '0')}';
        return ListTile(
          tileColor: i.isEven ? const Color(0xFFFDF8F0) : const Color(0xFFF8F0E0),
          title: Text(text, style: const TextStyle(fontFamily: 'UthmanicQaloun', fontSize: 20),
            maxLines: 2, overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '$suraName - الآية ${_arabicNumeral(ayaNo)}',
            style: const TextStyle(fontFamily: 'Amiri', color: Color(0xFF8B7D6B)),
          ),
          trailing: const Icon(Icons.arrow_back, color: Color(0xFFD5BC7C)),
          onTap: () => widget.onGoToPage(page, highlight: highlightKey),
        );
      },
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _arabicNumeral(int n) {
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return n.toString().split('').map((c) => digits[int.parse(c)]).join();
}
