import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../services/advanced_check.dart';
import '../services/storage_service.dart';

/// فحص متقدم للحركات والتجويد عبر خادم quran-muaalem (اختياري، يحتاج اتصالاً وخادماً).
class AdvancedCheckScreen extends StatefulWidget {
  const AdvancedCheckScreen({super.key});

  @override
  State<AdvancedCheckScreen> createState() => _AdvancedCheckScreenState();
}

class _AdvancedCheckScreenState extends State<AdvancedCheckScreen> {
  final _recorder = AudioRecorder();
  late final TextEditingController _url;
  bool _recording = false;
  bool _busy = false;
  String? _error;
  AdvancedCheckResult? _result;

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: StorageService.instance.muaalemUrl);
  }

  @override
  void dispose() {
    _url.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_busy) return;
    final url = _url.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'أدخل عنوان الخادم أولاً.');
      return;
    }
    await StorageService.instance.setMuaalemUrl(url);
    try {
      if (_recording) {
        final path = await _recorder.stop();
        setState(() {
          _recording = false;
          _busy = true;
          _error = null;
        });
        if (path == null) throw Exception('لم يُحفظ التسجيل');
        final r = await AdvancedCheck.analyze(url, File(path));
        if (mounted) setState(() => _result = r);
      } else {
        if (!await _recorder.hasPermission()) {
          setState(() => _error = 'لا يوجد إذن للميكروفون.');
          return;
        }
        final dir = await getTemporaryDirectory();
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1),
          path: '${dir.path}/advanced_check.wav',
        );
        setState(() {
          _recording = true;
          _result = null;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recording = false;
          _error = 'تعذّر الفحص: $e\nتأكد أن الخادم يعمل وأن العنوان صحيح.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _test() async {
    final ok = await AdvancedCheck.ping(_url.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'الخادم يستجيب ✓' : 'لا يستجيب الخادم')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('فحص متقدم للحركات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.amber.shade50,
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'ميزة تجريبية اختيارية: يُرسل تسجيلك إلى خادم تشغّله أنت (نموذج مفتوح المصدر '
                'quran-muaalem) فيقارن نطقك بالمتوقع ويرصد الحركات وأحكام التجويد. '
                'دقته محدودة (نحو ٧٦٪ في أحكام التجويد)، فما يظهر «اشتباه» لا حكم، '
                'والمرجع الحقّ مقرئ مجاز. اقرأ أي آية بصوت واضح وبدون تشويش.',
                style: TextStyle(height: 1.7, fontSize: 13.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _url,
            textDirection: TextDirection.ltr,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: 'عنوان الخادم',
              hintText: 'http://192.168.1.10:8001',
              border: const OutlineInputBorder(),
              suffixIcon: TextButton(onPressed: _test, child: const Text('اختبار')),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _toggle,
            icon: Icon(_recording ? Icons.stop : Icons.mic),
            label: Text(_busy
                ? 'جارٍ التحليل...'
                : _recording
                    ? 'إيقاف وفحص'
                    : 'ابدأ التسجيل'),
          ),
          if (_busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: TextStyle(color: scheme.error, height: 1.6)),
            ),
          if (_result != null) ..._resultWidgets(_result!),
        ],
      ),
    );
  }

  List<Widget> _resultWidgets(AdvancedCheckResult r) {
    if (!r.matched) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(r.message ?? 'لم يُعثر على آية مطابقة، أعد المحاولة بوضوح أكبر.'),
        ),
      ];
    }
    return [
      Card(
        margin: const EdgeInsets.only(top: 16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('النص المطابق', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(r.uthmaniText!, style: const TextStyle(fontSize: 20, height: 2)),
            ],
          ),
        ),
      ),
      if (r.errors.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text('لم يرصد النموذج أخطاء. ما شاء الله، لكن لا يغني عن مقرئ.'),
        )
      else
        for (final e in r.errors)
          Card(
            child: ListTile(
              title: Text('${e.actionLabel} · ${e.typeLabel}'),
              subtitle: Text(
                'المتوقع: ${e.expected}\nالمسموع: ${e.heard}'
                '${e.expectedLen != null ? '\nالمقدار: ${e.heardLen ?? '؟'} بدل ${e.expectedLen}' : ''}'
                '${e.ruleNames.isNotEmpty ? '\nالحكم: ${e.ruleNames.join('، ')}' : ''}',
                style: const TextStyle(height: 1.6),
              ),
            ),
          ),
    ];
  }
}
