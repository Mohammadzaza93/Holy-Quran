import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tajweed_quiz/main.dart';
import 'package:tajweed_quiz/services/storage_service.dart';

class _NoNetworkOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (Uri _) => 'PROXY 127.0.0.1:1';
    client.connectionTimeout = const Duration(milliseconds: 50);
    return client;
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _NoNetworkOverrides();
  });

  testWidgets('يعرض التطبيق الشاشة الرئيسية', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();

    await tester.pumpWidget(const TajweedApp());
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();

    // العناوين بعد إعادة تصميم الواجهة
    expect(find.text('تجويد حفص'), findsWidgets);
    expect(find.text('شامل'), findsOneWidget);
    expect(find.text('شرح التجويد المصور'), findsOneWidget);
  });
}
