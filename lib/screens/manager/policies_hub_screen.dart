import 'package:flutter/material.dart';
import 'attendance_policy_screen.dart';
import 'payroll_policy_screen.dart';
import 'leave_policy_screen.dart';
import 'official_holidays_screen.dart';
import 'payroll/tax_policy_screen.dart';
import 'payroll/eos_policy_screen.dart';
import 'payroll/insurance_policies_screen.dart';
import 'payroll/payroll_cycle_screen.dart';
import 'payroll/penalty_rules_screen.dart';
import 'payroll/bonus_rules_screen.dart';
import 'payroll/allowance_rules_screen.dart';
import 'payroll/leave_rules_screen.dart';
import 'payroll/manual_entries_screen.dart';

const Color kPoliciesHubColor = Color(0xFF455A64);

class PoliciesHubScreen extends StatelessWidget {
  const PoliciesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            isAr ? 'مركز السياسات' : 'Policies Hub',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: kPoliciesHubColor,
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _policyCard(
              context,
              title: isAr ? 'سياسات الحضور والانصراف' : 'Attendance Policies',
              subtitle: isAr ? 'قواعد البصمة والشيفتات والانضباط' : 'Attendance, shifts and discipline',
              color: const Color(0xFF00C688),
              icon: Icons.fingerprint,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendancePolicyScreen())),
            ),
            const SizedBox(height: 12),
            _policyCard(
              context,
              title: isAr ? 'سياسات الرواتب العامة' : 'Payroll Policies',
              subtitle: isAr ? 'البدلات والخصومات والمكافآت العامة' : 'General payroll policies',
              color: const Color(0xFF2E7D32),
              icon: Icons.payments,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PayrollPolicyScreen())),
            ),
            const SizedBox(height: 12),
            _policyCard(
              context,
              title: isAr ? 'سياسة الإجازات' : 'Leave Policy',
              subtitle: isAr ? 'سياسات الإجازات العامة والاعتمادات' : 'General leave policy and approvals',
              color: const Color(0xFF382483),
              icon: Icons.beach_access,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeavePolicyScreen())),
            ),
            const SizedBox(height: 12),
            _policyCard(
              context,
              title: isAr ? 'الأعياد والعطلات الرسمية' : 'Official Holidays',
              subtitle: isAr ? 'أيام الأعياد والعطلات الرسمية ومعاملتها في الرواتب' : 'Public holidays and payroll treatment',
              color: const Color(0xFF382483),
              icon: Icons.celebration,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OfficialHolidaysScreen())),
            ),
            const SizedBox(height: 12),
            _policyCard(
              context,
              title: isAr ? 'سياسة الضرائب' : 'Tax Policy',
              subtitle: isAr ? 'الشرائح الضريبية والإعفاءات الشخصية' : 'Tax brackets and personal exemptions',
              color: const Color(0xFFE65100),
              icon: Icons.receipt_long,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TaxPolicyScreen())),
            ),
            const SizedBox(height: 12),
            _policyCard(
              context,
              title: isAr ? 'مكافأة نهاية الخدمة' : 'End of Service',
              subtitle: isAr ? 'شرائح سنوات الخدمة ونسب الاستحقاق' : 'Service tiers and entitlement rates',
              color: const Color(0xFFF57C00),
              icon: Icons.card_giftcard,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EosPolicyScreen())),
            ),
            const SizedBox(height: 12),
            _policyCard(
              context,
              title: isAr ? 'التأمينات' : 'Insurance',
              subtitle: isAr ? 'التأمينات الاجتماعية والطبية' : 'Social and medical insurance',
              color: const Color(0xFF00C688),
              icon: Icons.shield,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InsurancePoliciesScreen())),
            ),
            const SizedBox(height: 12),
            _policyCard(
              context,
              title: isAr ? 'دورة الرواتب' : 'Payroll Cycle',
              subtitle: isAr ? 'يوم القفل والصرف والموافقات' : 'Cutoff, pay day and approvals',
              color: const Color(0xFF4A389E),
              icon: Icons.calendar_month,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PayrollCycleScreen())),
            ),
            const SizedBox(height: 12),
            _policyCard(
              context,
              title: isAr ? 'قواعد الجزاءات' : 'Penalty Rules',
              subtitle: isAr ? 'الشرائح التصاعدية والإنذارات والنطاق' : 'Tiers, warnings and scope',
              color: const Color(0xFFD32F2F),
              icon: Icons.trending_down,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PenaltyRulesScreen())),
            ),
            const SizedBox(height: 12),
            _policyCard(
              context,
              title: isAr ? 'قواعد المكافآت والأوفرتايم' : 'Bonus Rules',
              subtitle: isAr ? 'الأوفرتايم والشيفت الليلي والويكند' : 'Overtime, night shift and weekend work',
              color: const Color(0xFF2E7D32),
              icon: Icons.workspace_premium,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BonusRulesScreen())),
            ),
            const SizedBox(height: 12),
            _policyCard(
              context,
              title: isAr ? 'قواعد البدلات' : 'Allowance Rules',
              subtitle: isAr ? 'البدلات الشهرية والشرائح والاستحقاق' : 'Allowances, tiers and eligibility',
              color: const Color(0xFFE65100),
              icon: Icons.attach_money,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllowanceRulesScreen())),
            ),
            const SizedBox(height: 12),
            _policyCard(
              context,
              title: isAr ? 'قواعد الإجازات' : 'Leave Rules',
              subtitle: isAr ? 'السنوية والمرضية والطوارئ والأمومة...' : 'Annual, sick, emergency, maternity...',
              color: const Color(0xFF382483),
              icon: Icons.event_available,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveRulesScreen())),
            ),
            const SizedBox(height: 12),
            _policyCard(
              context,
              title: isAr ? 'الإدخالات اليدوية' : 'Manual Entries',
              subtitle: isAr ? 'جزاءات ومكافآت وبدلات يدوية مع الموافقات' : 'Manual penalties, bonuses and allowances',
              color: const Color(0xFF37474F),
              icon: Icons.fact_check,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManualEntriesScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _policyCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withAlpha(30),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[500], size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
