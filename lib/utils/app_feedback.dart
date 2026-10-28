import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

/// رسائل منبثقة سريعة (BotToast).
void appToast(String message, {bool success = false}) {
  BotToast.showText(
    text: message,
    duration: const Duration(seconds: 2),
    contentColor: success ? const Color(0xFF0B6E4F) : const Color(0xFF2C2C2C),
    textStyle: const TextStyle(color: Colors.white, fontSize: 14),
    borderRadius: BorderRadius.circular(10),
    align: const Alignment(0, 0.72),
  );
}

/// حوار تأكيد بـ Material (بدون awesome_dialog).
Future<bool> appConfirm(
  BuildContext context, {
  required String title,
  required String body,
  String okText = 'تأكيد',
  String cancelText = 'إلغاء',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body, style: const TextStyle(height: 1.6)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(okText),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// حوار نجاح.
Future<void> appSuccess(
  BuildContext context, {
  required String title,
  String? body,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF0B6E4F), size: 40),
      title: Text(title),
      content: body == null ? null : Text(body, style: const TextStyle(height: 1.6)),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('حسناً'),
        ),
      ],
    ),
  );
}
