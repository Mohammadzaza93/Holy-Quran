import 'package:flutter/material.dart';

import '../services/ayah_text_service.dart';
import '../services/connectivity_service.dart';
import '../services/mushaf_service.dart';
import '../services/recitation_checker.dart';
import '../services/storage_service.dart';

/// قائمة خيارات عند خطأ التلاوة:
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
    isScrollControlled: true,
    builder: (ctx) {
      final maxH = MediaQuery.sizeOf(ctx).height * 0.72;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Text(
                    focusWord != null
                        ? 'خيارات · «${focusWord.display}» — آية $ayahNumber'
                        : 'خيارات المساعدة — آية $ayahNumber',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(Icons.volume_up_rounded),
                  title: const Text('استمع'),
                  subtitle: const Text('تشغيل تلاوة القارئ المرجعية'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onListen();
                  },
                ),
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(Icons.mic_rounded),
                  title: const Text('أعد التسميع'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onRetryMic();
                  },
                ),
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(Icons.translate_rounded),
                  title: const Text('ترجمة'),
                  subtitle: const Text('محلياً بعد التحميل من الإعدادات'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showCachedOrFetch(
                      context,
                      title: 'ترجمة الآية',
                      surah: surahNumber,
                      ayah: ayahNumber,
                      kind: _TextKind.translation,
                    );
                  },
                ),
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(Icons.menu_book_rounded),
                  title: const Text('تفسير'),
                  subtitle: const Text('الميسّر — محلياً بعد التحميل'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showCachedOrFetch(
                      context,
                      title: 'التفسير الميسّر',
                      surah: surahNumber,
                      ayah: ayahNumber,
                      kind: _TextKind.tafsir,
                    );
                  },
                ),
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
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
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(Icons.compare_arrows_rounded),
                  title: const Text('المتشابهات'),
                  subtitle: const Text('مواضع مشابهة في نفس السورة'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showSimilar(context, surahAyat, ayahNumber, focusWord);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      );
    },
  );
}

enum _TextKind { translation, tafsir }

Future<void> _showCachedOrFetch(
  BuildContext context, {
  required String title,
  required int surah,
  required int ayah,
  required _TextKind kind,
}) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  String? text = kind == _TextKind.tafsir
      ? await AyahTextService.getTafsir(surah, ayah, allowNetwork: false)
      : await AyahTextService.getTranslation(surah, ayah, allowNetwork: false);

  if (text == null && await ConnectivityService.isOnline()) {
    text = kind == _TextKind.tafsir
        ? await AyahTextService.getTafsir(surah, ayah, allowNetwork: true)
        : await AyahTextService.getTranslation(surah, ayah, allowNetwork: true);
  }

  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();

  final body = text ??
      'النص غير محمّل على الجهاز.\n\n'
          'من الإعدادات ← «حفظ التفسير والترجمة دون اتصال» '
          'أو اتصل بالإنترنت مرة واحدة لجلب هذه السورة تلقائياً.';

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Text(body, style: const TextStyle(height: 1.7, fontSize: 15)),
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
