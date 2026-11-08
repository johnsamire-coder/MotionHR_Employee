// شاشات مرحلة 4 و5 بتتعرض من غير أخطاء (بالعربي، على مقاس موبايل صغير)
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motionhr_employee/l10n/generated/app_localizations.dart';
import 'package:motionhr_employee/screens/manager/reports/reports_hub_screen.dart';
import 'package:motionhr_employee/screens/manager/reports/server_table_report_screen.dart';
import 'package:motionhr_employee/screens/manager/reports/overtime_report_screen.dart';
import 'package:motionhr_employee/screens/manager/reports/eos_report_screen.dart';
import 'package:motionhr_employee/screens/manager/reports/field_visits_report_screen.dart';
import 'package:motionhr_employee/screens/manager/biometric_screen.dart';
import 'package:motionhr_employee/screens/manager/audit_log_screen.dart';

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> show(WidgetTester t, Widget w) async {
    t.view.physicalSize = const Size(360 * 3, 740 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(_app(w));
    await t.pump(const Duration(milliseconds: 300));
    await t.pump(const Duration(milliseconds: 300));
  }

  testWidgets('reports hub lists the new reports', (t) async {
    await show(t, const ReportsHubScreen());
    final list = find.byType(Scrollable).first;
    for (final title in ['تقرير الأوفر تايم', 'مكافأة نهاية الخدمة', 'معدل دوران الموظفين']) {
      await t.scrollUntilVisible(find.text(title), 300, scrollable: list);
      expect(find.text(title), findsOneWidget);
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('all nine table reports open', (t) async {
    expect(kServerTableReports.length, 9);
    for (final r in kServerTableReports) {
      await show(t, ServerTableReportScreen(def: r));
      expect(find.text(r.titleAr), findsOneWidget);
      expect(t.takeException(), isNull);
    }
  });

  testWidgets('overtime, eos, field visits', (t) async {
    await show(t, const OvertimeReportScreen());
    expect(t.takeException(), isNull);
    await show(t, const EosReportScreen());
    expect(t.takeException(), isNull);
    await show(t, const FieldVisitsReportScreen());
    expect(t.takeException(), isNull);
  });

  testWidgets('biometric tabs', (t) async {
    await show(t, const BiometricScreen());
    expect(find.text('تسجيل جهاز'), findsOneWidget);
    for (final tab in ['ربط الأرقام', 'رفع ملف', 'التقرير']) {
      await t.tap(find.text(tab));
      await t.pump(const Duration(milliseconds: 500));
      await t.pump(const Duration(milliseconds: 500));
      expect(t.takeException(), isNull);
    }
  });

  testWidgets('audit log both tabs', (t) async {
    await show(t, const AuditLogScreen());
    expect(find.text('سجل البرنامج'), findsOneWidget);
    await t.tap(find.text('سجل موظف'));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('اختار موظف'), findsWidgets);
    expect(t.takeException(), isNull);
  });
}
