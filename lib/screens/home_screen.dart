import 'dart:math';

import 'package:flutter/material.dart';

import '../models/question.dart';
import '../services/connectivity_service.dart';
import '../services/question_repository.dart';
import '../services/storage_service.dart';
import 'lessons_list_screen.dart';
import 'quiz_screen.dart';
import 'settings_screen.dart';
import 'surah_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool? _online;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkOnline();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkOnline();
  }

  Future<void> _checkOnline() async {
    final v = await ConnectivityService.isOnline();
    if (mounted) setState(() => _online = v);
  }

  Future<void> _start(List<Question> pool, String title, int count) async {
    if (pool.isEmpty) return;
    final list = List<Question>.of(pool)..shuffle(Random());
    final picked = count >= list.length ? list : list.sublist(0, count);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => QuizScreen(title: title, questions: picked)),
    );
    if (mounted) setState(() {});
  }

  void _chooseCount(String title, List<Question> pool) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${pool.length} سؤالاً متاحاً'),
            ),
            for (final n in [10, 20])
              if (pool.length > n)
                ListTile(
                  leading: const Icon(Icons.shuffle),
                  title: Text('$n أسئلة عشوائية'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _start(pool, title, n);
                  },
                ),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: Text('كل الأسئلة (${pool.length})'),
              onTap: () {
                Navigator.pop(ctx);
                _start(pool, title, pool.length);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = StorageService.instance;
    final scheme = Theme.of(context).colorScheme;
    final all = QuestionRepository.all();
    final wrong = QuestionRepository.wrongOnes();
    final totalAns = store.totalAnswered;
    final overall = totalAns == 0 ? 0 : (store.totalCorrect * 100 / totalAns).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار التجويد - رواية حفص'),
        actions: [
          IconButton(
            tooltip: 'الإعدادات',
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              if (mounted) {
                setState(() {});
                _checkOnline();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _checkOnline,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // حالة الاتصال
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Chip(
                avatar: Icon(
                  _online == true ? Icons.cloud_done : Icons.cloud_off,
                  size: 18,
                  color: _online == true ? Colors.green.shade700 : Colors.grey.shade700,
                ),
                label: Text(
                  _online == null
                      ? 'جارٍ فحص الاتصال...'
                      : _online == true
                          ? 'متصل: الصوتيات والآيات الكاملة متاحة'
                          : 'دون اتصال: يعمل البنك المحلي بالكامل',
                ),
              ),
            ),
            const SizedBox(height: 8),
            // ملخص التقدم
            Card(
              color: scheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('مستواك العام', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(
                            totalAns == 0 ? 'ابدأ أول اختبار' : '$overall%  (أجبت عن $totalAns سؤالاً)',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.emoji_events, size: 40, color: scheme.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // سلسلة شروح التجويد
            Card(
              color: scheme.tertiaryContainer,
              child: ListTile(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LessonsListScreen()),
                  );
                },
                leading: CircleAvatar(
                  backgroundColor: scheme.tertiary,
                  child: Icon(Icons.menu_book, color: scheme.onTertiary),
                ),
                title: const Text(
                  'سلسلة شروح التجويد',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  '26 درسًا مفصّلًا مع أمثلة قرآنية مستندة إلى منهج الشيخ أيمن رشدي سويد',
                ),
                trailing: const Icon(Icons.chevron_left),
              ),
            ),
            const SizedBox(height: 12),
            // وضع القراءة والتصحيح الصوتي
            Card(
              color: scheme.secondaryContainer,
              child: ListTile(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SurahListScreen()),
                  );
                  if (mounted) setState(() {});
                },
                leading: CircleAvatar(
                  backgroundColor: scheme.secondary,
                  child: Icon(Icons.mic, color: scheme.onSecondary),
                ),
                title: const Text('اقرأ القرآن وصحّح تلاوتك',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('اقرأ آية بصوتك ويُظهر لك التطبيق الكلمات التي أخطأت فيها'),
                trailing: const Icon(Icons.chevron_left),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _start(all, 'اختبار شامل', 20),
              icon: const Icon(Icons.shuffle),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('اختبار شامل (20 سؤالاً عشوائياً)'),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: wrong.isEmpty ? null : () => _start(wrong, 'مراجعة أخطائي', wrong.length),
              icon: const Icon(Icons.history),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('مراجعة أخطائي (${wrong.length})'),
              ),
            ),
            const SizedBox(height: 18),
            const Text('الأقسام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final c in QuizCategory.values)
              _CategoryTile(
                category: c,
                questionCount: all.where((q) => q.category == c).length,
                onTap: () => _chooseCount(c.title, QuestionRepository.byCategory(c)),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.questionCount,
    required this.onTap,
  });

  final QuizCategory category;
  final int questionCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final store = StorageService.instance;
    final scheme = Theme.of(context).colorScheme;
    final answered = store.answered(category);
    final acc = store.accuracy(category);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(category.icon, color: scheme.primary),
        ),
        title: Text(category.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                answered == 0
                    ? '$questionCount سؤالاً'
                    : '$questionCount سؤالاً  •  دقتك ${(acc * 100).round()}%',
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: acc, minHeight: 5),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_left),
      ),
    );
  }
}
