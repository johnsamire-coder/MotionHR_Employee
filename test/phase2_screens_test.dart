// شاشات مرحلة 2 بتتعرض من غير أخطاء (بالعربي، على مقاس موبايل)
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motionhr_employee/screens/common/charters_screens.dart';
import 'package:motionhr_employee/screens/manager/shifts/create_edit_shift_screen.dart';

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

  Future<void> phone(WidgetTester t) async {
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
  }

  testWidgets('shift form: break options like the web', (t) async {
    await phone(t);
    await t.pumpWidget(_app(const CreateEditShiftScreen(existingShift: {
      'id': 1, 'name': 'صباحي', 'shift_type': 'fixed', 'shift_mode': 'fixed',
      'start_time': '09:00', 'end_time': '17:00',
      'break_duration': 30, 'break_paid': false, 'break_punched': true,
    })));
    await t.pump();
    final hasBreak = find.text('فيه بريك (راحة) في الشيفت ده');
    await t.scrollUntilVisible(hasBreak, 300, scrollable: find.byType(Scrollable).first);
    expect(hasBreak, findsOneWidget);
    expect(find.text('مش مدفوع (بيتطرح من ساعات الشغل)'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('new shift has no break by default (like the web)', (t) async {
    await phone(t);
    await t.pumpWidget(_app(const CreateEditShiftScreen()));
    await t.pump();
    final hasBreak = find.text('فيه بريك (راحة) في الشيفت ده');
    await t.scrollUntilVisible(hasBreak, 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('البريك مدفوع؟'), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('charter form renders with all fields', (t) async {
    await phone(t);
    await t.pumpWidget(_app(const CharterFormScreen(charter: {
      'id': 3, 'title': 'لائحة المديرين', 'content': 'بنود', 'is_mandatory': true,
      'target_roles': ['manager'], 'target_departments': [], 'target_branches': [],
    })));
    await t.pump();
    expect(find.text('لائحة المديرين'), findsOneWidget);
    expect(find.text('مدير'), findsOneWidget);
    expect(find.text('تعديل اللائحة'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
