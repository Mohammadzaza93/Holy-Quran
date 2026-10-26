import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'storage_service.dart';

enum SpeechInit { ready, noPermission, unavailable, noArabic }

/// غلاف بسيط حول حزمة speech_to_text (محرك التعرف الصوتي الموجود في نظام الجهاز).
///
/// ملاحظة: جودة التعرف على العربية تعتمد على محرك الجهاز (Google على أندرويد، Apple على iOS)،
/// وهو غالباً يحتاج إنترنت إلا إذا فعّلت «التعرف على الجهاز» وكانت حزمة العربية محمّلة.
class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  final SpeechToText _stt = SpeechToText();
  bool _initialized = false;
  String? _localeId;

  /// يستدعيهما الشاشة الحالية لتعرف حالة المحرك
  void Function(String status)? onStatus;
  void Function(String message)? onError;

  bool get isListening => _stt.isListening;

  Future<SpeechInit> init() async {
    if (!_initialized) {
      final ok = await _stt.initialize(
        onStatus: (s) => onStatus?.call(s),
        onError: (SpeechRecognitionError e) => onError?.call(e.errorMsg),
        debugLogging: false,
      );
      if (!ok) {
        // الفشل إما لرفض إذن الميكروفون أو لعدم وجود خدمة تعرف على الجهاز
        return await _stt.hasPermission ? SpeechInit.unavailable : SpeechInit.noPermission;
      }
      _initialized = true;
    }
    _localeId ??= await _pickArabicLocale();
    return _localeId == null ? SpeechInit.noArabic : SpeechInit.ready;
  }

  Future<String?> _pickArabicLocale() async {
    final locales = await _stt.locales();
    final arabic = locales.where((l) => l.localeId.toLowerCase().startsWith('ar')).toList();
    if (arabic.isEmpty) return null;
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
      localeId: _localeId,
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
