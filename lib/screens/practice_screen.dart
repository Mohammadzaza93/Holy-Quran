import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../data/surahs.dart';
import '../services/connectivity_service.dart';
import '../services/mushaf_service.dart';
import '../services/quran_service.dart';
import '../services/lahn_jali.dart';
import '../services/recitation_checker.dart';
import '../services/speech_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../theme/quran_font.dart';
import '../widgets/recitation_error_sheet.dart';

/// شاشة التسميع مع تتبع حي كلمة بكلمة + قائمة مساعدة عند الخطأ.
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key, required this.surah, required this.startIndex});

  final SurahData surah;
  final int startIndex;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late int _index;
  final _speech = SpeechService.instance;
  final _player = AudioPlayer();
  StreamSubscription<void>? _playerSub;

  bool _listening = false;
  bool _finished = true;
  bool _playing = false;
  bool _loadingAudio = false;
  bool _hideText = false;
  bool _masteryMode = true;
  static const double _masteryThreshold = 0.8;

  RecitationResult? _result;
  LiveTrackResult? _liveTrack;
  String? _message;
  String _lastWords = '';

  AyahData get _ayah => widget.surah.ayat[_index];
  String get _displayAyahText =>
      _ayah.text.trim().isNotEmpty ? _ayah.text : _ayah.simple;

  @override
  void initState() {
    super.initState();
    _index = widget.startIndex.clamp(0, widget.surah.ayat.length - 1);
    StorageService.instance.saveLastPosition(widget.surah.number, _ayah.number);
    _playerSub = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
    _speech.onStatus = null;
    _speech.onError = null;
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

  Future<void> _openErrorSheet({WordResult? focusWord}) {
    return showRecitationErrorSheet(
      context: context,
      surahNumber: widget.surah.number,
      ayahNumber: _ayah.number,
      surahAyat: widget.surah.ayat,
      focusWord: focusWord,
      onListen: () {
        if (!_playing) _toggleReference();
      },
      onRetryMic: () {
        if (!_listening) _toggleMic();
      },
    );
  }

  Future<void> _toggleMic() async {
    if (_listening) {
      await _speech.stop();
      return;
    }
    await _player.stop();

    setState(() {
      _message = null;
      _result = null;
      _liveTrack = null;
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
      } else if (msg.contains('language')) {
        setState(() {
          _listening = false;
          _finished = true;
          _liveTrack = null;
          _message = 'لغة التعرف العربية غير متاحة على جهازك. جرّب بالترتيب: '
              '١) من الإعدادات ← «التعرف على الجهاز» أطفئه ليعمل عبر الإنترنت. '
              '٢) افتح تطبيق Google ← الإعدادات ← الصوت ← اللغات، وأضف «العربية». '
              '٣) حدّث تطبيق Google و«خدمات الكلام من Google» من متجر Play.';
        });
      } else {
        setState(() {
          _listening = false;
          _finished = true;
          _liveTrack = null;
          _message =
              'تعذّر التعرف على الصوت ($msg). تحقق من الاتصال والميكروفون ثم أعد المحاولة.';
        });
      }
    };

    setState(() {
      _listening = true;
      _finished = false;
      _liveTrack = RecitationChecker.trackLive(_displayAyahText, '');
    });

    try {
      await _speech.start(onWords: (words, isFinal) {
        if (!mounted) return;
        _lastWords = words;
        final track = RecitationChecker.trackLive(_displayAyahText, words);
        setState(() => _liveTrack = track);
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
    final result = RecitationChecker.compare(_displayAyahText, heard);
    setState(() {
      _listening = false;
      _liveTrack = null;
      if (result.nothingHeard || (silentNothingHeard && heard.trim().isEmpty)) {
        _result = null;
        _message =
            'لم أسمع قراءة واضحة. قرّب الجهاز منك وتحدّث بصوت واضح، ثم أعد المحاولة.';
      } else {
        _result = result;
        StorageService.instance
            .saveAyahScore(widget.surah.number, _ayah.number, result.score);
      }
    });
  }

  Future<void> _toggleReference() async {
    if (_playing) {
      await _player.stop();
      setState(() => _playing = false);
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
      final src = await QuranService.audioSource(s, a);
      await _player.play(src);
      if (!mounted) return;
      setState(() {
        _loadingAudio = false;
        _playing = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingAudio = false;
        _message = 'تعذّر تشغيل التلاوة.';
      });
    }
  }

  bool get _canGoNext {
    if (!_masteryMode) return true;
    if (_result != null && _result!.score >= _masteryThreshold) return true;
    final best =
        StorageService.instance.ayahBestScore(widget.surah.number, _ayah.number);
    return best != null && best >= _masteryThreshold;
  }

  void _go(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= widget.surah.ayat.length) return;
    if (delta > 0 && !_canGoNext) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'وضع الإتقان: صل إلى ${(_masteryThreshold * 100).round()}% على هذه الآية قبل الانتقال',
          ),
        ),
      );
      return;
    }
    _speech.cancel();
    _player.stop();
    setState(() {
      _index = next;
      _result = null;
      _liveTrack = null;
      _message = null;
      _lastWords = '';
      _listening = false;
      _finished = true;
      _playing = false;
    });
    StorageService.instance.saveLastPosition(widget.surah.number, _ayah.number);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textHidden = _hideText && _result == null && !_listening;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'سورة ${surahName(widget.surah.number)} · آية ${_ayah.number}',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ayahCard(textHidden),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('وضع التسميع من الحفظ'),
                      subtitle: const Text('يُخفى نص الآية حتى تبدأ القراءة أو تنتهي'),
                      value: _hideText,
                      onChanged: (v) => setState(() => _hideText = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('وضع الإتقان'),
                      subtitle: Text(
                        'يمنع الانتقال للسهل إن كانت النتيجة أقل من ${(_masteryThreshold * 100).round()}%',
                      ),
                      value: _masteryMode,
                      onChanged: (v) => setState(() => _masteryMode = v),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _loadingAudio ? null : _toggleReference,
                      icon: Icon(_playing ? Icons.stop : Icons.volume_up),
                      label: Text(_playing ? 'إيقاف' : 'استمع للقارئ أولاً'),
                    ),
                    const SizedBox(height: 20),
                    _micArea(scheme),
                    if (_message != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(
                          _message!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red.shade800, height: 1.6),
                        ),
                      ),
                    if (_result != null) _resultArea(_result!),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _index > 0 ? () => _go(-1) : null,
                      child: const Text('السابقة'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _index < widget.surah.ayat.length - 1 ? () => _go(1) : null,
                      child: Text(_canGoNext ? 'التالية' : 'التالية (تجاوز)'),
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

  Widget _ayahCard(bool textHidden) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: textHidden
            ? const Column(
                children: [
                  Icon(Icons.visibility_off, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'النص مخفي — اقرأ من حفظك ثم اضغط الميكروفون',
                    textAlign: TextAlign.center,
                    style: TextStyle(height: 1.7),
                  ),
                ],
              )
            : _buildAyahWords(),
      ),
    );
  }

  Widget _buildAyahWords() {
    final List<WordResult>? liveWords =
        _listening && _liveTrack != null ? _liveTrack!.words : null;
    final List<WordResult>? finalWords = _result?.words;

    if (liveWords != null || finalWords != null) {
      final words = liveWords ?? finalWords!;
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 10,
        children: [
          for (final w in words) _trackedWord(w, live: liveWords != null),
        ],
      );
    }

    return Text(
      _displayAyahText,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: quranFontFamily,
        fontSize: 28,
        height: 2.1,
        color: Color(0xFF0B3D2E),
      ),
    );
  }

  Widget _trackedWord(WordResult w, {required bool live}) {
    Color bg;
    Color fg = const Color(0xFF0B3D2E);
    Border? border;
    List<BoxShadow>? shadow;

    switch (w.status) {
      case WordStatus.correct:
        bg = const Color(0xFFD7F0DD);
      case WordStatus.near:
        bg = const Color(0xFFFFF1C2);
      case WordStatus.wrong:
        bg = const Color(0xFFF8D7D7);
      case WordStatus.missing:
        bg = Colors.white;
        border = Border.all(color: Colors.red.shade400, width: 1.5);
      case WordStatus.current:
        bg = const Color(0xFFDCEBFF);
        border = Border.all(color: const Color(0xFF1E5F8A), width: 2);
        shadow = [
          BoxShadow(
            color: const Color(0xFF1E5F8A).withOpacity(0.25),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ];
      case WordStatus.pending:
        bg = Colors.transparent;
        fg = const Color(0xFF0B3D2E).withOpacity(0.55);
    }

    final tappable = !live &&
        (w.status == WordStatus.wrong ||
            w.status == WordStatus.missing ||
            w.status == WordStatus.near);

    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: border,
        boxShadow: shadow,
      ),
      child: Text(
        w.display,
        style: TextStyle(
          fontFamily: quranFontFamily,
          fontSize: 26,
          height: 1.7,
          color: fg,
          fontWeight: w.status == WordStatus.current ? FontWeight.w700 : FontWeight.w400,
          decoration:
              w.status == WordStatus.missing ? TextDecoration.underline : null,
          decorationColor: Colors.red.shade400,
        ),
      ),
    );

    if (!tappable) return chip;
    return GestureDetector(
      onTap: () => _openErrorSheet(focusWord: w),
      child: chip,
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
              ? 'جارٍ التتبع الحي… اقرأ بوضوح ثم اضغط للإيقاف'
              : (_result == null ? 'اضغط وابدأ القراءة' : 'اضغط لإعادة المحاولة'),
          style: const TextStyle(fontSize: 15),
        ),
        if (_listening && live.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              live,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.7, color: scheme.outline),
            ),
          ),
      ],
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
              Text(
                '$pct%',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
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
                spacing: 12,
                runSpacing: 4,
                children: [
                  _legend(_okBg, 'صحيحة ${r.correct}'),
                  _legend(_nearBg, 'قريبة ${r.near}'),
                  _legend(_wrongBg, 'خاطئة ${r.wrong}'),
                  _legend(Colors.white, 'متروكة ${r.missing}', border: Colors.red.shade400),
                  if (r.extras.isNotEmpty)
                    _legend(Colors.grey.shade300, 'زائدة ${r.extras.length}'),
                ],
              ),
              if (!r.isPerfect) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _openErrorSheet(),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('خيارات المساعدة عند الخطأ'),
                ),
              ],
              const Divider(height: 24),
              const Text(
                'اضغط كلمة حمراء/صفراء لفتح: استمع · ترجمة · تفسير · إشارة · متشابهات.',
                style: TextStyle(fontSize: 12.5, height: 1.7, color: Colors.black54),
              ),
            ],
          ),
        ),
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
            border: border != null ? Border.all(color: border) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12.5)),
      ],
    );
  }

  void _showLahnInfo() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اللحن الجلي'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(LahnJali.definition, style: TextStyle(height: 1.7)),
              const SizedBox(height: 10),
              for (final f in LahnJali.forms)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $f', style: const TextStyle(height: 1.7)),
                ),
              const SizedBox(height: 6),
              const Text(LahnJali.limit,
                  style: TextStyle(fontSize: 13, height: 1.7, color: Colors.black54)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً')),
        ],
      ),
    );
  }
}
