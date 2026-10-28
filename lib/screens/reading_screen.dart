import 'package:flutter/material.dart';

import '../data/surahs.dart';
import '../services/mushaf_service.dart';
import '../services/storage_service.dart';
import '../theme/quran_font.dart';
import '../widgets/app_skeleton.dart';
import 'memorization_report_screen.dart';
import 'practice_screen.dart';

/// عرض السورة للقراءة. الضغط على أي آية يفتح شاشة التسميع والتصحيح لتلك الآية.
class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key, required this.surahNumber, this.jumpToAyah});

  final int surahNumber;
  final int? jumpToAyah;

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  SurahData? _surah;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final s = await MushafService.getSurah(widget.surahNumber);
    if (!mounted) return;
    setState(() {
      _surah = s;
      _loading = false;
      _failed = s == null;
    });
    if (s != null && widget.jumpToAyah != null) {
      final idx = s.ayat.indexWhere((a) => a.number == widget.jumpToAyah);
      if (idx >= 0) _openPractice(idx);
    }
  }

  Future<void> _openPractice(int index) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PracticeScreen(surah: _surah!, startIndex: index)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openReport() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MemorizationReportScreen(surahNumber: widget.surahNumber),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.surahNumber;
    return Scaffold(
      appBar: AppBar(
        title: Text('سورة ${surahName(n)}'),
        actions: [
          IconButton(
            tooltip: 'تقرير ضعف الحفظ',
            icon: const Icon(Icons.analytics_outlined),
            onPressed: _loading || _failed ? null : _openReport,
          ),
        ],
      ),
      body: _loading
          ? const AppSkeletonList(count: 10)
          : _failed
              ? _ErrorView(onRetry: _load)
              : _buildSurah(context),
    );
  }

  Widget _buildSurah(BuildContext context) {
    final surah = _surah!;
    final store = StorageService.instance;
    final scheme = Theme.of(context).colorScheme;
    final showBasmala = surah.number != 1 && surah.number != 9;
    final count = surah.ayat.length;
    final mastered = store.masteredAyat(surah.number, count);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'اقرأ الآية بصوتك: اضغط على أي آية ثم على زر الميكروفون. أثناء القراءة يظهر تلوين فوري للكلمات. من أيقونة التقرير أعلى الشاشة تعرض الآيات الضعيفة.',
            style: TextStyle(height: 1.7, fontSize: 14),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          color: scheme.secondaryContainer,
          child: ListTile(
            onTap: _openReport,
            leading: Icon(Icons.analytics, color: scheme.secondary),
            title: const Text('تقرير ضعف الحفظ', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              mastered == 0
                  ? 'لم تُسجَّل محاولات بعد في هذه السورة'
                  : 'أتقنت $mastered من $count آية · اضغط لعرض التفاصيل',
            ),
            trailing: const Icon(Icons.chevron_left),
          ),
        ),
        if (showBasmala)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Text(
              'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: quranFontFamily,
                fontSize: 26,
                height: 2,
                color: Color(0xFF0B3D2E),
              ),
            ),
          ),
        for (var i = 0; i < surah.ayat.length; i++)
          Builder(builder: (context) {
            final a = surah.ayat[i];
            final score = store.ayahBestScore(surah.number, a.number);
            return Card(
              margin: const EdgeInsets.only(top: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openPractice(i),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        a.text,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: quranFontFamily,
                          fontSize: 24,
                          height: 2.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: scheme.primaryContainer,
                            child: Text(
                              arabicDigits(a.number),
                              style: TextStyle(fontSize: 12, color: scheme.primary),
                            ),
                          ),
                          const Spacer(),
                          if (score != null)
                            Chip(
                              visualDensity: VisualDensity.compact,
                              avatar: Icon(
                                score >= 0.9
                                    ? Icons.verified
                                    : score >= 0.8
                                        ? Icons.trending_up
                                        : Icons.error_outline,
                                size: 16,
                                color: score >= 0.9
                                    ? Colors.green.shade700
                                    : score >= 0.8
                                        ? Colors.orange.shade800
                                        : Colors.red.shade700,
                              ),
                              label: Text('أفضل نتيجة ${(score * 100).round()}%'),
                            )
                          else
                            const Icon(Icons.mic_none, color: Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'تعذّر تحميل السورة. تحتاج اتصالاً بالإنترنت في أول مرة فقط، وبعدها تُحفظ على جهازك وتعمل دون اتصال.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.7),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
