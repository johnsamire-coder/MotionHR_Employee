import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _keyLanguage = 'app_language';
  static const String _defaultLanguage = 'ar';

  static final ValueNotifier<Locale> currentLocale = ValueNotifier(const Locale('ar'));

  // تحميل اللغة المحفوظة عند فتح التطبيق
  static Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_keyLanguage) ?? _defaultLanguage;
    currentLocale.value = Locale(lang);
  }

  // تغيير اللغة
  static Future<void> changeLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, languageCode);
    currentLocale.value = Locale(languageCode);
  }

  // اللغة الحالية
  static String get currentLanguage => currentLocale.value.languageCode;

  // فحص العربية
  static bool get isArabic => currentLocale.value.languageCode == 'ar';

  // اسم اللغة
  static String getLanguageName(String code) {
    switch (code) {
      case 'ar':
        return 'العربية';
      case 'en':
        return 'English';
      default:
        return code;
    }
  }
}

// ── الترجمات ──
class AppStrings {
  static final Map<String, Map<String, String>> _translations = {
    'ar': {
      // عام
      'app_name': 'MotionHR',
      'login': 'دخول',
      'logout': 'تسجيل الخروج',
      'username': 'اسم المستخدم',
      'password': 'كلمة المرور',
      'remember_me': 'تذكرني',
      'stay_logged_in': 'البقاء مسجلاً',
      'forgot_password': 'نسيت كلمة المرور؟',
      'welcome': 'مرحباً بك، سجل دخولك للمتابعة',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'confirm': 'تأكيد',
      'delete': 'حذف',
      'edit': 'تعديل',
      'add': 'إضافة',
      'search': 'بحث',
      'refresh': 'تحديث',
      'loading': 'جاري التحميل...',
      'error': 'خطأ',
      'success': 'تم بنجاح',
      'no_data': 'لا توجد بيانات',
      'language': 'اللغة',
      'settings': 'الإعدادات',
      'change_language': 'تغيير اللغة',

      // الداشبورد
      'dashboard': 'لوحة التحكم',
      'quick_management': 'الإدارة السريعة',
      'tools': 'الأدوات',
      'pending_requests': 'الطلبات المعلقة',
      'attendance_today': 'الحضور اليوم',
      'field_workers': 'الموظفين الميدانيين',
      'live_locations': 'المواقع المباشرة',
      'employees': 'الموظفين',
      'add_employee': 'إضافة موظف',
      'announcements': 'الإعلانات',
      'reports': 'التقارير',
      'payroll': 'الرواتب',
      'reminders': 'التذكيرات',
      'company_charter': 'لائحة الشركة',
      'geofence': 'نطاق الجيو',

      // الموظف
      'employee_code': 'الرقم الوظيفي',
      'full_name': 'الاسم الكامل',
      'first_name': 'الاسم الأول',
      'last_name': 'الاسم الأخير',
      'middle_name': 'الاسم الأوسط',
      'first_name_ar': 'الاسم الأول بالعربي',
      'last_name_ar': 'الاسم الأخير بالعربي',
      'first_name_en': 'الاسم الأول بالإنجليزي',
      'last_name_en': 'الاسم الأخير بالإنجليزي',
      'phone': 'الموبايل',
      'email': 'البريد الإلكتروني',
      'national_id': 'الرقم القومي',
      'birth_date': 'تاريخ الميلاد',
      'gender': 'النوع',
      'male': 'ذكر',
      'female': 'أنثى',
      'address': 'العنوان',
      'branch': 'الفرع',
      'department': 'الإدارة',
      'job_title': 'المسمى الوظيفي',
      'direct_manager': 'المدير المباشر',
      'hire_date': 'تاريخ التعيين',
      'basic_salary': 'الراتب الأساسي',
      'reset_password': 'إعادة تعيين كلمة المرور',

      // الحالات
      'active': 'نشط',
      'on_leave': 'في إجازة',
      'suspended': 'موقوف',
      'resigned': 'مستقيل',
      'terminated': 'مفصول',
      'required': 'مطلوب',
    },

    'en': {
      // General
      'app_name': 'MotionHR',
      'login': 'Login',
      'logout': 'Logout',
      'username': 'Username',
      'password': 'Password',
      'remember_me': 'Remember me',
      'stay_logged_in': 'Stay logged in',
      'forgot_password': 'Forgot password?',
      'welcome': 'Welcome, sign in to continue',
      'save': 'Save',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'search': 'Search',
      'refresh': 'Refresh',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'no_data': 'No data',
      'language': 'Language',
      'settings': 'Settings',
      'change_language': 'Change language',

      // Dashboard
      'dashboard': 'Dashboard',
      'quick_management': 'Quick Management',
      'tools': 'Tools',
      'pending_requests': 'Pending Requests',
      'attendance_today': 'Today Attendance',
      'field_workers': 'Field Workers',
      'live_locations': 'Live Locations',
      'employees': 'Employees',
      'add_employee': 'Add Employee',
      'announcements': 'Announcements',
      'reports': 'Reports',
      'payroll': 'Payroll',
      'reminders': 'Reminders',
      'company_charter': 'Company Charter',
      'geofence': 'Geofence',

      // Employee
      'employee_code': 'Employee Code',
      'full_name': 'Full Name',
      'first_name': 'First Name',
      'last_name': 'Last Name',
      'middle_name': 'Middle Name',
      'first_name_ar': 'First Name (Arabic)',
      'last_name_ar': 'Last Name (Arabic)',
      'first_name_en': 'First Name (English)',
      'last_name_en': 'Last Name (English)',
      'phone': 'Phone',
      'email': 'Email',
      'national_id': 'National ID',
      'birth_date': 'Birth Date',
      'gender': 'Gender',
      'male': 'Male',
      'female': 'Female',
      'address': 'Address',
      'branch': 'Branch',
      'department': 'Department',
      'job_title': 'Job Title',
      'direct_manager': 'Direct Manager',
      'hire_date': 'Hire Date',
      'basic_salary': 'Basic Salary',
      'reset_password': 'Reset Password',

      // Status
      'active': 'Active',
      'on_leave': 'On Leave',
      'suspended': 'Suspended',
      'resigned': 'Resigned',
      'terminated': 'Terminated',
      'required': 'Required',
    },
  };

  static String get(String key) {
    final lang = LanguageService.currentLanguage;
    return _translations[lang]?[key] ?? _translations['ar']?[key] ?? key;
  }

  static String tr(String key) => get(key);
}