import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/question.dart';
import '../services/connectivity_service.dart';
import '../services/question_repository.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
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
  DateTime? _lastBackPress;

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
    if (!mounted || v == _online) return;
    setState(() => _online = v);
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    QuestionRepository.invalidate();
    if (mounted) _checkOnline();
  }

  Future<void> _start(List<Question> pool, String title, int count) async {
    if (pool.isEmpty) return;
    final list = List<Question>.of(pool)..shuffle(Random());
    final picked = count >= list.length ? list : list.sublist(0, count);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => QuizScreen(title: title, questions: picked)),
    );
  }

  void _chooseCount(String title, List<Question> pool) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                subtitle: Text('${pool.length} سؤالاً متاحاً'),
              ),
              for (final n in const [10, 20])
                if (pool.length > n)
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.shuffle, size: 20)),
                    title: Text('$n أسئلة عشوائية'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _start(pool, title, n);
                    },
                  ),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.all_inclusive, size: 20)),
                title: Text('كل الأسئلة (${pool.length})'),
                onTap: () {
                  Navigator.pop(ctx);
                  _start(pool, title, pool.length);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPress != null &&
            now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
          await SystemNavigator.pop();
          return;
        }
        _lastBackPress = now;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('اضغط رجوع مرة أخرى للخروج'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: _checkOnline,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SpiverAppBarFix(onSettings: _openSettings),
              SpiverBody(online: _online, onStart: _start, onChooseCount: _chooseCount),
            ],
          ),
        ),
      ),
    );
  }
}

class SpiverAppBarFix extends StatelessWidget {
  const SpiverAppBarFix({super.key, required this.onSettings});
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return SLiverAppBarSafe(onSettings: onSettings);
  }
}

class SLiverAppBarSafe extends StatelessWidget {
  const SLiverAppBarSafe({super.key, required this.onSettings});
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return SLiverAppBar(onSettings: onSettings);
  }
}

class SLiverAppBar extends StatelessWidget {
  const SLiverAppBar({super.key, required this.onSettings});
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      actions: [
        IconButton(
          tooltip: 'الإعدادات',
          icon: const Icon(Icons.settings_outlined),
          onPressed: onSettings,
        ),
      ],
      flexibleSpace: const FlexibleSpaceBar(
        titlePadding: EdgeInsetsDirectional.only(start: 16, bottom: 14, end: 56),
        title: Text('إتقان'),
        background: _AppBarBackground(),
      ),
    );
  }
}

class SpiverBody extends StatelessWidget {
  const SpiverBody({
    super.key,
    required this.online,
    required this.onStart,
    required this.onChooseCount,
  });

  final bool? online;
  final Future<void> Function(List<Question> pool, String title, int count) onStart;
  final void Function(String title, List<Question> pool) onChooseCount;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _StatusChip(online: online),
          const SizedBox(height: 14),
          ListenableBuilder(
            listenable: StorageService.instance,
            builder: (context, _) {
              final store = StorageService.instance;
              final all = QuestionRepository.all();
              final wrong = QuestionRepository.wrongOnes();
              final due = QuestionRepository.dueOnes();
              final totalAns = store.totalAnswered;
              final overall =
                  totalAns == 0 ? 0 : (store.totalCorrect * 100 / totalAns).round();
              final dailyDone = store.dailyQuizCount;
              final dailyGoal = StorageService.dailyQuizGoal;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _LevelCard(overall: overall, totalAns: totalAns),
                  const SizedBox(height: 12),
                  Material(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () => onStart(all, 'اختبار سريع', 10),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0x0F000000)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.bolt_rounded, color: AppColors.gold),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'هدف اليوم · اختبار سريع',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Text(
                                  '$dailyDone/$dailyGoal',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (dailyDone / dailyGoal).clamp(0.0, 1.0),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _SectionLabel('التعلّم والتلاوة'),
                  const SizedBox(height: 10),
                  _FeatureCard(
                    icon: Icons.play_circle_fill_rounded,
                    iconBg: const Color(0xFFE8F5EF),
                    iconColor: AppColors.primary,
                    title: 'شرح التجويد المصور',
                    subtitle: '45 حلقة للشيخ أيمن سويد على يوتيوب',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LessonsListScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _FeatureCard(
                    icon: Icons.mic_rounded,
                    iconBg: const Color(0xFFEAF2FB),
                    iconColor: const Color(0xFF1E5F8A),
                    title: 'اقرأ وصحّح تلاوتك',
                    subtitle: 'تسميع بالتعرف الصوتي مع تنبيه فوري للأخطاء',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SurahListScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  const _SectionLabel('الاختبارات'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.shuffle_rounded,
                          label: 'شامل',
                          hint: '20 سؤالاً',
                          filled: true,
                          onTap: () => onStart(all, 'اختبار شامل', 20),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.event_repeat_rounded,
                          label: 'اليوم',
                          hint: due.isEmpty ? 'لا شيء' : '${due.length}',
                          enabled: due.isNotEmpty,
                          onTap: due.isEmpty
                              ? null
                              : () => onStart(due, 'مراجعة اليوم', due.length),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.history_rounded,
                          label: 'أخطائي',
                          hint: wrong.isEmpty ? '0' : '${wrong.length}',
                          enabled: wrong.isNotEmpty,
                          onTap: wrong.isEmpty
                              ? null
                              : () => onStart(wrong, 'مراجعة أخطائي', wrong.length),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const _SectionLabel('أقسام الأسئلة'),
                  const SizedBox(height: 10),
                  for (final c in QuizCategory.values) ...[
                    _CategoryCard(
                      category: c,
                      questionCount: QuestionRepository.countInCategory(c),
                      onTap: () => onChooseCount(c.title, QuestionRepository.byCategory(c)),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
          if (online == false)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'أنت في وضع عدم الاتصال — البنك المحلي يعمل بالكامل.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.5),
              ),
            ),
        ]),
      ),
    );
  }
}

