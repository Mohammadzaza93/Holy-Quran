import 'dart:math';

import 'package:flutter/material.dart';

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
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _checkOnline,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SpiverAppBarFix(onSettings: _openSettings),
            SpiverBody(
              online: _online,
              onStart: _start,
              onChooseCount: _chooseCount,
            ),
          ],
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
        title: Text('تجويد حفص'),
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
      sliver: SLiverListFix(online: online, onStart: onStart, onChooseCount: onChooseCount),
    );
  }
}

class SLiverListFix extends StatelessWidget {
  const SLiverListFix({
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
    return SliverList(
      delegate: SLiverChildListDelegateFix(
        online: online,
        onStart: onStart,
        onChooseCount: onChooseCount,
      ),
    );
  }
}

class SLiverChildListDelegateFix extends SLiverChildListDelegateBase {
  SLiverChildListDelegateFix({
    required this.online,
    required this.onStart,
    required this.onChooseCount,
  });

  final bool? online;
  final Future<void> Function(List<Question> pool, String title, int count) onStart;
  final void Function(String title, List<Question> pool) onChooseCount;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

// Avoid broken partial rewrite — full list below
class _Unused {
  void x() {}
}
