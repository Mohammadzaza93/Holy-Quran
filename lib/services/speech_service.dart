import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'storage_service.dart';

enum SpeechInit { ready, noPermission, unavailable, noArabic }

/// غلاف حول حزمة speech_to_text (محرك التعرف الصوتي في نظام الجهاز).
///
/// جودة العربية تعتمد على محرك الجهاز (Google / Apple).
/// كثير من الأجهزة لا تُرجع العربية في قائمة اللغات رغم أنها تعمل — نجرّب ar_SA دائماً.
class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  final SpeechToText _stt = SpeechToText();
  bool _initialized = false;
  String? _localeId;
  bool _localeAnnounced = false;

  void Function(String status)? onStatus;
  void Function(String message)? onError;

  bool get isListening => _stt.isListening;

  /// هل أعلن الجهاز وجود لغة عربية في قائمة locales؟
  bool get localeAnnounced => _localeAnnounced;

  Future<SpeechInit> init() async {
    if (!_initialized) {
      final ok = await _stt.initialize(
        onStatus: (s) => onStatus?.call(s),
        onError: (SpeechRecognitionError e) => onError?.call(e.errorMsg),
        debugLogging: false,
      );
      if (!ok) {
        final granted = await _stt.hasPermission;
        return granted ? SpeechInit.unavailable : SpeechInit.noPermission;
      }
      _initialized = true;
    }
    _localeId ??= await _pickArabicLocale();
    // لا نرجع noArabic هنا: أجهزة كثيرة (شاومي/هواوي) لا تُدرج العربية في locales
    // رغم أن التعرف يعمل عند تمرير ar_SA.
    return SpeechInit.ready;
  }

  Future<String> _pickArabicLocale() async {
    List<LocaleName> locales = const [];
    try {
      locales = await _stt.locales();
    } catch (_) {}
    final arabic =
        locales.where((l) => l.localeId.toLowerCase().startsWith('ar')).toList();
    if (arabic.isEmpty) {
      _localeAnnounced = false;
      return 'ar_SA';
    }
    _localeAnnounced = true;
    for (final l in arabic) {
      final id = l.localeId.toLowerCase().replaceAll('-', '_');
      if (id == 'ar_sa') return l.localeId;
    }
    return arabic.first.localeId;
  }

  /// يبدأ الاستماع. [onWords] تُستدعى بالنص الجزئي ثم النهائي.
  Future<void> start({required void Function(String words, bool isFinal) onWords}) async {
    await _stt.listen(
      onResult: (r) => onWords(r.recognizedWords, r.finalResult),
      // بعض إصدارات الحزمة ما زالت تتوقع هذه المعاملات على المستوى الأعلى
      localeId: _localeId ?? 'ar_SA',
      listenFor: const Duration(seconds: 90),
      pauseFor: const Duration(seconds: 5),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
        onDevice: StorageService.instance.onDeviceSpeech,
      ),
    );
  }

  Future<void> stop() => _stt.stop();
  Future<void> cancel() => _stt.cancel();
}