class _AppBarBackground extends StatelessWidget {
  const _AppBarBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
        ),
      ),
      child: Align(
        alignment: AlignmentDirectional.bottomStart,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 48),
          child: Text(
            'مراجعة · تسميع · تصحيح',
            style: TextStyle(color: Color(0xD9FFFFFF), fontSize: 13),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.online});
  final bool? online;

  @override
  Widget build(BuildContext context) {
    final isOn = online == true;
    final isOff = online == false;
    final color = isOn ? const Color(0xFF1B7A4E) : (isOff ? AppColors.muted : AppColors.gold);
    final bg = isOn ? const Color(0xFFE6F4EC) : (isOff ? const Color(0xFFEEF0EE) : AppColors.goldSoft);
    final text = online == null
        ? 'جارٍ فحص الاتصال...'
        : isOn
            ? 'متصل — الصوتيات والآيات متاحة'
            : 'دون اتصال — البنك المحلي جاهز';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(
            isOn
                ? Icons.cloud_done_rounded
                : (isOff ? Icons.cloud_off_rounded : Icons.cloud_queue_rounded),
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.overall, required this.totalAns});
  final int overall;
  final int totalAns;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0B6E4F), Color(0xFF147A58)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('مستواك العام',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                const SizedBox(height: 6),
                Text(
                  totalAns == 0 ? 'ابدأ أول اختبار' : '$overall%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                if (totalAns > 0) ...[
                  const SizedBox(height: 4),
                  Text('أجبت عن $totalAns سؤالاً',
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                ],
              ],
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFE08A), size: 34),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x0F000000)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: const TextStyle(color: AppColors.muted, height: 1.35, fontSize: 12.5)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.hint,
    this.onTap,
    this.filled = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback? onTap;
  final bool filled;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final active = enabled && onTap != null;
    final bg = filled && active
        ? AppColors.primary
        : (active ? Theme.of(context).cardColor : const Color(0xFFF0F0EC));
    final fg = filled && active
        ? Colors.white
        : (active ? AppColors.ink : AppColors.muted);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: active ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: filled && active ? null : Border.all(color: const Color(0x0F000000)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 22),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 2),
              Text(hint, style: TextStyle(color: fg.withOpacity(0.75), fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
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
    final answered = store.answered(category);
    final acc = store.accuracy(category);

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x0F000000)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(category.icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(
                      answered == 0
                          ? '$questionCount سؤالاً'
                          : '$questionCount سؤالاً  ·  دقتك ${(acc * 100).round()}%',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                    ),
                    if (answered > 0) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: acc,
                          minHeight: 5,
                          backgroundColor: const Color(0xFFE2E8E4),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
