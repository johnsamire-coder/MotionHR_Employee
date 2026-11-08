// شاشات مرحلة 3 بتتعرض من غير أخطاء (بالعربي، على مقاس موبايل)
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motionhr_employee/screens/manager/hr_leaves_screen.dart';
import 'package:motionhr_employee/screens/manager/installments_screen.dart';
import 'package:motionhr_employee/screens/manager/substitution_summary_screen.dart';
import 'package:motionhr_employee/screens/manager/work_locations_approval_screen.dart';

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
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

  testWidgets('leaves screen', (t) async {
    await show(t, const HrLeavesScreen());
    expect(find.text('الإجازات'), findsWidgets);
    expect(find.text('إضافة إجازة'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('add leave form', (t) async {
    await show(t, const HrAddLeaveScreen());
    expect(find.text('الموظف البديل (مطلوب للمرضية)'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('installments + add form', (t) async {
    await show(t, const InstallmentsScreen());
    expect(find.text('السلف والأقساط'), findsOneWidget);
    expect(t.takeException(), isNull);
    await show(t, const AddInstallmentScreen());
    expect(find.text('إضافة السلفة'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('substitution summary', (t) async {
    await show(t, const SubstitutionSummaryScreen());
    expect(t.takeException(), isNull);
  });

  testWidgets('assign employees to location', (t) async {
    await show(t, const AssignLocationEmployeesScreen(
        location: {'id': 5, 'name': 'فرع المهندسين', 'assigned_employee_ids': [1, 2]}));
    expect(find.text('موظفين محددين'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
