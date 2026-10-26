import 'package:flutter/material.dart';

import '../services/connectivity_service.dart';
import '../services/mushaf_service.dart';
import '../services/question_repository.dart';
import '../services/quran_service.dart';
import '../services/storage_service.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
      _status = error ?? 'تم التحديث: ${QuestionRepository.remoteCount} سؤالاً إضافياً محفوظة للعمل دون اتصال';
    });
  }

  Future<void> _confirm(String title, String body, Future<void> Function() onYes) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
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
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle('القارئ'),
          DropdownButton<String>(
            isExpanded: true,
            value: _reciter,
            items: [
              for (final e in reciters.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) async {
              if (v == null) return;
              await StorageService.instance.setReciter(v);
              setState(() => _reciter = v);
              await _refreshSize();
            },
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              'جميع القراء المدرجين يقرؤون برواية حفص عن عاصم. الصوتيات المحمّلة مسبقاً مرتبطة بالقارئ المختار.',
              style: TextStyle(fontSize: 13, height: 1.6),
            ),
          ),
          const Divider(height: 28),
          const _SectionTitle('العمل دون اتصال'),
          const Text(
            'البنك المدمج يعمل دائماً دون إنترنت. اضغط الزر لتحميل نصوص الآيات وتلاواتها الخاصة بالأمثلة، لتسمعها وتراها دون اتصال.',
            style: TextStyle(height: 1.7),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _busy ? null : _downloadForOffline,
            icon: const Icon(Icons.download),
            label: const Text('تحميل الآيات والصوتيات للعمل دون اتصال'),
          ),
          if (_progress != null) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(value: _progress),
          ],
          const SizedBox(height: 6),
          Text('الصوتيات المحمّلة: ${_audioMb.toStringAsFixed(1)} م.ب', style: const TextStyle(fontSize: 13)),
          if (_audioMb > 0)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: _busy
                    ? null
                    : () => _confirm('حذف الصوتيات', 'سيتم حذف ملفات الصوت المحمّلة من الجهاز.', () async {
                          await QuranService.deleteDownloadedAudio();
                          await _refreshSize();
                        }),
                child: const Text('حذف الصوتيات المحمّلة'),
              ),
            ),
          const Divider(height: 28),
          const _SectionTitle('القراءة والتصحيح الصوتي'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _onDevice,
            onChanged: (v) async {
              await StorageService.instance.setOnDeviceSpeech(v);
              setState(() => _onDevice = v);
            },
            title: const Text('التعرف على الجهاز (دون إنترنت)'),
            subtitle: const Text(
              'يعمل إن كانت حزمة اللغة العربية للتعرف الصوتي محمّلة على جهازك، وإلا فأوقفه ليستخدم الإنترنت.',
            ),
          ),
          const SizedBox(height: 6),
          FilledButton.tonalIcon(
            onPressed: _busy ? null : _downloadSurahs,
            icon: const Icon(Icons.menu_book),
            label: const Text('حفظ نص المصحف كاملاً للقراءة دون اتصال'),
          ),
          const Divider(height: 28),
          const _SectionTitle('تحديث الأسئلة من الإنترنت'),
          const Text(
            'يمكنك إضافة أسئلة جديدة من ملف JSON على رابط https (مثلاً من GitHub). تُحفظ الأسئلة محلياً وتعمل بعدها دون اتصال.',
            style: TextStyle(height: 1.7),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'https://example.com/questions.json',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _busy ? null : _updateQuestions,
                  icon: const Icon(Icons.sync),
                  label: const Text('تحديث الأسئلة'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _busy || QuestionRepository.remoteCount == 0
                    ? null
                    : () => _confirm('إزالة الأسئلة الإضافية', 'ستعود للبنك المدمج فقط.', () async {
                          await StorageService.instance.clearRemoteQuestions();
                          if (mounted) setState(() => _status = 'أُزيلت الأسئلة الإضافية');
                        }),
                child: Text('إزالة (${QuestionRepository.remoteCount})'),
              ),
            ],
          ),
          if (_status != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_status!, style: const TextStyle(height: 1.6)),
            ),
          const Divider(height: 28),
          const _SectionTitle('البيانات'),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => _confirm('مسح التقدم', 'سيتم حذف إحصائياتك وسجل الأخطاء ونتائج القراءة وتقدمك في الدروس.', () async {
                      await StorageService.instance.resetProgress();
                      await StorageService.instance.resetReading();
                      await StorageService.instance.resetBookLessons();
                      if (mounted) _snack('تم مسح التقدم');
                    }),
            icon: const Icon(Icons.delete_outline),
            label: const Text('مسح التقدم وسجل الأخطاء'),
          ),
          const SizedBox(height: 24),
          const Text(
            'تنبيه: هذا التطبيق وسيلة مساعدة للمراجعة، ولا يغني عن التلقي والمشافهة على مقرئ متقن بالسند.',
            style: TextStyle(fontSize: 13, height: 1.7, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );
}
