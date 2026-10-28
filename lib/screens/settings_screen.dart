import 'package:flutter/material.dart';

import '../services/ayah_text_service.dart';
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
    _reciter =
        reciters.containsKey(store.reciter) ? store.reciter : StorageService.defaultReciter;
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
      _status = 'جارٍ حفظ نص المصحف...';
    });
    final n = await MushafService.downloadAllSurahs(
      onProgress: (done, total) {
        if (mounted) setState(() => _progress = total == 0 ? 1 : done / total);
      },
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _progress = null;
      _status = 'تم حفظ نص $n سورة محلياً';
    });
  }

  Future<void> _downloadTexts() async {
    if (_busy || !await _requireOnline()) return;
    setState(() {
      _busy = true;
      _progress = 0;
      _status = 'جارٍ حفظ التفسير والترجمة...';
    });
    final n = await AyahTextService.downloadAll(
      onProgress: (done, total) {
        if (mounted) setState(() => _progress = total == 0 ? 1 : done / total);
      },
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _progress = null;
      _status = 'تم تجهيز التفسير والترجمة لـ $n سورة';
    });
  }

  Future<void> _clearAudio() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('مسح الصوتيات؟'),
        content: const Text('سيتم حذف التلاوات المحمّلة. يمكن إعادة تحميلها لاحقاً.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('مسح')),
        ],
      ),
    );
    if (ok != true) return;
    await QuranService.clearDownloadedAudio();
    await _refreshSize();
    if (mounted) _snack('تم مسح الصوتيات المحمّلة');
  }

  Future<void> _saveRemoteUrl() async {
    await StorageService.instance.setRemoteUrl(_urlController.text.trim());
    QuestionRepository.invalidate();
    if (mounted) _snack('تم حفظ رابط بنك الأسئلة');
  }

  Future<void> _refreshQuestions() async {
    if (_busy || !await _requireOnline()) return;
    setState(() {
      _busy = true;
      _status = 'جارٍ جلب الأسئلة...';
    });
    try {
      await QuestionRepository.refreshRemote();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = 'تم تحديث الأسئلة';
      });
      _snack('تم تحديث بنك الأسئلة');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = 'تعذّر التحديث';
      });
      _snack('تعذّر تحديث الأسئلة');
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StorageService.instance;
    final readLessons = store.readLessonsCount;
    final themeName = store.themeModeName;

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _SettingsCard(
            icon: Icons.brightness_6_rounded,
            title: 'المظهر',
            child: Column(
              children: [
                for (final e in const [
                  ('system', 'حسب النظام'),
                  ('light', 'فاتح'),
                  ('dark', 'داكن'),
                ])
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(e.$2),
                    value: e.$1,
                    groupValue: themeName,
                    onChanged: (v) async {
                      if (v == null) return;
                      await StorageService.instance.setThemeModeName(v);
                      setState(() {});
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            icon: Icons.record_voice_over_rounded,
            title: 'القارئ والتلاوة',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: _reciter,
                  decoration: const InputDecoration(
                    labelText: 'القارئ',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final e in reciters.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: _busy
                      ? null
                      : (v) async {
                          if (v == null) return;
                          await StorageService.instance.setReciter(v);
                          setState(() => _reciter = v);
                        },
                ),
                const SizedBox(height: 12),
                Text(
                  'الصوتيات المحمّلة: ${_audioMb.toStringAsFixed(1)} م.ب',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                if (_progress != null) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: _progress),
                ],
                if (_status != null) ...[
                  const SizedBox(height: 8),
                  Text(_status!, style: const TextStyle(fontSize: 13, height: 1.4)),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy ? null : _downloadForOffline,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('تحميل صوتيات للاستخدام دون اتصال'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _clearAudio,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('مسح الصوتيات المحمّلة'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            icon: Icons.mic_rounded,
            title: 'التعرف والمحتوى دون اتصال',
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
                  title: const Text('التعرف على الجهاز',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                    'يعمل دون إنترنت إن كانت حزمة العربية محمّلة على الجهاز',
                    style: TextStyle(height: 1.4, fontSize: 12.5),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : _downloadSurahs,
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('حفظ نص المصحف كاملاً'),
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : _downloadTexts,
                  icon: const Icon(Icons.translate_rounded),
                  label: const Text('حفظ التفسير والترجمة دون اتصال'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            icon: Icons.sync_rounded,
            title: 'تحديث الأسئلة',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'رابط JSON للأسئلة (اختياري)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy ? null : _saveRemoteUrl,
                        child: const Text('حفظ الرابط'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _busy ? null : _refreshQuestions,
                        child: const Text('تحديث الآن'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            icon: Icons.restart_alt_rounded,
            title: 'إعادة التعيين',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                          await StorageService.instance.clearQuizProgress();
                          if (mounted) _snack('تم مسح تقدم الاختبارات');
                        },
                  icon: const Icon(Icons.quiz_outlined),
                  label: const Text('مسح تقدم الاختبارات'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                          await StorageService.instance.clearLessonProgress();
                          if (mounted) {
                            setState(() {});
                            _snack('تم مسح تقدم الحلقات');
                          }
                        },
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
        color: Theme.of(context).cardColor,
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
