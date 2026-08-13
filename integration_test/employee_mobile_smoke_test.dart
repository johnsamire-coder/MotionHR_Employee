import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motionhr_employee/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const username = 're_sales_1';
  const password = 'Test@1234';

  Future<void> hardResetApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // حافظ على إعداد اللغة عشان التطبيق ميفتحش First Launch
    await prefs.setBool('first_launch_done', true);
    await prefs.setString('language', 'ar');
  }

  Future<void> pumpFor(WidgetTester tester, int seconds) async {
    for (int i = 0; i < seconds; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  Future<void> waitForLoginScreen(WidgetTester tester) async {
    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      final fields = find.byType(TextField);
      final loginAr = find.text('دخول');
      final loginEn = find.text('Login');
      if (tester.any(fields) && (tester.any(loginAr) || tester.any(loginEn))) {
        return;
      }
    }
    throw Exception('شاشة اللوجين لم تظهر');
  }

  testWidgets('EMPLOYEE MOBILE SMOKE: login + home tabs', (tester) async {
    await hardResetApp();

    app.main();
    await pumpFor(tester, 4);
    await waitForLoginScreen(tester);

    final fields = find.byType(TextField);
    expect(fields, findsAtLeastNWidgets(2), reason: 'حقول اللوجين غير موجودة');

    await tester.enterText(fields.at(0), username);
    await tester.enterText(fields.at(1), password);
    await tester.pump(const Duration(milliseconds: 500));

    final loginBtn = tester.any(find.text('دخول'))
        ? find.text('دخول')
        : find.text('Login');

    await tester.ensureVisible(loginBtn);
    await tester.tap(loginBtn, warnIfMissed: false);

    await pumpFor(tester, 10);

    final visibleTexts = tester
        .widgetList<Text>(find.byType(Text))
        .map((w) => w.data ?? '')
        .where((t) => t.trim().isNotEmpty)
        .take(80)
        .toList();

    debugPrint('VISIBLE_TEXTS_START');
    for (final t in visibleTexts) {
      debugPrint(t);
    }
    debugPrint('VISIBLE_TEXTS_END');

    final homeChecks = [
      find.text('تسجيل الحضور'),
      find.text('إجازاتي'),
      find.text('طلباتي'),
      find.text('حضوري'),
      find.text('الرئيسية'),
      find.text('لائحة الشركة'),
      find.text('تغيير كلمة المرور'),
      find.text('Company Charter'),
      find.text('Change Password'),
    ];

    bool ok = false;
    for (final item in homeChecks) {
      if (tester.any(item)) {
        ok = true;
        break;
      }
    }

    expect(ok, true, reason: 'الموظف لم يصل لشاشة معروفة بعد اللوجين');
    debugPrint('✅ EMPLOYEE MOBILE SMOKE PASS');
  });
}
