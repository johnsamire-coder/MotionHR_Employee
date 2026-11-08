import 'package:flutter_test/flutter_test.dart';
import 'package:motionhr_employee/services/payslip_breakdown.dart';

double _sum(List<PayslipLine> l) => l.fold(0.0, (s, x) => s + x.amount);

void main() {
  // كشف شهر عادي (مش معتمد) فيه كل البنود
  final live = <String, dynamic>{
    'is_final': false,
    'currency': 'EGP',
    'basic_salary': 10000,
    'allowances_total': 1500,
    'allowance_items': [
      {'name_ar': 'بدل مواصلات', 'name_en': 'Transport', 'amount': 1000},
      {'name_ar': 'بدل وجبة', 'name_en': 'Meal', 'amount': 500},
    ],
    'overtime_bonus': 750.5,
    'bonuses_total': 300,
    'bonus_items': [
      {'name_ar': 'مكافأة', 'name_en': 'Bonus', 'amount': 300},
    ],
    'night_allowance': 200,
    'weekend_allowance': 0,
    'rule_allowances_total': 100,
    'kpi_bonus': 0,
    'gross_salary': 12850.5,
    'late_deduction': 120,
    'absence_deduction': 333.33,
    'early_leave_deduction': 50,
    'social_insurance_employee': 1100,
    'medical_insurance_employee': 100,
    'insurance_deduction': 1200,
    'tax_deduction': 640.25,
    'installments_total': 500,
    'installment_items': [
      {'name_ar': 'سلفة', 'name_en': 'Loan', 'amount': 500},
    ],
    'penalties_total': 200,
    'extra_deductions_total': 0,
    'total_deductions': 3043.58,
    'net_salary': 9806.92,
    'social_insurance_company': 1875,
    'medical_insurance_company': 0,
    'total_company_insurance_contribution': 1875,
  };

  test('earnings add up to gross and deductions to the total', () {
    final b = buildPayslipBreakdown(live, true);
    expect(_sum(b.earnings), closeTo(b.gross, 0.005));
    expect(_sum(b.deductions), closeTo(b.totalDeductions, 0.005));
    expect(b.gross - b.totalDeductions, closeTo(b.net, 0.005));
  });

  test('shows every item the web shows, with item details', () {
    final b = buildPayslipBreakdown(live, true);
    final earnKeys = b.earnings.map((l) => l.key).toList();
    expect(earnKeys, [
      'basic_salary', 'allowances_total', 'overtime_bonus', 'bonuses_total',
      'night_allowance', 'rule_allowances_total',
    ]);
    final dedKeys = b.deductions.map((l) => l.key).toList();
    expect(dedKeys, [
      'late_deduction', 'absence_deduction', 'early_leave_deduction',
      'social_insurance_employee', 'medical_insurance_employee',
      'tax_deduction', 'installments_total', 'penalties_total',
    ]);
    final allow = b.earnings.firstWhere((l) => l.key == 'allowances_total');
    expect(allow.items.map((i) => i.name), ['بدل مواصلات', 'بدل وجبة']);
    expect(b.companyInsurance.map((l) => l.key),
        ['social_insurance_company', 'total_company_insurance_contribution']);
  });

  test('English names come from name_en', () {
    final b = buildPayslipBreakdown(live, false);
    final allow = b.earnings.firstWhere((l) => l.key == 'allowances_total');
    expect(allow.items.first.name, 'Transport');
    expect(allow.label, 'Allowances');
  });

  test('approved run: totals from the run, the difference goes to "other"', () {
    final approved = Map<String, dynamic>.from(live)
      ..['is_final'] = true
      ..['gross_salary'] = 13000.0
      ..['total_deductions'] = 3100.0
      ..['net_salary'] = 9900.0;
    final b = buildPayslipBreakdown(approved, true);
    expect(b.isFinal, isTrue);
    // البنود التفصيلية (البدل الليلي، الانصراف المبكر) مابتظهرش لوحدها في المسير المعتمد
    expect(b.earnings.any((l) => l.key == 'night_allowance'), isFalse);
    expect(b.deductions.any((l) => l.key == 'early_leave_deduction'), isFalse);
    expect(b.deductions.any((l) => l.key == 'insurance_deduction'), isTrue);
    expect(_sum(b.earnings), closeTo(13000, 0.005));
    expect(_sum(b.deductions), closeTo(3100, 0.005));
    expect(b.earnings.last.key, 'other_earnings');
    expect(b.deductions.last.key, 'other_deductions');
  });

  test('zero lines are hidden, basic salary always shown', () {
    final b = buildPayslipBreakdown({
      'basic_salary': 5000, 'gross_salary': 5000, 'total_deductions': 0, 'net_salary': 5000,
    }, true);
    expect(b.earnings.map((l) => l.key), ['basic_salary']);
    expect(b.deductions, isEmpty);
    expect(b.companyInsurance, isEmpty);
  });

  test('numbers sent as text still work', () {
    final b = buildPayslipBreakdown({
      'basic_salary': '5000.00', 'gross_salary': '5000.00',
      'tax_deduction': '10.5', 'total_deductions': '10.50', 'net_salary': '4989.50',
    }, true);
    expect(b.deductions.single.amount, 10.5);
    expect(b.net, 4989.5);
  });

  test('money format', () {
    expect(formatPayslipMoney(1234.5), '1,234.50');
    expect(formatPayslipMoney(1200), '1,200');
    expect(formatPayslipMoney(999.999), '1,000');
    expect(formatPayslipMoney(0), '0');
    expect(formatPayslipMoney(-50.25), '-50.25');
    expect(formatPayslipMoney(1234567.89), '1,234,567.89');
  });

  test('KPI bonus line uses the same name as the web', () {
    final b = buildPayslipBreakdown({
      'basic_salary': 5000, 'kpi_bonus': 250, 'gross_salary': 5250,
      'total_deductions': 0, 'net_salary': 5250,
    }, true);
    expect(b.earnings.last.key, 'kpi_bonus');
    expect(b.earnings.last.label, 'مكافأة الانضباط (KPI)');
  });
}
