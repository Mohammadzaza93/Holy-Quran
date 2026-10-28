import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/mushaf_service.dart';
import '../services/recitation_checker.dart';
import '../services/storage_service.dart';

/// قائمة خيارات عند خطأ التلاوة — مشابهة لتطبيقات المصحف:
/// استمع · أعد التسميع · ترجمة · تفسير · إشارة · متشابهات.
Future<void> showRecitationErrorSheet({
  required BuildContext context,
  required int surahNumber,
  required int ayahNumber,
  required List<AyahData> surahAyat,
  WordResult? focusWord,
  required VoidCallback onListen,
  required VoidCallback onRetryMic,
}) async {
  final store = StorageService.instance;
  final bookmarked = store.isAyahBookmarked(surahNumber, ayahNumber);

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                focusWord != null
                    ? 'خيارات · «${focusWord.display}» — آية $ayahNumber'
                    : 'خيارات المساعدة — آية $ayahNumber',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.volume_up_rounded),
              title: const Text('استمع'),
              subtitle: const Text('تشغيل تلاوة القارئ المرجعية'),
              onTap: () {
                Navigator.pop(ctx);
                onListen();
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic_rounded),
              title: const Text('أعد التسميع'),
              onTap: () {
                Navigator.pop(ctx);
                onRetryMic();
              },
            ),
            ListTile(
              leading: const Icon(Icons.translate_rounded),
              title: const Text('ترجمة'),
              subtitle: const Text('معنى الآية (يتطلب إنترنت)'),
              onTap: () {
                Navigator.pop(ctx);
                _showRemoteText(
                  context,
                  title: 'ترجمة الآية',
                  surah: surahNumber,
                  ayah: ayahNumber,
                  edition: 'en.sahih',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_rounded),
              title: const Text('تفسير'),
              subtitle: const Text('التفسير الميسّر (يتطلب إنترنت)'),
              onTap: () {
                Navigator.pop(ctx);
                _showRemoteText(
                  context,
                  title: 'التفسير الميسّر',
                  surah: surahNumber,
                  ayah: ayahNumber,
                  edition: 'ar.muyassar',
                );
              },
            ),
            ListTile(
              leading: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border),
              title: Text(bookmarked ? 'إزالة الإشارة المرجعية' : 'أضف إشارة مرجعية'),
              onTap: () async {
                Navigator.pop(ctx);
                if (bookmarked) {
                  await store.removeAyahBookmark(surahNumber, ayahNumber);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('أُزيلت الإشارة المرجعية')),
                    );
                  }
                } else {
                  await store.addAyahBookmark(surahNumber, ayahNumber);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تمت إضافة إشارة مرجعية')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.compare_arrows_rounded),
              title: const Text('المتشابهات'),
              subtitle: const Text('مواضع مشابهة في نفس السورة'),
              onTap: () {
                Navigator.pop(ctx);
                _showSimilar(context, surahAyat, ayahNumber, focusWord);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

Future<void> _showRemoteText(
  BuildContext context, {
  required String title,
  required int surah,
  required int ayah,
  required String edition,
}) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  String? text;
  try {
    final uri = Uri.parse('https://api.alquran.cloud/v1/ayah/$surah:$ayah/$edition');
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final ayahData = data['data'];
      if (ayahData is Map && ayahData['text'] is String) {
        text = ayahData['text'] as String;
      }
    }
  } catch (_) {
    text = null;
  }
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Text(
          text ?? 'تعذّر الجلب. تحقق من الاتصال بالإنترنت.',
          style: const TextStyle(height: 1.7, fontSize: 15),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
      ],
    ),
  );
}

void _showSimilar(
  BuildContext context,
  List<AyahData> ayat,
  int currentAyah,
  WordResult? focusWord,
) {
  final needle = (focusWord?.display ?? '').trim();
  final hits = <String>[];
  if (needle.isNotEmpty) {
    final normNeedle = ArabicText.normalize(needle);
    for (final a in ayat) {
      if (a.number == currentAyah) continue;
      for (final w in ArabicText.displayWords(a.text)) {
        if (ArabicText.normalize(w) == normNeedle) {
          hits.add('آية ${a.number}: ${a.text}');
          break;
        }
      }
    }
  }
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('المتشابهات في السورة'),
      content: SizedBox(
        width: double.maxFinite,
        child: hits.isEmpty
            ? Text(
                needle.isEmpty
                    ? 'اضغط كلمة خاطئة أولاً للبحث عن متشابهاتها.'
                    : 'لم يُعثر على «$needle» في آيات أخرى من هذه السورة.',
                style: const TextStyle(height: 1.7),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: hits.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (_, i) => Text(
                  hits[i],
                  style: const TextStyle(height: 1.7, fontSize: 14),
                ),
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
      ],
    ),
  );
}
