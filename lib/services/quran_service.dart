import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/question.dart';
import 'storage_service.dart';

/// القراء المتاحون (جميعهم يقرؤون برواية حفص عن عاصم).
/// القيمة هي اسم المجلد في موقع everyayah.com
const Map<String, String> reciters = {
  'Alafasy_128kbps': 'مشاري العفاسي',
  'Husary_128kbps': 'محمود خليل الحصري',
  'Minshawy_Murattal_128kbps': 'محمد صديق المنشاوي (مرتل)',
  'Abdul_Basit_Murattal_192kbps': 'عبد الباسط عبد الصمد (مرتل)',
  'Abdurrahmaan_As-Sudais_192kbps': 'عبد الرحمن السديس',
};

/// يتعامل مع نص الآية (من الإنترنت مع تخزين محلي) وصوتها (بث أو ملف محمّل).
class QuranService {
  static const _textApi = 'https://api.alquran.cloud/v1/ayah';
  static const _audioBase = 'https://everyayah.com/data';

  // ───────── نص الآية ─────────

  /// يعيد نص الآية بالرسم العثماني من التخزين المحلي، وإلا من الإنترنت.
  /// يعيد null إذا لم يتوفر لا هذا ولا ذاك.
  static Future<String?> getAyahText(int surah, int ayah) async {
    final store = StorageService.instance;
    final cached = store.cachedAyah(surah, ayah);
    if (cached != null) return cached;
    try {
      final r = await http
          .get(Uri.parse('$_textApi/$surah:$ayah/quran-uthmani'))
          .timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) return null;
      final json = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      final text = (json['data'] as Map<String, dynamic>)['text'] as String?;
      if (text == null || text.isEmpty) return null;
      await store.cacheAyah(surah, ayah, text);
      return text;
    } catch (_) {
      return null;
    }
  }

  // ───────── صوت الآية ─────────

  static String _fileName(int surah, int ayah) =>
      '${surah.toString().padLeft(3, '0')}${ayah.toString().padLeft(3, '0')}.mp3';

  static Future<File> _localFile(String reciter, int surah, int ayah) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/audio/$reciter');
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}/${_fileName(surah, ayah)}');
  }

  static Future<bool> isAudioDownloaded(int surah, int ayah) async {
    final f = await _localFile(StorageService.instance.reciter, surah, ayah);
    return f.exists();
  }

  /// يعيد مصدر الصوت: الملف المحمّل إن وُجد، وإلا رابط البث.
  static Future<Source> audioSource(int surah, int ayah) async {
    final reciter = StorageService.instance.reciter;
    final f = await _localFile(reciter, surah, ayah);
    if (await f.exists()) return DeviceFileSource(f.path);
    return UrlSource('$_audioBase/$reciter/${_fileName(surah, ayah)}');
  }

  static Future<bool> downloadAudio(int surah, int ayah) async {
    final reciter = StorageService.instance.reciter;
    final f = await _localFile(reciter, surah, ayah);
    if (await f.exists()) return true;
    try {
      final r = await http
          .get(Uri.parse('$_audioBase/$reciter/${_fileName(surah, ayah)}'))
          .timeout(const Duration(seconds: 30));
      if (r.statusCode != 200 || r.bodyBytes.isEmpty) return false;
      await f.writeAsBytes(r.bodyBytes, flush: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// يحمّل نصوص وصوتيات كل الآيات المرتبطة بالأسئلة ليعمل كل شيء دون اتصال.
  /// يعيد عدد الآيات التي نجح تحميلها كاملة.
  static Future<({int done, int total})> downloadAllForOffline(
    List<Question> questions, {
    void Function(int done, int total)? onProgress,
  }) async {
    final refs = <String, (int, int)>{};
    for (final q in questions) {
      if (q.hasAyahRef) refs['${q.surah}:${q.ayah}'] = (q.surah!, q.ayah!);
    }
    final total = refs.length;
    var done = 0;
    var ok = 0;
    for (final (s, a) in refs.values) {
      final text = await getAyahText(s, a);
      final audio = await downloadAudio(s, a);
      if (text != null && audio) ok++;
      done++;
      onProgress?.call(done, total);
    }
    return (done: ok, total: total);
  }

  /// حجم الملفات الصوتية المحمّلة بالميغابايت
  static Future<double> downloadedAudioSizeMb() async {
    try {
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory('${base.path}/audio');
      if (!await dir.exists()) return 0;
      var bytes = 0;
      await for (final e in dir.list(recursive: true)) {
        if (e is File) bytes += await e.length();
      }
      return bytes / (1024 * 1024);
    } catch (_) {
      return 0;
    }
  }

  static Future<void> deleteDownloadedAudio() async {
    try {
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory('${base.path}/audio');
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }
}
