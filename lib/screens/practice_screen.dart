import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../data/surahs.dart';
import '../services/connectivity_service.dart';
import '../services/mushaf_service.dart';
import '../services/quran_service.dart';
import '../services/recitation_checker.dart';
import '../services/speech_service.dart';
import '../services/storage_service.dart';
import '../theme/quran_font.dart';

/// شاشة التسميع المحسّنة:
/// - تنبيه فوري أثناء القراءة (مقارنة جزئية وتلوين الكلمات)
/// - وضع الإتقان: لا تنتقل للتالية إلا بعد نسبة مقبولة (أو تجاوز يدوي)
/// - يعمل مجانًا عبر محرك التعرف على الجهاز بدون اشتراك
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key, required this.surah, required this.startIndex});

  final SurahData surah;
  final int startIndex;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final SpeechService _speech = SpeechService.instance;
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerSub;

  late int _index;
  bool _hideText = false;
  bool _listening = false;
  bool _finished = true;
  bool _playing = false;
  bool _loadingAudio = false;

  /// وضع الإتقان: يمنع الانتقال السهل إن كانت النتيجة ضعيفة
  bool _masteryMode = true;
  static const double _masteryThreshold = 0.8;

  String _lastWords = '';
  RecitationResult? _result;
  /// نتيجة مباشرة أثناء الاستماع (من النتائج الجزئية)
  RecitationResult? _liveResult;
  String? _message;

  AyahData get _ayah => widget.surah.ayat[_index];
  int get _count => widget.surah.ayat.length;

  @override
  void initState() {
    super.initState();
    _index = widget.startIndex;
    _playerSub = _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playing = s == PlayerState.playing);
    });
    StorageService.instance.saveLastPosition(widget.surah.number, _ayah.number);
  }

  @override
  void dispose() {
    _speech.onStatus = null;
    _speech.onError = null;
    _speech.cancel();
    _playerSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  // ───────────────────────── التسجيل والتعرف ─────────────────────────

  Future<void> _toggleMic() async {
    if (_listening) {
      await _speech.stop();
      return;
    }
    await _player.stop();

    setState(() {
      _message = null;
      _result = null;
      _liveResult = null;
      _lastWords = '';
    });

    final init = await _speech.init();
    if (!mounted) return;
    switch (init) {
      case SpeechInit.noPermission:
        setState(() => _message =
            'لم يُمنح إذن الميكروفون. فعّله من إعدادات الجهاز ← التطبيقات ← هذا التطبيق ← الأذونات.');
        return;
      case SpeechInit.unavailable:
        setState(() => _message =
            'خدمة التعرف على الكلام غير متوفرة على جهازك. على أندرويد ثبّت/فعّل تطبيق Google وحدّثه.');
        return;
      case SpeechInit.noArabic:
        setState(() => _message =
            'لغة التعرف العربية غير مفعّلة على جهازك. أضفها من إعدادات لوحة المفاتيح/الإدخال الصوتي.');
        return;
      case SpeechInit.ready:
        break;
    }

    _speech.onStatus = (status) {
      if (!mounted || !_listening) return;
      if (status == 'done' || status == 'notListening') {
        Future<void>.delayed(const Duration(milliseconds: 350), () {
          if (mounted) _finish();
        });
      }
    };
    _speech.onError = (msg) {
      if (!mounted) return;
      if (msg == 'error_no_match' || msg == 'error_speech_timeout') {
        _finish(silentNothingHeard: true);
      } else {
        setState(() {
          _listening = false;
          _finished = true;
          _liveResult = null;
          _message = 'تعذّر التعرف على الصوت ($msg). تحقق من الاتصال والميكروفون ثم أعد المحاولة.';
        });
      }
    };

    setState(() {
      _listening = true;
      _finished = false;
    });
    try {
      await _speech.start(onWords: (words, isFinal) {
        if (!mounted) return;
        _lastWords = words;
        // مقارنة فورية مع النتائج الجزئية
        if (words.trim().isNotEmpty) {
          final live = RecitationChecker.compare(_ayah.simple, words);
          setState(() => _liveResult = live);
        } else {
          setState(() => _liveResult = null);
        }
        if (isFinal) _finish();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _listening = false;
        _finished = true;
        _message = 'تعذّر بدء التسجيل.';
      });
    }
  }

  void _finish({bool silentNothingHeard = false}) {
    if (_finished) return;
    _finished = true;
    final heard = _lastWords;
    final result = RecitationChecker.compare(_ayah.simple, heard);
    setState(() {
      _listening = false;
      _liveResult = null;
      if (result.nothingHeard || (silentNothingHeard && heard.trim().isEmpty)) {
        _result = null;
        _message = 'لم أسمع قراءة واضحة. قرّب الجهاز منك وتحدّث بصوت واضح، ثم أعد المحاولة.';
      } else {
        _result = result;
        StorageService.instance.saveAyahScore(widget.surah.number, _ayah.number, result.score);
      }
    });
  }

  // ───────────────────────── الاستماع للقارئ ─────────────────────────

  Future<void> _toggleReference() async {
    if (_playing) {
      await _player.stop();
      return;
    }
    if (_listening) await _speech.cancel();
    setState(() {
      _loadingAudio = true;
      _message = null;
    });
    try {
      final s = widget.surah.number;
      final a = _ayah.number;
      final downloaded = await QuranService.isAudioDownloaded(s, a);
      if (!downloaded && !await ConnectivityService.isOnline()) {
        if (!mounted) return;
        setState(() {
          _loadingAudio = false;
          _message = 'لا يوجد اتصال، والتلاوة غير محمّلة لهذه الآية.';
        });
        return;
      }
      await _player.play(await QuranService.audioSource(s, a));
      if (!mounted) return;
      setState(() => _loadingAudio = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingAudio = false;
        _message = 'تعذّر تشغيل التلاوة.';
      });
    }
  }

  // ───────────────────────── التنقل ─────────────────────────

  bool get _canAdvanceFreely {
    if (!_masteryMode) return true;
    final best = StorageService.instance.ayahBestScore(widget.surah.number, _ayah.number);
    if (best != null && best >= _masteryThreshold) return true;
    if (_result != null && _result!.score >= _masteryThreshold) return true;
    return false;
  }

  Future<void> _go(int delta) async {
    final next = _index + delta;
    if (next < 0 || next >= _count) return;

    // عند الانتقال للتالية في وضع الإتقان دون إتقان: تأكيد
    if (delta > 0 && _masteryMode && !_canAdvanceFreely) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('لم تُتقن الآية بعد'),
          content: Text(
            'وضع الإتقان مفعّل. يُفضَّل إعادة القراءة حتى تصل إلى ${(_masteryThreshold * 100).round()}% على الأقل.\n\nهل تريد الانتقال رغم ذلك؟',
            style: const TextStyle(height: 1.6),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('البقاء')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('انتقال')),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }

    await _player.stop();
    await _speech.cancel();
    setState(() {
      _index = next;
      _result = null;
      _liveResult = null;
      _message = null;
      _lastWords = '';
      _listening = false;
      _finished = true;
    });
    StorageService.instance.saveLastPosition(widget.surah.number, _ayah.number);
  }

  // ───────────────────────── الواجهة ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textHidden = _hideText && _result == null && !_listening;

    return Scaffold(
      appBar: AppBar(
        title: Text('سورة ${surahName(widget.surah.number)} - آية ${arabicDigits(_ayah.number)}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: (_index + 1) / _count),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ayahCard(textHidden),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _hideText,
                    onChanged: (v) => setState(() => _hideText = v),
                    title: const Text('وضع التسميع من الحفظ'),
                    subtitle: const Text('يُخفى نص الآية حتى تنتهي من قراءتها'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _masteryMode,
                    onChanged: (v) => setState(() => _masteryMode = v),
                    title: const Text('وضع الإتقان'),
                    subtitle: Text(
                      'يطلب إعادة المحاولة قبل الانتقال إن كانت النتيجة أقل من ${(_masteryThreshold * 100).round()}%',
                    ),
                  ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _loadingAudio ? null : _toggleReference,
                        icon: _loadingAudio
                            ? const SizedBox(
                                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : Icon(_playing ? Icons.stop : Icons.volume_up),
                        label: Text(_playing ? 'إيقاف' : 'استمع للقارئ أولاً'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _micArea(scheme),
                  // تنبيه فوري أثناء الاستماع
                  if (_listening && _liveResult != null && !_liveResult!.nothingHeard)
                    _liveFeedback(_liveResult!),
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.error, height: 1.7),
                      ),
                    ),
                  if (_result != null) _resultArea(_result!),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _index > 0 ? () => _go(-1) : null,
                      icon: const Icon(Icons.chevron_right),
                      label: const Text('السابقة'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _index < _count - 1 ? () => _go(1) : null,
                      icon: Icon(
                        _masteryMode && !_canAdvanceFreely
                            ? Icons.lock_open
                            : Icons.chevron_left,
                      ),
                      label: Text(
                        _masteryMode && !_canAdvanceFreely ? 'التالية (تجاوز)' : 'التالية',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ayahCard(bool hidden) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9C79A)),
      ),
      child: hidden
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.visibility_off, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('النص مخفي، اقرأ الآية من حفظك ثم اضغط الميكروفون',
                      textAlign: TextAlign.center, style: TextStyle(height: 1.7)),
                ],
              ),
            )
          : Text(
              _ayah.text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: quranFontFamily, fontSize: 28, height: 2.1, color: Color(0xFF0B3D2E)),
            ),
    );
  }

  Widget _micArea(ColorScheme scheme) {
    final live = _lastWords.trim();
    return Column(
      children: [
        GestureDetector(
          onTap: _toggleMic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _listening ? Colors.red.shade600 : scheme.primary,
              boxShadow: [
                BoxShadow(
                  color: (_listening ? Colors.red : scheme.primary).withAlpha(90),
                  blurRadius: _listening ? 24 : 10,
                  spreadRadius: _listening ? 6 : 1,
                ),
              ],
            ),
            child: Icon(_listening ? Icons.stop : Icons.mic, color: Colors.white, size: 40),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _listening
              ? 'جارٍ الاستماع... اقرأ الآية ثم اضغط للإنهاء'
              : (_result == null ? 'اضغط وابدأ القراءة' : 'اضغط لإعادة المحاولة'),
          style: const TextStyle(fontSize: 15),
        ),
        if (_listening && live.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              live,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, height: 1.8, color: scheme.outline),
            ),
          ),
      ],
    );
  }

  /// تغذية راجعة فورية أثناء القراءة
  Widget _liveFeedback(RecitationResult r) {
    final pct = (r.score * 100).round();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        color: const Color(0xFFF0F7F4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.hearing, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'متابعة مباشرة · $pct%',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 8,
                children: [for (final w in r.words) _wordChip(w, compact: true)],
              ),
              if (r.wrong > 0 || r.missing > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    [
                      if (r.wrong > 0) '${r.wrong} خاطئة',
                      if (r.missing > 0) '${r.missing} متروكة',
                      if (r.extras.isNotEmpty) '${r.extras.length} زائدة',
                    ].join(' · '),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.red.shade800),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static const _okBg = Color(0xFFD7F0DD);
  static const _nearBg = Color(0xFFFFF1C2);
  static const _wrongBg = Color(0xFFF8D7D7);

  Widget _resultArea(RecitationResult r) {
    final pct = (r.score * 100).round();
    final headline = r.isPerfect
        ? 'ما شاء الله! قراءة صحيحة'
        : pct >= 80
            ? 'قراءة جيدة، راجع الكلمات الملوّنة'
            : 'حاول مرة أخرى بعد الاستماع للقارئ';

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('$pct%',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary)),
              Text(headline, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              if (_masteryMode && r.score < _masteryThreshold)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'وضع الإتقان: أعد المحاولة للوصول إلى ${(_masteryThreshold * 100).round()}% قبل الانتقال',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.orange.shade900, height: 1.5),
                  ),
                ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 8,
                children: [for (final w in r.words) _wordChip(w)],
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 4,
                children: [
                  _legend(_okBg, 'صحيحة ${r.correct}'),
                  _legend(_nearBg, 'قريبة ${r.near}'),
                  _legend(_wrongBg, 'خاطئة ${r.wrong}'),
                  _legend(Colors.white, 'متروكة ${r.missing}', border: Colors.red.shade400),
                  if (r.extras.isNotEmpty) _legend(Colors.grey.shade300, 'زائدة ${r.extras.length}'),
                ],
              ),
              ..._details(r),
              const Divider(height: 24),
              const Text(
                'يتحقق التصحيح من الكلمات المنطوقة فقط (مجاني وعلى الجهاز). أحكام التجويد (المدود، الغنة، الإخفاء، المخارج الدقيقة) لا يكشفها التعرف الصوتي العام، فراجعها مع مقرئ.',
                style: TextStyle(fontSize: 12.5, height: 1.7, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wordChip(WordResult w, {bool compact = false}) {
    Color bg;
    Color? border;
    TextDecoration? deco;
    switch (w.status) {
      case WordStatus.correct:
        bg = _okBg;
      case WordStatus.near:
        bg = _nearBg;
      case WordStatus.wrong:
        bg = _wrongBg;
      case WordStatus.missing:
        bg = Colors.white;
        border = Colors.red.shade400;
        deco = TextDecoration.underline;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 3 : 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: border == null ? null : Border.all(color: border, width: 1.5),
      ),
      child: Text(
        w.display,
        style: TextStyle(fontFamily: quranFontFamily, fontSize: compact ? 18 : 22, height: 1.8, decoration: deco),
      ),
    );
  }

  Widget _legend(Color c, String label, {Color? border}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border ?? Colors.black26),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  List<Widget> _details(RecitationResult r) {
    final lines = <String>[];
    for (final w in r.words) {
      if (w.status == WordStatus.wrong) {
        lines.add('نُطقت «${w.heard}» بدل «${w.display}»');
      } else if (w.status == WordStatus.missing) {
        lines.add('تركتَ كلمة «${w.display}»');
      } else if (w.status == WordStatus.near) {
        lines.add('«${w.display}» قريبة: سُمعت «${w.heard}»، أعد نطقها بوضوح');
      }
    }
    if (r.extras.isNotEmpty) {
      lines.add('كلمات زائدة: ${r.extras.join('، ')}');
    }
    if (lines.isEmpty) return const [];
    return [
      const SizedBox(height: 12),
      const Text('ملاحظات', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      for (final l in lines)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('• $l', style: const TextStyle(height: 1.6)),
        ),
    ];
  }
}
