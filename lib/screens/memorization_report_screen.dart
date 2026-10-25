import 'package:flutter/material.dart';

import '../data/surahs.dart';
import '../services/mushaf_service.dart';
import '../services/storage_service.dart';
import 'practice_screen.dart';

/// تقرير ضعف الحفظ في سورة واحدة:
/// يصنّف الآيات إلى: لم تُقرأ / ضعيفة / جيدة / متقنة
/// ويسمح بالانتقال مباشرة لممارسة الآيات الضعيفة.
class MemorizationReportScreen extends StatefulWidget {
  const MemorizationReportScreen({super.key, required this.surahNumber});

  final int surahNumber;

  @override
  State<MemorizationReportScreen> createState() => _MemorizationReportScreenState();
}

enum _AyahLevel { unread, weak, good, mastered }

class _AyahRow {
  const _AyahRow({
    required this.index,
    required this.number,
    required this.text,
    required this.score,
    required this.level,
  });

  final int index;
  final int number;
  final String text;
  final double? score;
  final _AyahLevel level;
}

class _MemorizationReportScreenState extends State<MemorizationReportScreen> {
  SurahData? _surah;
  bool _loading = true;
  bool _failed = false;
  List<_AyahRow> _rows = const [];
  String _filter = 'all'; // all | weak | unread

  static const double _weakBelow = 0.8;
  static const double _masteredAt = 0.9;

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
    if (s == null) {
      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }
    final store = StorageService.instance;
    final rows = <_AyahRow>[];
    for (var i = 0; i < s.ayat.length; i++) {
      final a = s.ayat[i];
      final score = store.ayahBestScore(s.number, a.number);
      final level = score == null
          ? _AyahLevel.unread
          : score >= _masteredAt
              ? _AyahLevel.mastered
              : score >= _weakBelow
                  ? _AyahLevel.good
                  : _AyahLevel.weak;
      rows.add(_AyahRow(
        index: i,
        number: a.number,
        text: a.text,
        score: score,
        level: level,
      ));
    }
    setState(() {
      _surah = s;
      _rows = rows;
      _loading = false;
    });
  }

  List<_AyahRow> get _visible {
    switch (_filter) {
      case 'weak':
        return _rows.where((r) => r.level == _AyahLevel.weak || r.level == _AyahLevel.unread).toList();
      case 'unread':
        return _rows.where((r) => r.level == _AyahLevel.unread).toList();
      default:
        return _rows;
    }
  }

  Future<void> _openPractice(int index) async {
    final surah = _surah;
    if (surah == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeScreen(surah: surah, startIndex: index),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _practiceWeak() async {
    final weak = _rows.where((r) => r.level == _AyahLevel.weak || r.level == _AyahLevel.unread).toList();
    if (weak.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد آيات ضعيفة أو غير مقروءة')),
      );
      return;
    }
    await _openPractice(weak.first.index);
  }

  @override
  Widget build(BuildContext context) {
    final name = surahName(widget.surahNumber);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('تقرير الحفظ · $name'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _failed
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'تعذّر تحميل السورة. تحتاج اتصالًا في أول مرة فقط.',
                          textAlign: TextAlign.center,
                          style: TextStyle(height: 1.7),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _load, child: const Text('إعادة المحاولة')),
                      ],
                    ),
                  ),
                )
              : _buildBody(scheme),
      bottomNavigationBar: _surah == null || _loading
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  onPressed: _practiceWeak,
                  icon: const Icon(Icons.fitness_center),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('ممارسة الآيات الضعيفة أولًا'),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildBody(ColorScheme scheme) {
    final unread = _rows.where((r) => r.level == _AyahLevel.unread).length;
    final weak = _rows.where((r) => r.level == _AyahLevel.weak).length;
    final good = _rows.where((r) => r.level == _AyahLevel.good).length;
    final mastered = _rows.where((r) => r.level == _AyahLevel.mastered).length;
    final total = _rows.length;
    final attempted = total - unread;
    final avg = attempted == 0
        ? 0.0
        : _rows.where((r) => r.score != null).map((r) => r.score!).fold(0.0, (a, b) => a + b) /
            attempted;

    final visible = _visible;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Card(
          color: scheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سورة ${surahName(widget.surahNumber)} · $total آية',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  attempted == 0
                      ? 'لم تبدأ تسميع هذه السورة بعد.'
                      : 'متوسط أفضل نتيجة للآيات المقروءة: ${(avg * 100).round()}%',
                  style: const TextStyle(height: 1.5),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statChip('لم تُقرأ', unread, Colors.grey.shade600),
                    _statChip('ضعيفة', weak, Colors.red.shade700),
                    _statChip('جيدة', good, Colors.orange.shade800),
                    _statChip('متقنة', mastered, Colors.green.shade700),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'ضعيفة = أقل من ${(_weakBelow * 100).round()}%  ·  متقنة = ${(_masteredAt * 100).round()}% فأكثر',
                  style: TextStyle(fontSize: 12, color: scheme.onPrimaryContainer.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'all', label: Text('الكل'), icon: Icon(Icons.list)),
            ButtonSegment(value: 'weak', label: Text('الضعيفة'), icon: Icon(Icons.warning_amber)),
            ButtonSegment(value: 'unread', label: Text('لم تُقرأ'), icon: Icon(Icons.radio_button_unchecked)),
          ],
          selected: {_filter},
          onSelectionChanged: (s) => setState(() => _filter = s.first),
        ),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('لا توجد آيات في هذا التصنيف.', textAlign: TextAlign.center),
          )
        else
          for (final row in visible) _ayahTile(row, scheme),
      ],
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Text('$count', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
      ),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _ayahTile(_AyahRow row, ColorScheme scheme) {
    final (Color bg, String label, IconData icon) = switch (row.level) {
      _AyahLevel.unread => (Colors.grey.shade200, 'لم تُقرأ', Icons.radio_button_unchecked),
      _AyahLevel.weak => (const Color(0xFFF8D7D7), 'ضعيفة ${((row.score ?? 0) * 100).round()}%', Icons.error_outline),
      _AyahLevel.good => (const Color(0xFFFFF1C2), 'جيدة ${((row.score ?? 0) * 100).round()}%', Icons.trending_up),
      _AyahLevel.mastered => (const Color(0xFFD7F0DD), 'متقنة ${((row.score ?? 0) * 100).round()}%', Icons.verified),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: bg.withValues(alpha: 0.55),
      child: ListTile(
        onTap: () => _openPractice(row.index),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Text(
            arabicDigits(row.number),
            style: TextStyle(fontSize: 13, color: scheme.primary),
          ),
        ),
        title: Text(
          row.text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 18, height: 1.7),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Icon(icon, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
        trailing: const Icon(Icons.mic),
      ),
    );
  }
}
