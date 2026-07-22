import 'package:flutter/material.dart';

Future<DateTime?> showReportMonthPicker(
  BuildContext context, {
  required int initialYear,
  required int initialMonth,
}) async {
  final isAr = Localizations.localeOf(context).languageCode == 'ar';
  final now = DateTime.now();

  int tempYear = initialYear;
  int tempMonth = initialMonth;

  String monthName(int m) {
    const ar = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    const en = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return isAr ? ar[m - 1] : en[m - 1];
  }

  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  isAr ? 'اختر الشهر' : 'Select Month',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setS(() => tempYear--),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$tempYear',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: tempYear < now.year
                          ? () => setS(() => tempYear++)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 12,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (_, i) {
                    final m = i + 1;
                    final selected = tempMonth == m;

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setS(() => tempMonth = m),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF6A1B9A)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF6A1B9A)
                                : Colors.grey.shade300,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          monthName(m),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(isAr ? 'إلغاء' : 'Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx, DateTime(tempYear, tempMonth, 1));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A1B9A),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(isAr ? 'تأكيد' : 'Confirm'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
