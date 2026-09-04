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
      '\u064A\u0646\u0627\u064A\u0631',
      '\u0641\u0628\u0631\u0627\u064A\u0631',
      '\u0645\u0627\u0631\u0633',
      '\u0623\u0628\u0631\u064A\u0644',
      '\u0645\u0627\u064A\u0648',
      '\u064A\u0648\u0646\u064A\u0648',
      '\u064A\u0648\u0644\u064A\u0648',
      '\u0623\u063A\u0633\u0637\u0633',
      '\u0633\u0628\u062A\u0645\u0628\u0631',
      '\u0623\u0643\u062A\u0648\u0628\u0631',
      '\u0646\u0648\u0641\u0645\u0628\u0631',
      '\u062F\u064A\u0633\u0645\u0628\u0631',
    ];
    const en = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return isAr ? ar[m - 1] : en[m - 1];
  }

  bool isFutureMonth(int month) {
    return tempYear > now.year ||
        (tempYear == now.year && month > now.month);
  }

  void normalizeMonthAfterYearChange(void Function(void Function()) setS, int nextYear) {
    setS(() {
      tempYear = nextYear;
      if (tempYear == now.year && tempMonth > now.month) {
        tempMonth = now.month;
      }
    });
  }

  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setS) {
          return SafeArea(
            child: FractionallySizedBox(
              heightFactor: 0.72,
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isAr
                          ? '\u0627\u062E\u062A\u0631 \u0627\u0644\u0634\u0647\u0631'
                          : 'Select Month',
                      textAlign: TextAlign.center,
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
                          onPressed: () =>
                              normalizeMonthAfterYearChange(setS, tempYear - 1),
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
                              ? () => normalizeMonthAfterYearChange(
                                  setS,
                                  tempYear + 1,
                                )
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: GridView.builder(
                        itemCount: 12,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemBuilder: (_, i) {
                          final m = i + 1;
                          final selected = tempMonth == m;
                          final disabled = isFutureMonth(m);

                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: disabled
                                ? null
                                : () => setS(() => tempMonth = m),
                            child: Container(
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFF382483)
                                    : disabled
                                        ? const Color(0xFFF1F5F9)
                                        : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFF382483)
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
                                  color: selected
                                      ? Colors.white
                                      : disabled
                                          ? Colors.grey
                                          : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              isAr
                                  ? '\u0625\u0644\u063A\u0627\u0621'
                                  : 'Cancel',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(
                                ctx,
                                DateTime(tempYear, tempMonth, 1),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF382483),
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              isAr
                                  ? '\u062A\u0623\u0643\u064A\u062F'
                                  : 'Confirm',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
