import 'dart:async';

import 'package:flutter/material.dart';

import '../data/surahs.dart';
import '../services/mushaf_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'reading_screen.dart';

/// قائمة السور + بحث بالاسم/الرقم/كلمات القرآن المحفوظة.
class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  final TextEditingController _search = TextEditingController();
  Set<int> _cached = {};
  String _query = '';
  List<AyahSearchHit> _ayahHits = const [];
  bool _searching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadCached();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadCached() async {
    final c = await MushafService.cachedSurahs();
    if (mounted) setState(() => _cached = c);
  }

  void _onQueryChanged(String v) {
    setState(() => _query = v);
    _debounce?.cancel();
    final q = v.trim();
    if (q.length < 2) {
      setState(() {
        _ayahHits = const [];
        _searching = false;
      });
      return;
    }
    // إن كان رقم سورة أو اسم سورة قصير — لا نمنع بحث الآيات أيضاً
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 320), () async {
      final hits = await MushafService.searchAyat(q, limit: 50);
      if (!mounted || _search.text.trim() != q) return;
      setState(() {
        _ayahHits = hits;
        _searching = false;
      });
    });
  }

  Future<void> _open(int surah, {int? ayah}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReadingScreen(surahNumber: surah, jumpToAyah: ayah),
      ),
    );
    if (mounted) {
      setState(() {});
      _loadCached();
    }
  }

  List<int> _matchingSurahs(String q) {
    if (q.isEmpty) return [for (var i = 1; i <= 114; i++) i];
    final asNum = int.tryParse(q);
    return [
      for (var i = 1; i <= 114; i++)
        if ((asNum != null && i == asNum) || surahName(i).contains(q)) i,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final store = StorageService.instance;
    final scheme = Theme.of(context).colorScheme;
    final last = store.lastPosition;
    final q = _query.trim();
    final surahs = _matchingSurahs(q);
    final showAyahSection = q.length >= 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('اقرأ وصحّح'),
        actions: [
          if (_cached.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: Center(
                child: Text(
                  '${_cached.length}/114 محفوظ',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // شريط بحث مُحسَّن
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'اسم سورة · رقم · أو كلمة من القرآن',
                helperText: _cached.isEmpty
                    ? 'ابحث بالاسم/الرقم الآن — بحث الكلمات بعد حفظ السور من الإعدادات'
                    : 'البحث في الكلمات يعمل على السور المحفوظة على جهازك',
                helperMaxLines: 2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                suffixIcon: q.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'مسح',
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _search.clear();
                          _onQueryChanged('');
                        },
                      ),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                // متابعة القراءة
                if (last != null && q.isEmpty) ...[
                  Material(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _open(last.$1, ayah: last.$2),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: scheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.bookmark_rounded,
                                  color: scheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'متابعة من حيث توقفت',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'سورة ${surahName(last.$1)} · الآية ${arabicDigits(last.$2)}',
                                    style: TextStyle(
                                      color: scheme.onPrimaryContainer
                                          .withOpacity(0.85),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_left_rounded,
                                color: scheme.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // نتائج آيات (كلمات القرآن)
                if (showAyahSection) ...[
                  _SectionHeader(
                    title: 'آيات مطابقة',
                    trailing: _searching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            '${_ayahHits.length}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  if (!_searching && _ayahHits.isEmpty)
                    _EmptyHint(
                      text: _cached.isEmpty
                          ? 'لا توجد سور محفوظة بعد. افتح سورة مرة أو حمّل المصحف من الإعدادات لتفعيل بحث الكلمات.'
                          : 'لم يُعثر على «$q» في النصوص المحفوظة.',
                    )
                  else
                    for (final h in _ayahHits)
                      _AyahHitCard(
                        hit: h,
                        query: q,
                        onTap: () => _open(h.surah, ayah: h.ayah),
                      ),
                  const SizedBox(height: 18),
                ],

                // السور
                _SectionHeader(
                  title: q.isEmpty ? 'السور' : 'السور المطابقة',
                  trailing: Text(
                    '${surahs.length}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (surahs.isEmpty)
                  const _EmptyHint(text: 'لا توجد سورة بهذا الاسم أو الرقم.')
                else
                  for (final n in surahs)
                    _SurahCard(
                      number: n,
                      cached: _cached.contains(n),
                      mastered: store.masteredAyat(n, surahAyahCount(n)),
                      total: surahAyahCount(n),
                      onTap: () => _open(n),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x0F000000)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.muted,
          height: 1.55,
          fontSize: 13.5,
        ),
      ),
    );
  }
}

class _AyahHitCard extends StatelessWidget {
  const _AyahHitCard({
    required this.hit,
    required this.query,
    required this.onTap,
  });

  final AyahSearchHit hit;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x0F000000)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${surahName(hit.surah)} · ${arabicDigits(hit.ayah)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.mic_none_rounded,
                        size: 18, color: scheme.primary),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  hit.text,
                  textAlign: TextAlign.right,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.75,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SurahCard extends StatelessWidget {
  const _SurahCard({
    required this.number,
    required this.cached,
    required this.mastered,
    required this.total,
    required this.onTap,
  });

  final int number;
  final bool cached;
  final int mastered;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = total == 0 ? 0.0 : (mastered / total).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x0F000000)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$number',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سورة ${surahName(number)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mastered == 0
                            ? '$total آية'
                            : '$total آية · أتقنت $mastered',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                        ),
                      ),
                      if (mastered > 0) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: const Color(0xFFE2E8E4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  cached
                      ? Icons.download_done_rounded
                      : Icons.cloud_download_outlined,
                  color: cached ? Colors.green.shade700 : Colors.grey,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
