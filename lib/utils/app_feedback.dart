import 'package:flutter/material.dart';

/// رسالة سريعة عبر SnackBar (بدون حزم خارجية).
void appToast(BuildContext context, String message, {bool success = false}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor:
          success ? const Color(0xFF0B6E4F) : null,
      duration: const Duration(seconds: 2),
    ),
  );
}

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

Future<void> appSuccess(
  BuildContext context, {
  required String title,
  String? body,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.check_circle_rounded,
          color: Color(0xFF0B6E4F), size: 40),
      title: Text(title),
      content: body == null
          ? null
          : Text(body, style: const TextStyle(height: 1.6)),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('حسناً'),
        ),
      ],
    ),
  );
}
