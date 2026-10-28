import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

/// رسائل منبثقة سريعة.
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

/// حوار تأكيد أنيق.
Future<bool> appConfirm(
  BuildContext context, {
  required String title,
  required String body,
  String okText = 'تأكيد',
  String cancelText = 'إلغاء',
  DialogType type = DialogType.question,
}) async {
  var accepted = false;
  await AwesomeDialog(
    context: context,
    dialogType: type,
    animType: AnimType.scale,
    title: title,
    desc: body,
    btnCancelText: cancelText,
    btnOkText: okText,
    btnCancelOnPress: () {},
    btnOkOnPress: () => accepted = true,
  ).show();
  return accepted;
}

/// حوار نجاح.
Future<void> appSuccess(
  BuildContext context, {
  required String title,
  String? body,
}) async {
  await AwesomeDialog(
    context: context,
    dialogType: DialogType.success,
    animType: AnimType.bottomSlide,
    title: title,
    desc: body,
    btnOkText: 'حسناً',
    btnOkOnPress: () {},
  ).show();
}
