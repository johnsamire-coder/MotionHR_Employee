import 'package:flutter/material.dart';
import 'attendance_policy_screen.dart';
import 'payroll_policy_screen.dart';
import 'leave_policy_screen.dart';
import 'official_holidays_screen.dart';
import 'payroll/tax_policy_screen.dart';
import 'payroll/eos_policy_screen.dart';
import 'payroll/insurance_policies_screen.dart';

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
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
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
              subtitle: isAr
                  ? 'التأخير والغياب والأذونات'
                  : 'Late, absence and permissions',
              color: const Color(0xFF1565C0),
              icon: Icons.policy,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AttendancePolicyScreen(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _policyCard(
              context,
              title: isAr ? 'سياسات المرتبات' : 'Payroll Policies',
              subtitle: isAr
                  ? 'الأوفر تايم والبدلات والجزاءات'
                  : 'Overtime, allowances and disciplinary',
              color: const Color(0xFF2E7D32),
              icon: Icons.monetization_on,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PayrollPolicyScreen(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _policyCard(
              context,
              title: isAr ? 'سياسات الإجازات' : 'Leave Policies',
              subtitle: isAr
                  ? 'الاستحقاق والترحيل والأرصدة'
                  : 'Entitlement, carry forward and balances',
              color: const Color(0xFF1B5E20),
              icon: Icons.beach_access,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LeavePolicyScreen(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _policyCard(
              context,
              title: isAr ? 'الإجازات الرسمية' : 'Official Holidays',
              subtitle: isAr
                  ? 'أيام الأعياد والعطل الرسمية ومعاملتها في الرواتب'
                  : 'Public holidays and their payroll treatment',
              color: const Color(0xFF6A1B9A),
              icon: Icons.celebration,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OfficialHolidaysScreen(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _policyCard(
              context,
              title: isAr ? '????? ???????' : 'Tax Policy',
              subtitle: isAr
                  ? '??????? ???????? ?????????? ???????'
                  : 'Tax brackets and personal exemptions',
              color: const Color(0xFFE65100),
              icon: Icons.receipt_long,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TaxPolicyScreen(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _policyCard(
              context,
              title: isAr ? '?????? ????? ??????' : 'End of Service',
              subtitle: isAr
                  ? '????? ?????? ???? ?????????'
                  : 'Service tiers and entitlement rates',
              color: const Color(0xFFF57C00),
              icon: Icons.card_giftcard,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EosPolicyScreen(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _policyCard(
              context,
              title: isAr ? '?????????' : 'Insurance',
              subtitle: isAr
                  ? '??????? ????????? ??????'
                  : 'Social and medical insurance',
              color: const Color(0xFF00838F),
              icon: Icons.shield,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const InsurancePoliciesScreen(),
                ),
              ),
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
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: Colors.grey[500], size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
