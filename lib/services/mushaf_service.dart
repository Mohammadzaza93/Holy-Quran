import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'recitation_checker.dart';

class AyahData {
  const AyahData({required this.number, required this.text, required this.simple});

  final int number;
  final String text;
  final String simple;

  Map<String, dynamic> toJson() => {'n': number, 't': text, 's': simple};
}

class SurahData {
  const SurahData({required this.number, required this.ayat});
  final int number;
  final List<AyahData> ayat;
}

/// نتيجة بحث في نص الآيات المحفوظة محلياً.
class AyahSearchHit {
  const AyahSearchHit({
    required this.surah,
    required this.ayah,
    required this.text,
  });

  final int surah;
  final int ayah;
  final String text;
}

/// تحميل نص السور وحفظه محلياً + بحث بالكلمات.
class MushafService {
  static const _api = 'https://api.alquran.cloud/v1/surah';
  static const _basmala = 'بسم الله الرحمن الرحيم';

  static Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/quran');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static Future<File> _file(int surah) async =>
      File('${(await _dir()).path}/$surah.json');

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

  static Future<SurahData?> getSurah(int number) async {
    final f = await _file(number);
    if (await f.exists()) {
      final local = _parseLocal(number, await f.readAsString());
      if (local != null) return local;
    }
    final remote = await _fetch(number);
    if (remote == null) return null;
    try {
      await f.writeAsString(
          jsonEncode({'a': remote.ayat.map((a) => a.toJson()).toList()}));
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

  /// بحث في الآيات المحفوظة على الجهاز (اسم/رقم السورة يُعالَج في الواجهة).
  /// [query] يُطبَّع عبر [ArabicText.normalize] (إزالة التشكيل وتوحيد الحروف).
  static Future<List<AyahSearchHit>> searchAyat(
    String query, {
    int limit = 40,
  }) async {
    final needle = ArabicText.normalize(query);
    if (needle.length < 2) return const [];

    final cached = await cachedSurahs();
    if (cached.isEmpty) return const [];

    final hits = <AyahSearchHit>[];
    final sorted = cached.toList()..sort();

    for (final n in sorted) {
      if (hits.length >= limit) break;
      final f = await _file(n);
      if (!await f.exists()) continue;
      final surah = _parseLocal(n, await f.readAsString());
      if (surah == null) continue;

      for (final a in surah.ayat) {
        if (hits.length >= limit) break;
        final hay = ArabicText.normalize(a.simple.isNotEmpty ? a.simple : a.text);
        if (hay.contains(needle)) {
          hits.add(AyahSearchHit(surah: n, ayah: a.number, text: a.text));
        }
      }
    }
    return hits;
  }

  static Future<List<Map<String, dynamic>>?> _fetchEdition(
      int number, String edition) async {
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
      ayat.add(AyahData(
        number: (uth[i]['numberInSurah'] as num).toInt(),
        text: t,
        simple: s,
      ));
    }
    return SurahData(number: number, ayat: ayat);
  }

  static Future<int> downloadAllSurahs(
          {void Function(int done, int total)? onProgress}) =>
      downloadAll(onProgress: onProgress);

  static Future<int> downloadAll(
      {void Function(int done, int total)? onProgress}) async {
    var ok = 0;
    for (var n = 1; n <= 114; n++) {
      final s = await getSurah(n);
      if (s != null) ok++;
      onProgress?.call(n, 114);
    }
    return ok;
  }
}
