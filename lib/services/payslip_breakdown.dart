// lib/services/payslip_breakdown.dart
//
// بنود كشف المرتب زي ما بتظهر في الويب بالظبط (نفس الترتيب ونفس الحساب).
// الأرقام كلها جاية من السيرفر (employee/payslip)، والملف ده بيرتبها بس:
//   الإيرادات: الأساسي، البدلات، الأوفر تايم، المكافآت، ... = إجمالي المستحق
//   الخصومات: التأخير، الغياب، التأمينات، الضريبة، الأقساط، الجزاءات، ... = إجمالي الخصومات
// ولو فيه فرق بين مجموع البنود والإجمالي اللي راجع من السيرفر، بيظهر في سطر
// "استحقاقات أخرى" أو "خصومات أخرى"، عشان البنود تجمع دايمًا على الإجمالي.

class PayslipItem {
  final String name;
  final double amount;
  const PayslipItem(this.name, this.amount);
}

class PayslipLine {
  final String key;
  final String label;
  final double amount;
  final List<PayslipItem> items;
  const PayslipLine(this.key, this.label, this.amount, [this.items = const []]);
}

class PayslipBreakdown {
  final List<PayslipLine> earnings;
  final double gross;
  final List<PayslipLine> deductions;
  final double totalDeductions;
  final double net;
  final List<PayslipLine> companyInsurance;
  final bool isFinal;
  const PayslipBreakdown({
    required this.earnings,
    required this.gross,
    required this.deductions,
    required this.totalDeductions,
    required this.net,
    required this.companyInsurance,
    required this.isFinal,
  });
}

double payslipNum(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse('${v ?? ''}') ?? 0.0;
}

double _round2(double v) => (v * 100).roundToDouble() / 100;

List<PayslipItem> _items(dynamic list, bool isAr) {
  if (list is! List) return const [];
  final out = <PayslipItem>[];
  for (final it in list) {
    if (it is! Map) continue;
    final amount = payslipNum(it['amount']);
    if (amount == 0) continue;
    final name = (isAr ? it['name_ar'] : it['name_en']) ?? it['name'] ?? '';
    out.add(PayslipItem('$name', amount));
  }
  return out;
}

