import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// ترجمة وتفسير محفوظان محلياً للعمل دون إنترنت بعد التحميل.
///
/// - التفسير: ar.muyassar (التفسير الميسّر)
/// - الترجمة: en.sahih (معنى إنجليزي واضح وشائع)
class AyahTextService {
  AyahTextService._();

  static const tafsirEdition = 'ar.muyassar';
  static const translationEdition = 'en.sahih';

  static const _api = 'https://api.alquran.cloud/v1/surah';

  static Future<Directory> _root() async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/quran_texts');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static Future<File> _file(String edition, int surah) async {
    final dir = Directory('${(await _root()).path}/$edition');
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}/$surah.json');
  }

  /// خريطة رقم الآية → النص من التخزين المحلي.
  static Future<Map<int, String>?> loadSurahLocal(String edition, int surah) async {
    try {
      final f = await _file(edition, surah);
      if (!await f.exists()) return null;
      final data = jsonDecode(await f.readAsString());
      if (data is! Map) return null;
      final out = <int, String>{};
      data.forEach((k, v) {
        final n = int.tryParse(k.toString());
        if (n != null && v is String && v.trim().isNotEmpty) out[n] = v;
      });
      return out.isEmpty ? null : out;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveSurah(String edition, int surah, Map<int, String> map) async {
    final f = await _file(edition, surah);
    await f.writeAsString(
      jsonEncode({for (final e in map.entries) '${e.key}': e.value}),
    );
  }

  /// يجلب السورة كاملة من الشبكة ويحفظها.
  static Future<Map<int, String>?> fetchAndCacheSurah(String edition, int surah) async {
    try {
      final r = await http
          .get(Uri.parse('$_api/$surah/$edition'))
          .timeout(const Duration(seconds: 25));
      if (r.statusCode != 200) return null;
      final json = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      final ayahs = (json['data'] as Map<String, dynamic>)['ayahs'] as List;
      final map = <int, String>{};
      for (final a in ayahs) {
        final m = a as Map<String, dynamic>;
        final n = (m['numberInSurah'] as num).toInt();
        final text = (m['text'] as String?)?.trim() ?? '';
        if (text.isNotEmpty) map[n] = text;
      }
      if (map.isEmpty) return null;
      await _saveSurah(edition, surah, map);
      return map;
    } catch (_) {
      return null;
    }
  }

  /// نص آية: محلي أولاً، ثم شبكة مع حفظ، وإلا null.
  static Future<String?> getAyahText({
    required String edition,
    required int surah,
    required int ayah,
    bool allowNetwork = true,
  }) async {
    final local = await loadSurahLocal(edition, surah);
    if (local != null && local[ayah] != null) return local[ayah];

    if (!allowNetwork) return null;

    final remote = await fetchAndCacheSurah(edition, surah);
    return remote?[ayah];
  }

  static Future<String?> getTafsir(int surah, int ayah, {bool allowNetwork = true}) =>
      getAyahText(
        edition: tafsirEdition,
        surah: surah,
        ayah: ayah,
        allowNetwork: allowNetwork,
      );

  static Future<String?> getTranslation(int surah, int ayah, {bool allowNetwork = true}) =>
      getAyahText(
        edition: translationEdition,
        surah: surah,
        ayah: ayah,
        allowNetwork: allowNetwork,
      );

  /// تحميل التفسير + الترجمة لكل السور (للعمل دون اتصال).
  /// يعيد عدد السور التي اكتمل لها النوعان.
  static Future<int> downloadAll({
    void Function(int done, int total)? onProgress,
  }) async {
    var ok = 0;
    const total = 114 * 2;
    var step = 0;
    for (var n = 1; n <= 114; n++) {
      final t = await fetchAndCacheSurah(tafsirEdition, n);
      step++;
      onProgress?.call(step, total);
      final tr = await fetchAndCacheSurah(translationEdition, n);
      step++;
      onProgress?.call(step, total);
      if (t != null && tr != null) ok++;
    }
    return ok;
  }

  /// هل التفسير والترجمة محفوظان لسورة؟
  static Future<bool> isSurahReady(int surah) async {
    final t = await loadSurahLocal(tafsirEdition, surah);
    final tr = await loadSurahLocal(translationEdition, surah);
    return t != null && tr != null;
  }

  static Future<int> readySurahCount() async {
    var n = 0;
    for (var s = 1; s <= 114; s++) {
      if (await isSurahReady(s)) n++;
    }
    return n;
  }
}
