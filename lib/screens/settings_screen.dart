import 'package:flutter/material.dart';

import '../services/connectivity_service.dart';
import '../services/mushaf_service.dart';
import '../services/question_repository.dart';
import '../services/quran_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _urlController;
  late String _reciter;
  bool _busy = false;
  String? _status;
  double _audioMb = 0;
  double? _progress;
  bool _onDevice = false;

  @override
  void initState() {
    super.initState();
    final store = StorageService.instance;
    _urlController = TextEditingController(text: store.remoteUrl);
    _reciter = reciters.containsKey(store.reciter) ? store.reciter : StorageService.defaultReciter;
    _onDevice = store.onDeviceSpeech;
    _refreshSize();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _refreshSize() async {
    final mb = await QuranService.downloadedAudioSizeMb();
    if (mounted) setState(() => _audioMb = mb);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<bool> _requireOnline() async {
    if (await ConnectivityService.isOnline()) return true;
    _snack('لا يوجد اتصال بالإنترنت');
    return false;
  }

  Future<void> _downloadForOffline() async {
    if (_busy || !await _requireOnline()) return;
    setState(() {
      _busy = true;
      _progress = 0;
      _status = 'جارٍ تحميل الآيات والصوتيات...';
    });
    final result = await QuranService.downloadAllForOffline(
      QuestionRepository.all(),
      onProgress: (done, total) {
        if (mounted) setState(() => _progress = total == 0 ? 1 : done / total);
      },
    );
    await _refreshSize();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _progress = null;
      _status = 'تم تجهيز ${result.done} من ${result.total} آية للعمل دون اتصال';
    });
  }

  Future<void> _downloadSurahs() async {
    if (_busy || !await _requireOnline()) return;
    setState(() {
      _busy = true;
      _progress = 0;
      _status = 'جارٍ تحميل السور (114 سورة)...';
    });
    final ok = await MushafService.downloadAll(
      onProgress: (done, total) {
        if (mounted) setState(() => _progress = done / total);
      },
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _progress = null;
      _status = ok == 114
          ? 'تم حفظ المصحف كاملاً للقراءة دون اتصال'
          : 'تم حفظ $ok من 114 سورة. أعد المحاولة لإكمال الباقي';
    });
  }

  Future<void> _updateQuestions() async {
    if (_busy || !await _requireOnline()) return;
    setState(() {
      _busy = true;
      _status = 'جارٍ تحديث الأسئلة...';
    });
    final error = await QuestionRepository.updateFromUrl(_urlController.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = error ??
          'تم التحديث: ${QuestionRepository.remoteCount} سؤالاً إضافياً محفوظة للعمل دون اتصال';
    });
  }

  Future<void> _confirm(String title, String body, Future<void> Function() onYes) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title),
        content: Text(body, style: const TextStyle(height: 1.6)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تأكيد')),
        ],
      ),
    );
    if (yes == true) await onYes();
  }

  @override
  Widget build(BuildContext context) {
    final readLessons = StorageService.instance.readLessonsCount;
    final remoteCount = QuestionRepository.remoteCount;

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          // ─── القارئ ───
          _SettingsCard(
            icon: Icons.record_voice_over_rounded,
            title: 'القارئ',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'اختر صوت التلاوة المرجعية (رواية حفص عن عاصم)',
                  style: TextStyle(color: AppColors.muted, height: 1.5, fontSize: 13),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'القارئ الحالي',
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _reciter,
                      borderRadius: BorderRadius.circular(14),
                      items: [
                        for (final e in reciters.entries)
                          DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value, style: const TextStyle(fontSize: 14)),
                          ),
                      ],
                      onChanged: _busy
                          ? null
                          : (v) async {
                              if (v == null) return;
                              await StorageService.instance.setReciter(v);
                              setState(() => _reciter = v);
                              await _refreshSize();
                            },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'الصوتيات المحمّلة مرتبطة بالقارئ المختار.',
                  style: TextStyle(color: AppColors.muted.withValues(alpha: 0.9), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─── دون اتصال ───
          _SettingsCard(
            icon: Icons.cloud_download_rounded,
            title: 'العمل دون اتصال',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'البنك المدمج يعمل دائماً بدون إنترنت. حمّل الآيات والتلاوات لتسمع الأمثلة دون اتصال.',
                  style: TextStyle(color: AppColors.muted, height: 1.55, fontSize: 13),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _busy ? null : _downloadForOffline,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('تحميل الآيات والصوتيات'),
                ),
                if (_progress != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(value: _progress, minHeight: 8),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_rounded, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'الصوتيات المحمّلة: ${_audioMb.toStringAsFixed(1)} م.ب',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      if (_audioMb > 0)
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _confirm(
                                    'حذف الصوتيات',
                                    'سيتم حذف ملفات الصوت المحمّلة من الجهاز.',
                                    () async {
                                      await QuranService.deleteDownloadedAudio();
                                      await _refreshSize();
                                      if (mounted) _snack('تم حذف الصوتيات');
                                    },
                                  ),
                          child: const Text('حذف', style: TextStyle(color: Colors.redAccent)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─── القراءة والتصحيح ───
          _SettingsCard(
            icon: Icons.mic_rounded,
            title: 'القراءة والتصحيح',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _onDevice,
                  onChanged: _busy
                      ? null
                      : (v) async {
                          await StorageService.instance.setOnDeviceSpeech(v);
                          setState(() => _onDevice = v);
                        },
                  title: const Text('التعرف على الجهاز', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                    'يعمل دون إنترنت إن كانت حزمة العربية محمّلة على الجهاز',
                    style: TextStyle(height: 1.4, fontSize: 12.5),
                  ),
                  activeTrackColor: AppColors.primary,
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : _downloadSurahs,
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('حفظ نص المصحف كاملاً'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─── تحديث الأسئلة ───
          _SettingsCard(
            icon: Icons.sync_rounded,
            title: 'تحديث الأسئلة',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'أضف أسئلة من ملف JSON على رابط https (مثل GitHub). تُحفظ محلياً وتعمل دون اتصال.',
                  style: TextStyle(color: AppColors.muted, height: 1.55, fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _urlController,
                  enabled: !_busy,
                  keyboardType: TextInputType.url,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    hintText: 'https://example.com/questions.json',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _busy ? null : _updateQuestions,
                        icon: const Icon(Icons.cloud_sync_rounded),
                        label: const Text('تحديث'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: _busy || remoteCount == 0
                          ? null
                          : () => _confirm(
                                'إزالة الأسئلة الإضافية',
                                'ستعود للبنك المدمج فقط.',
                                () async {
                                  await StorageService.instance.clearRemoteQuestions();
                                  if (mounted) {
                                    setState(() => _status = 'أُزيلت الأسئلة الإضافية');
                                  }
                                },
                              ),
                      child: Text('إزالة ($remoteCount)'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_status != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_status!, style: const TextStyle(height: 1.55, fontSize: 13.5)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // ─── البيانات ───
          _SettingsCard(
            icon: Icons.storage_rounded,
            title: 'البيانات',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _confirm(
                            'مسح التقدم',
                            'سيتم حذف إحصائياتك وسجل الأخطاء ونتائج القراءة.',
                            () async {
                              await StorageService.instance.resetProgress();
                              await StorageService.instance.resetReading();
                              if (mounted) _snack('تم مسح التقدم');
                            },
                          ),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('مسح التقدم وسجل الأخطاء'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _busy || readLessons == 0
                      ? null
                      : () => _confirm(
                            'مسح تقدم الحلقات',
                            'سيتم إلغاء تعليم حلقات يوتيوب كمقروءة ($readLessons).',
                            () async {
                              await StorageService.instance.resetLessonProgress();
                              if (mounted) {
                                setState(() {});
                                _snack('تم مسح تقدم الحلقات');
                              }
                            },
                          ),
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: Text('مسح تقدم حلقات يوتيوب ($readLessons)'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.school_rounded, color: Color(0xFF8B6914), size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'هذا التطبيق وسيلة مساعدة للمراجعة، ولا يغني عن التلقي والمشافهة على مقرئ متقن بالسند.',
                    style: TextStyle(fontSize: 12.5, height: 1.65, color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x0F000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
