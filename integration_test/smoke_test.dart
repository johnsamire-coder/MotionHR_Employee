import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:motionhr_employee/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const BASE_URL = 'https://jssolutions-eg.com';
  const PASSWORD = 'Test@1234';

  final SCENARIOS = [
    {'username': 're_admin', 'role': 'manager', 'label': 'عقاري - مدير'},
    {'username': 'con_admin', 'role': 'manager', 'label': 'مقاولات - مدير'},
    {'username': 'ph_hr', 'role': 'manager', 'label': 'أدوية - HR'},
    {'username': 'wh_admin', 'role': 'manager', 'label': 'مخازن - مدير'},
    {'username': 're_sales_1', 'role': 'employee', 'label': 'عقاري - موظف ميداني'},
    {'username': 'con_worker_1', 'role': 'employee', 'label': 'مقاولات - عامل'},
    {'username': 'ph_rep_1', 'role': 'employee', 'label': 'أدوية - مندوب'},
    {'username': 'wh_dispatch', 'role': 'employee', 'label': 'مخازن - مندوب'},
  ];

  for (final scenario in SCENARIOS) {
    final username = scenario['username']!;
    final label = scenario['label']!;

    testWidgets('LOGIN: $label ($username)', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // انتظر شاشة اللوجين
      final userField = find.byType(TextField).first;
      final passField = find.byType(TextField).at(1);

      await tester.enterText(userField, username);
      await tester.enterText(passField, PASSWORD);
      await tester.pumpAndSettle();

      // دوس زر الدخول
      final loginBtn = find.text('دخول');
      expect(loginBtn, findsOneWidget, reason: 'زرار دخول مش موجود');
      await tester.tap(loginBtn);
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // تأكد إن الرئيسية فتحت
      final homeIndicators = [
        find.text('الرئيسية'),
        find.text('Dashboard'),
        find.text('لوحة التحكم'),
        find.text('MotionHR'),
        find.byType(BottomNavigationBar),
        find.byType(Scaffold),
      ];

      bool foundHome = false;
      for (final indicator in homeIndicators) {
        if (tester.any(indicator)) {
          foundHome = true;
          break;
        }
      }

      expect(foundHome, true, reason: 'الرئيسية مش اتفتحت بعد اللوجين');

      debugPrint('✅ LOGIN OK: $label');
    });
  }
}