PayslipBreakdown buildPayslipBreakdown(Map<String, dynamic> d, bool isAr) {
  double n(String k) => payslipNum(d[k]);
  final isFinal = d['is_final'] == true;
  String t(String ar, String en) => isAr ? ar : en;

  // ─── الإيرادات ───
  final earnings = <PayslipLine>[
    PayslipLine('basic_salary', t('الراتب الأساسي', 'Basic Salary'), n('basic_salary')),
  ];
  void addEarn(String key, String label, [List<PayslipItem> items = const []]) {
    final v = n(key);
    if (v != 0) earnings.add(PayslipLine(key, label, v, items));
  }

  addEarn('allowances_total', t('البدلات', 'Allowances'), _items(d['allowance_items'], isAr));
  addEarn('overtime_bonus', t('الأوفر تايم', 'Overtime'));
  addEarn('bonuses_total', t('المكافآت', 'Bonuses'), _items(d['bonus_items'], isAr));
  // لو المسير معتمد، السيرفر بيرجّع الإجماليات من المسير، والبنود التفصيلية دي ممكن تكون
  // اتحسبت بعده، فبتدخل في "استحقاقات أخرى" بدل ما تظهر لوحدها
  if (!isFinal) {
    addEarn('night_allowance', t('بدل الوردية الليلية', 'Night Allowance'));
    addEarn('weekend_allowance', t('بدل العمل في يوم الراحة', 'Weekend Allowance'));
    addEarn('rule_allowances_total', t('بدلات السياسات', 'Policy Allowances'),
        _items(d['rule_allowance_items'], isAr));
    addEarn('kpi_bonus', t('مكافأة الأداء', 'KPI Bonus'));
  }
  final gross = n('gross_salary');
  final shownEarn = earnings.fold<double>(0, (s, l) => s + l.amount);
  final otherEarn = _round2(gross - shownEarn);
  if (otherEarn > 0.01) {
    earnings.add(PayslipLine('other_earnings', t('استحقاقات أخرى', 'Other Earnings'), otherEarn));
  }

  // ─── الخصومات ───
  final deductions = <PayslipLine>[];
  void addDed(String key, String label, [List<PayslipItem> items = const []]) {
    final v = n(key);
    if (v != 0) deductions.add(PayslipLine(key, label, v, items));
  }

  addDed('late_deduction', t('خصم التأخير', 'Late Deduction'));
  addDed('absence_deduction', t('خصم الغياب', 'Absence Deduction'));
  if (!isFinal) {
    addDed('early_leave_deduction', t('خصم الانصراف المبكر', 'Early Leave Deduction'));
    addDed('unpaid_leave_deduction', t('إجازة بدون أجر', 'Unpaid Leave'));
    addDed('missing_checkout_deduction', t('عدم تسجيل الانصراف', 'Missing Check-out'));
    addDed('flex_shortage_deduction', t('نقص ساعات الشيفت المرن', 'Flex Hours Shortage'));
    addDed('not_employed_deduction', t('أيام قبل التعيين أو بعد انتهاء الخدمة', 'Days Outside Employment'));
  }
  final social = n('social_insurance_employee');
  final medical = n('medical_insurance_employee');
  final insurance = n('insurance_deduction');
  if (!isFinal && (social != 0 || medical != 0) &&
      (social + medical - insurance).abs() < 0.02) {
    addDed('social_insurance_employee', t('تأمين اجتماعي (حصة الموظف)', 'Social Insurance (Employee Share)'));
    addDed('medical_insurance_employee', t('تأمين طبي (حصة الموظف)', 'Medical Insurance (Employee Share)'));
  } else {
    addDed('insurance_deduction', t('التأمينات', 'Insurance'), _items(d['insurance_items'], isAr));
  }
  addDed('tax_deduction', t('ضريبة الدخل', 'Income Tax'));
  addDed('installments_total', t('الأقساط والسلف', 'Installments & Loans'),
      _items(d['installment_items'], isAr));
  addDed('penalties_total', t('الجزاءات', 'Penalties'), _items(d['penalty_items'], isAr));
  addDed('extra_deductions_total', t('خصومات إضافية', 'Extra Deductions'),
      _items(d['extra_deduction_items'], isAr));
  final totalDeductions = n('total_deductions');
  final shownDed = deductions.fold<double>(0, (s, l) => s + l.amount);
  final otherDed = _round2(totalDeductions - shownDed);
  if (otherDed > 0.01) {
    deductions.add(PayslipLine('other_deductions', t('خصومات أخرى', 'Other Deductions'), otherDed));
  }

  // ─── مساهمة الشركة في التأمينات (للعلم بس، مش بتتخصم من المرتب) ───
  final company = <PayslipLine>[];
  if (n('social_insurance_company') != 0) {
    company.add(PayslipLine('social_insurance_company', t('تأمين اجتماعي', 'Social Insurance'),
        n('social_insurance_company')));
  }
  if (n('medical_insurance_company') != 0) {
    company.add(PayslipLine('medical_insurance_company', t('تأمين طبي', 'Medical Insurance'),
        n('medical_insurance_company')));
  }
  if (n('total_company_insurance_contribution') != 0) {
    company.add(PayslipLine('total_company_insurance_contribution', t('الإجمالي', 'Total'),
        n('total_company_insurance_contribution')));
  }

  return PayslipBreakdown(
    earnings: earnings,
    gross: gross,
    deductions: deductions,
    totalDeductions: totalDeductions,
    net: n('net_salary'),
    companyInsurance: company,
    isFinal: isFinal,
  );
}

/// 1234.5 -> "1,234.50" ، و 1200 -> "1,200"
String formatPayslipMoney(double v) {
  final neg = v < 0;
  final abs = v.abs();
  final whole = abs.truncate();
  final cents = ((abs - whole) * 100).round();
  final w = cents == 100 ? whole + 1 : whole;
  final c = cents == 100 ? 0 : cents;
  final digits = '$w';
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  final s = c == 0 ? buf.toString() : '${buf.toString()}.${c.toString().padLeft(2, '0')}';
  return neg ? '-$s' : s;
}
