// lib/widgets/account_incomplete_screen.dart
import 'package:flutter/material.dart';

/// شاشة/Widget بيظهر لو الموظف عنده بيانات ناقصة
/// (worker_type أو الشيفت)
class AccountIncompleteWidget extends StatelessWidget {
  final List<String> missing;
  final String message;

  const AccountIncompleteWidget({
    super.key,
    required this.missing,
    required this.message,
  });

  bool get _needsWorkerType => missing.contains('worker_type');
  bool get _needsShift => missing.contains('shift');

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.orange.shade50, Colors.red.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ar ? 'بياناتك ناقصة' : 'Your Account is Incomplete',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                      ),
                    ),
                    Text(
                      ar
                          ? 'لا يمكنك استخدام التطبيق الآن'
                          : 'You cannot use the app now',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            ar ? 'المطلوب:' : 'Required:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          if (_needsWorkerType)
            _buildMissingItem(
              icon: Icons.person_pin,
              color: Colors.blue,
              title: ar ? 'تحديد نوع الموظف' : 'Set Worker Type',
              subtitle: ar
                  ? 'مكتبي / ميداني حر / ميداني محدد'
                  : 'Office / Field Free / Field Assigned',
            ),
          if (_needsShift)
            _buildMissingItem(
              icon: Icons.schedule,
              color: Colors.purple,
              title: ar ? 'ربط شيفت' : 'Assign Shift',
              subtitle: ar
                  ? 'تحديد ساعات العمل الرسمية'
                  : 'Set official working hours',
            ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.support_agent, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ar
                            ? 'تواصل مع الموارد البشرية'
                            : 'Contact Human Resources',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ar
                      ? 'الـ HR هيحدد بياناتك عشان تقدر تستخدم التطبيق. تم إرسال إشعار تلقائي لهم بحالتك.'
                      : 'HR will complete your data so you can use the app. An automatic notification has been sent.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
        ],
      ),
    );
  }
}
