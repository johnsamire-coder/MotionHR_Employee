import 'dart:io';

void main() async {
  final libPath = 'lib/screens';
  final dir = Directory(libPath);
  int totalUpdated = 0;

  final replacements = {
    // Payroll
    "'نظام الرواتب'": "isAr ? 'نظام الرواتب' : 'Payroll System'",
    "'ملخص الرواتب الشهري'": "isAr ? 'ملخص الرواتب الشهري' : 'Monthly Payroll Summary'",
    "'إعدادات حساب الرواتب'": "isAr ? 'إعدادات حساب الرواتب' : 'Payroll Settings'",
    "'الملخص المالي'": "isAr ? 'الملخص المالي' : 'Financial Summary'",
    "'ملخص الرواتب'": "isAr ? 'ملخص الرواتب' : 'Payroll Summary'",
    "'إعدادات الرواتب'": "isAr ? 'إعدادات الرواتب' : 'Payroll Settings'",
    "'لا يوجد موظفين لعرضهم'": "isAr ? 'لا يوجد موظفين لعرضهم' : 'No employees found'",
    "'عدد الموظفين'": "isAr ? 'عدد الموظفين' : 'Total Employees'",
    "'إجمالي الرواتب'": "isAr ? 'إجمالي الرواتب' : 'Total Salary'",
    "'صافي الرواتب'": "isAr ? 'صافي الرواتب' : 'Net Salary'",
    "'خصم التأخير'": "isAr ? 'خصم التأخير' : 'Late Deduction'",
    "'خصم الغياب'": "isAr ? 'خصم الغياب' : 'Absence Deduction'",

    // Reports
    "'تقارير المدير'": "isAr ? 'تقارير المدير' : 'Manager Reports'",
    "'تقرير الحضور الشهري'": "isAr ? 'تقرير الحضور الشهري' : 'Monthly Attendance Report'",
    "'تقرير التأخير'": "isAr ? 'تقرير التأخير' : 'Late Report'",
    "'تقرير الغياب'": "isAr ? 'تقرير الغياب' : 'Absence Report'",
    "'تقرير الإجازات'": "isAr ? 'تقرير الإجازات' : 'Leaves Report'",
    "'تقرير الطلبات'": "isAr ? 'تقرير الطلبات' : 'Requests Report'",
    "'تقرير ساعات العمل'": "isAr ? 'تقرير ساعات العمل' : 'Work Hours Report'",
    "'تقرير المواقع اليومي'": "isAr ? 'تقرير المواقع اليومي' : 'Daily Location Report'",
    "'تصدير PDF'": "isAr ? 'تصدير PDF' : 'Export PDF'",
    "'تصدير Excel'": "isAr ? 'تصدير Excel' : 'Export Excel'",
    "'طباعة'": "isAr ? 'طباعة' : 'Print'",

    // Profile
    "'الملف الشخصي'": "isAr ? 'الملف الشخصي' : 'Profile'",
    "'البيانات الشخصية'": "isAr ? 'البيانات الشخصية' : 'Personal Info'",
    "'البيانات الوظيفية'": "isAr ? 'البيانات الوظيفية' : 'Job Info'",
    "'البيانات البنكية'": "isAr ? 'البيانات البنكية' : 'Bank Info'",
    "'تغيير كلمة المرور'": "isAr ? 'تغيير كلمة المرور' : 'Change Password'",
    "'كلمة المرور الحالية'": "isAr ? 'كلمة المرور الحالية' : 'Current Password'",
    "'كلمة المرور الجديدة'": "isAr ? 'كلمة المرور الجديدة' : 'New Password'",
    "'تأكيد كلمة المرور'": "isAr ? 'تأكيد كلمة المرور' : 'Confirm Password'",

    // Employee
    "'تعديل بيانات الموظف'": "isAr ? 'تعديل بيانات الموظف' : 'Edit Employee'",
    "'تفاصيل الموظف'": "isAr ? 'تفاصيل الموظف' : 'Employee Details'",
    "'نقل الموظف'": "isAr ? 'نقل الموظف' : 'Transfer Employee'",
    "'إعادة تعيين كلمة المرور'": "isAr ? 'إعادة تعيين كلمة المرور' : 'Reset Password'",
    "'قائمة الموظفين'": "isAr ? 'قائمة الموظفين' : 'Employees List'",
    "'لا يوجد موظفون'": "isAr ? 'لا يوجد موظفون' : 'No employees found'",
    "'إنشاء موظف جديد'": "isAr ? 'إنشاء موظف جديد' : 'Create New Employee'",
    "'بيانات الوظيفة'": "isAr ? 'بيانات الوظيفة' : 'Job Details'",
    "'بيانات التواصل'": "isAr ? 'بيانات التواصل' : 'Contact Info'",
    "'بيانات حساب الدخول'": "isAr ? 'بيانات حساب الدخول' : 'Login Credentials'",
    "'ملخص المراجعة'": "isAr ? 'ملخص المراجعة' : 'Review Summary'",

    // Missions
    "'إدارة المهمات'": "isAr ? 'إدارة المهمات' : 'Missions Management'",
    "'مهمة جديدة'": "isAr ? 'مهمة جديدة' : 'New Mission'",
    "'تفاصيل المهمة'": "isAr ? 'تفاصيل المهمة' : 'Mission Details'",
    "'إنشاء مهمة جديدة'": "isAr ? 'إنشاء مهمة جديدة' : 'Create New Mission'",
    "'بدء المهمة'": "isAr ? 'بدء المهمة' : 'Start Mission'",
    "'إنهاء المهمة'": "isAr ? 'إنهاء المهمة' : 'End Mission'",
    "'فيدباك الزيارة'": "isAr ? 'فيدباك الزيارة' : 'Visit Feedback'",
    "'لا توجد مهمات'": "isAr ? 'لا توجد مهمات' : 'No missions found'",
    "'المشاركون'": "isAr ? 'المشاركون' : 'Participants'",
    "'طلب الانسحاب'": "isAr ? 'طلب الانسحاب' : 'Withdraw Request'",
    "'إلغاء المهمة'": "isAr ? 'إلغاء المهمة' : 'Cancel Mission'",

    // Requests & Leaves
    "'لا توجد طلبات'": "isAr ? 'لا توجد طلبات' : 'No requests found'",
    "'لا يوجد طلبات'": "isAr ? 'لا يوجد طلبات' : 'No requests found'",
    "'طلب إجازة'": "isAr ? 'طلب إجازة' : 'Request Leave'",
    "'إلغاء الطلب'": "isAr ? 'إلغاء الطلب' : 'Cancel Request'",
    "'من تاريخ'": "isAr ? 'من تاريخ' : 'From Date'",
    "'إلى تاريخ'": "isAr ? 'إلى تاريخ' : 'To Date'",

    // Status
    "'نشط'": "isAr ? 'نشط' : 'Active'",
    "'موافق عليه'": "isAr ? 'موافق عليه' : 'Approved'",
    "'مرفوض'": "isAr ? 'مرفوض' : 'Rejected'",
    "'ملغي'": "isAr ? 'ملغي' : 'Cancelled'",
    "'في الانتظار'": "isAr ? 'في الانتظار' : 'Pending'",
    "'جارية'": "isAr ? 'جارية' : 'In Progress'",
    "'مكتملة'": "isAr ? 'مكتملة' : 'Completed'",
    "'الكل'": "isAr ? 'الكل' : 'All'",

    // General
    "'جاري التحميل...'": "isAr ? 'جاري التحميل...' : 'Loading...'",
    "'جارٍ التحميل...'": "isAr ? 'جارٍ التحميل...' : 'Loading...'",
    "'لا توجد بيانات'": "isAr ? 'لا توجد بيانات' : 'No data'",
    "'حدث خطأ'": "isAr ? 'حدث خطأ' : 'An error occurred'",
    "'إعادة المحاولة'": "isAr ? 'إعادة المحاولة' : 'Retry'",
    "'تم بنجاح'": "isAr ? 'تم بنجاح' : 'Success'",
    "'بحث'": "isAr ? 'بحث' : 'Search'",
    "'تحديث'": "isAr ? 'تحديث' : 'Refresh'",
    "'حفظ'": "isAr ? 'حفظ' : 'Save'",
    "'إلغاء'": "isAr ? 'إلغاء' : 'Cancel'",
    "'تأكيد'": "isAr ? 'تأكيد' : 'Confirm'",
    "'حذف'": "isAr ? 'حذف' : 'Delete'",
    "'تعديل'": "isAr ? 'تعديل' : 'Edit'",
    "'إضافة'": "isAr ? 'إضافة' : 'Add'",
    "'إرسال'": "isAr ? 'إرسال' : 'Send'",
    "'رجوع'": "isAr ? 'رجوع' : 'Back'",
    "'إغلاق'": "isAr ? 'إغلاق' : 'Close'",
    "'التالي'": "isAr ? 'التالي' : 'Next'",
    "'تم'": "isAr ? 'تم' : 'Done'",
    "'نعم'": "isAr ? 'نعم' : 'Yes'",
    "'الإعدادات'": "isAr ? 'الإعدادات' : 'Settings'",
    "'الإشعارات'": "isAr ? 'الإشعارات' : 'Notifications'",
    "'الرئيسية'": "isAr ? 'الرئيسية' : 'Home'",
    "'الموظفون'": "isAr ? 'الموظفون' : 'Employees'",
    "'التقارير'": "isAr ? 'التقارير' : 'Reports'",
    "'الرواتب'": "isAr ? 'الرواتب' : 'Payroll'",
    "'الإجازات'": "isAr ? 'الإجازات' : 'Leaves'",
    "'الطلبات'": "isAr ? 'الطلبات' : 'Requests'",
    "'طلباتي'": "isAr ? 'طلباتي' : 'My Requests'",
    "'إجازاتي'": "isAr ? 'إجازاتي' : 'My Leaves'",
  };

  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      var content = await entity.readAsString();
      final original = content;

      for (final entry in replacements.entries) {
        content = content.replaceAll(entry.key, entry.value);
      }

      if (content != original) {
        await entity.writeAsString(content);
        print('✅ ${entity.path.split('\\').last}');
        totalUpdated++;
      }
    }
  }

  print('\n✅ Done! Updated $totalUpdated files');
}