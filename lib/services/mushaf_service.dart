import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'recitation_checker.dart';

class AyahData {
  const AyahData({required this.number, required this.text, required this.simple});

  /// رقم الآية في السورة
  final int number;

  /// النص بالرسم العثماني (للقراءة)
  final String text;

  /// النص بالرسم الإملائي المشكول (للمقارنة مع التعرف الصوتي وعرض النتيجة)
  final String simple;

  Map<String, dynamic> toJson() => {'n': number, 't': text, 's': simple};
}

class SurahData {
  const SurahData({required this.number, required this.ayat});
  final int number;
  final List<AyahData> ayat;
}

/// تحميل نص السور (رسم عثماني + إملائي) وحفظه محلياً ليعمل التطبيق دون اتصال.
/// المصدر: api.alquran.cloud (رواية حفص عن عاصم)
class MushafService {
  static const _api = 'https://api.alquran.cloud/v1/surah';
  static const _basmala = 'بسم الله الرحمن الرحيم';

  static Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/quran');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static Future<File> _file(int surah) async => File('${(await _dir()).path}/$surah.json');

  /// أرقام السور المحفوظة محلياً
  static Future<Set<int>> cachedSurahs() async {
    try {
      final d = await _dir();
      final out = <int>{};
      await for (final e in d.list()) {
        if (e is File && e.path.endsWith('.json')) {
          final name = e.uri.pathSegments.last.replaceAll('.json', '');
          final n = int.tryParse(name);
          if (n != null) out.add(n);
        }
      }
      return out;
    } catch (_) {
      return <int>{};
    }
  }

  /// يعيد السورة من التخزين المحلي، وإلا من الإنترنت (ثم يحفظها). null عند الفشل.
  static Future<SurahData?> getSurah(int number) async {
    final f = await _file(number);
    if (await f.exists()) {
      final local = _parseLocal(number, await f.readAsString());
      if (local != null) return local;
    }
    final remote = await _fetch(number);
    if (remote == null) return null;
    try {
      await f.writeAsString(jsonEncode({'a': remote.ayat.map((a) => a.toJson()).toList()}));
    } catch (_) {}
    return remote;
  }

  static SurahData? _parseLocal(int number, String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final list = (data['a'] as List)
          .map((e) => AyahData(
                number: e['n'] as int,
                text: e['t'] as String,
                simple: e['s'] as String,
              ))
          .toList();
      return list.isEmpty ? null : SurahData(number: number, ayat: list);
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> _fetchEdition(int number, String edition) async {
    try {
      final r = await http
          .get(Uri.parse('$_api/$number/$edition'))
          .timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) return null;
      final json = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      final ayahs = (json['data'] as Map<String, dynamic>)['ayahs'] as List;
      return ayahs.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  /// المصدر يضيف البسملة إلى بداية الآية الأولى في كل السور عدا الفاتحة والتوبة، فنحذفها.
  static String _stripBasmala(int surah, String text) {
    if (surah == 1 || surah == 9) return text;
    final tokens = text.trim().split(RegExp(r'\s+'));
    if (tokens.length <= 4) return text;
    final head = ArabicText.normalize(tokens.take(4).join(' '));
    if (head != _basmala) return text;
    return tokens.skip(4).join(' ');
  }

  static Future<SurahData?> _fetch(int number) async {
    final uth = await _fetchEdition(number, 'quran-uthmani');
    if (uth == null) return null;
    final simple = await _fetchEdition(number, 'quran-simple');
    if (simple == null || simple.length != uth.length) return null;

    final ayat = <AyahData>[];
    for (var i = 0; i < uth.length; i++) {
      var t = (uth[i]['text'] as String).trim();
      var s = (simple[i]['text'] as String).trim();
      if (i == 0) {
        t = _stripBasmala(number, t);
        s = _stripBasmala(number, s);
      }
      ayat.add(AyahData(number: (uth[i]['numberInSurah'] as num).toInt(), text: t, simple: s));
    }
    return SurahData(number: number, ayat: ayat);
  }

  /// يحمّل كل السور (114) للعمل دون اتصال. يعيد عدد السور الجاهزة.
  static Future<int> downloadAll({void Function(int done, int total)? onProgress}) async {
    var ok = 0;
    for (var n = 1; n <= 114; n++) {
      final s = await getSurah(n);
      if (s != null) ok++;
      onProgress?.call(n, 114);
    }
    return ok;
  }
}
