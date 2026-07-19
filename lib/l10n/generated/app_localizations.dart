import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'MotionHR'**
  String get appName;

  /// No description provided for @ok.
  ///
  /// In ar, this message translates to:
  /// **'موافق'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get back;

  /// No description provided for @next.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In ar, this message translates to:
  /// **'تخطي'**
  String get skip;

  /// No description provided for @done.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get done;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get refresh;

  /// No description provided for @search.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In ar, this message translates to:
  /// **'فلتر'**
  String get filter;

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// No description provided for @yes.
  ///
  /// In ar, this message translates to:
  /// **'نعم'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In ar, this message translates to:
  /// **'لا'**
  String get no;

  /// No description provided for @loading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحميل...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In ar, this message translates to:
  /// **'خطأ'**
  String get error;

  /// No description provided for @success.
  ///
  /// In ar, this message translates to:
  /// **'تم بنجاح'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In ar, this message translates to:
  /// **'تحذير'**
  String get warning;

  /// No description provided for @noData.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بيانات'**
  String get noData;

  /// No description provided for @noResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج'**
  String get noResults;

  /// No description provided for @required.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحقل مطلوب'**
  String get required;

  /// No description provided for @optional.
  ///
  /// In ar, this message translates to:
  /// **'اختياري'**
  String get optional;

  /// No description provided for @send.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get send;

  /// No description provided for @upload.
  ///
  /// In ar, this message translates to:
  /// **'رفع'**
  String get upload;

  /// No description provided for @download.
  ///
  /// In ar, this message translates to:
  /// **'تحميل'**
  String get download;

  /// No description provided for @share.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get share;

  /// No description provided for @print.
  ///
  /// In ar, this message translates to:
  /// **'طباعة'**
  String get print;

  /// No description provided for @export.
  ///
  /// In ar, this message translates to:
  /// **'تصدير'**
  String get export;

  /// No description provided for @import.
  ///
  /// In ar, this message translates to:
  /// **'استيراد'**
  String get import;

  /// No description provided for @add.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get add;

  /// No description provided for @remove.
  ///
  /// In ar, this message translates to:
  /// **'إزالة'**
  String get remove;

  /// No description provided for @update.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get update;

  /// No description provided for @create.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء'**
  String get create;

  /// No description provided for @view.
  ///
  /// In ar, this message translates to:
  /// **'عرض'**
  String get view;

  /// No description provided for @details.
  ///
  /// In ar, this message translates to:
  /// **'التفاصيل'**
  String get details;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logout;

  /// No description provided for @profile.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get profile;

  /// No description provided for @notifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notifications;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @arabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In ar, this message translates to:
  /// **'الإنجليزية'**
  String get english;

  /// No description provided for @selectLanguage.
  ///
  /// In ar, this message translates to:
  /// **'اختر اللغة'**
  String get selectLanguage;

  /// No description provided for @languageChanged.
  ///
  /// In ar, this message translates to:
  /// **'تم تغيير اللغة بنجاح'**
  String get languageChanged;

  /// No description provided for @chooseAppLanguage.
  ///
  /// In ar, this message translates to:
  /// **'اختر لغة التطبيق'**
  String get chooseAppLanguage;

  /// No description provided for @continueBtn.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get continueBtn;

  /// No description provided for @login.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get login;

  /// No description provided for @username.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم'**
  String get username;

  /// No description provided for @password.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get password;

  /// No description provided for @rememberMe.
  ///
  /// In ar, this message translates to:
  /// **'تذكرني'**
  String get rememberMe;

  /// No description provided for @stayLoggedIn.
  ///
  /// In ar, this message translates to:
  /// **'البقاء مسجلاً لـ 72 ساعة'**
  String get stayLoggedIn;

  /// No description provided for @forgotPassword.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get forgotPassword;

  /// No description provided for @loginButton.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get loginButton;

  /// No description provided for @loggingIn.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الدخول...'**
  String get loggingIn;

  /// No description provided for @loginFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل تسجيل الدخول'**
  String get loginFailed;

  /// No description provided for @invalidCredentials.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم أو كلمة المرور غير صحيحة'**
  String get invalidCredentials;

  /// No description provided for @usernameRequired.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال اسم المستخدم'**
  String get usernameRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال كلمة المرور'**
  String get passwordRequired;

  /// No description provided for @welcomeBack.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً بعودتك'**
  String get welcomeBack;

  /// No description provided for @loginToAccount.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك إلى حسابك'**
  String get loginToAccount;

  /// No description provided for @changeLanguage.
  ///
  /// In ar, this message translates to:
  /// **'تغيير اللغة'**
  String get changeLanguage;

  /// No description provided for @dashboard.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get dashboard;

  /// No description provided for @home.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get home;

  /// No description provided for @welcome.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً'**
  String get welcome;

  /// No description provided for @today.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get today;

  /// No description provided for @date.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get date;

  /// No description provided for @time.
  ///
  /// In ar, this message translates to:
  /// **'الوقت'**
  String get time;

  /// No description provided for @totalEmployees.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الموظفين'**
  String get totalEmployees;

  /// No description provided for @presentToday.
  ///
  /// In ar, this message translates to:
  /// **'الحاضرون اليوم'**
  String get presentToday;

  /// No description provided for @absentToday.
  ///
  /// In ar, this message translates to:
  /// **'الغائبون اليوم'**
  String get absentToday;

  /// No description provided for @pendingRequests.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات المعلقة'**
  String get pendingRequests;

  /// No description provided for @quickActions.
  ///
  /// In ar, this message translates to:
  /// **'إجراءات سريعة'**
  String get quickActions;

  /// No description provided for @tools.
  ///
  /// In ar, this message translates to:
  /// **'الأدوات'**
  String get tools;

  /// No description provided for @management.
  ///
  /// In ar, this message translates to:
  /// **'الإدارة'**
  String get management;

  /// No description provided for @attendance.
  ///
  /// In ar, this message translates to:
  /// **'الحضور والانصراف'**
  String get attendance;

  /// No description provided for @checkIn.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الحضور'**
  String get checkIn;

  /// No description provided for @checkOut.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الانصراف'**
  String get checkOut;

  /// No description provided for @checkInTime.
  ///
  /// In ar, this message translates to:
  /// **'وقت الحضور'**
  String get checkInTime;

  /// No description provided for @checkOutTime.
  ///
  /// In ar, this message translates to:
  /// **'وقت الانصراف'**
  String get checkOutTime;

  /// No description provided for @attendanceHistory.
  ///
  /// In ar, this message translates to:
  /// **'سجل الحضور'**
  String get attendanceHistory;

  /// No description provided for @attendanceReport.
  ///
  /// In ar, this message translates to:
  /// **'تقرير الحضور'**
  String get attendanceReport;

  /// No description provided for @alreadyCheckedIn.
  ///
  /// In ar, this message translates to:
  /// **'لقد سجلت حضورك بالفعل'**
  String get alreadyCheckedIn;

  /// No description provided for @alreadyCheckedOut.
  ///
  /// In ar, this message translates to:
  /// **'لقد سجلت انصرافك بالفعل'**
  String get alreadyCheckedOut;

  /// No description provided for @notCheckedIn.
  ///
  /// In ar, this message translates to:
  /// **'لم تسجل حضورك بعد'**
  String get notCheckedIn;

  /// No description provided for @checkInSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الحضور بنجاح'**
  String get checkInSuccess;

  /// No description provided for @checkOutSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الانصراف بنجاح'**
  String get checkOutSuccess;

  /// No description provided for @activeMissionCheckout.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن الانصراف - لديك مهمة نشطة'**
  String get activeMissionCheckout;

  /// No description provided for @workingHours.
  ///
  /// In ar, this message translates to:
  /// **'ساعات العمل'**
  String get workingHours;

  /// No description provided for @overtime.
  ///
  /// In ar, this message translates to:
  /// **'وقت إضافي'**
  String get overtime;

  /// No description provided for @late.
  ///
  /// In ar, this message translates to:
  /// **'متأخر'**
  String get late;

  /// No description provided for @earlyLeave.
  ///
  /// In ar, this message translates to:
  /// **'مغادرة مبكرة'**
  String get earlyLeave;

  /// No description provided for @absent.
  ///
  /// In ar, this message translates to:
  /// **'غائب'**
  String get absent;

  /// No description provided for @present.
  ///
  /// In ar, this message translates to:
  /// **'حاضر'**
  String get present;

  /// No description provided for @onLeave.
  ///
  /// In ar, this message translates to:
  /// **'في إجازة'**
  String get onLeave;

  /// No description provided for @onMission.
  ///
  /// In ar, this message translates to:
  /// **'في مهمة'**
  String get onMission;

  /// No description provided for @employees.
  ///
  /// In ar, this message translates to:
  /// **'الموظفون'**
  String get employees;

  /// No description provided for @employee.
  ///
  /// In ar, this message translates to:
  /// **'موظف'**
  String get employee;

  /// No description provided for @employeeList.
  ///
  /// In ar, this message translates to:
  /// **'قائمة الموظفين'**
  String get employeeList;

  /// No description provided for @employeeDetails.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الموظف'**
  String get employeeDetails;

  /// No description provided for @addEmployee.
  ///
  /// In ar, this message translates to:
  /// **'إضافة موظف'**
  String get addEmployee;

  /// No description provided for @editEmployee.
  ///
  /// In ar, this message translates to:
  /// **'تعديل بيانات الموظف'**
  String get editEmployee;

  /// No description provided for @deleteEmployee.
  ///
  /// In ar, this message translates to:
  /// **'حذف الموظف'**
  String get deleteEmployee;

  /// No description provided for @searchEmployees.
  ///
  /// In ar, this message translates to:
  /// **'بحث في الموظفين'**
  String get searchEmployees;

  /// No description provided for @noEmployees.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد موظفون'**
  String get noEmployees;

  /// No description provided for @employeeId.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموظف'**
  String get employeeId;

  /// No description provided for @employeeName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الموظف'**
  String get employeeName;

  /// No description provided for @nameAr.
  ///
  /// In ar, this message translates to:
  /// **'الاسم بالعربية'**
  String get nameAr;

  /// No description provided for @nameEn.
  ///
  /// In ar, this message translates to:
  /// **'الاسم بالإنجليزية'**
  String get nameEn;

  /// No description provided for @firstNameAr.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الأول بالعربية'**
  String get firstNameAr;

  /// No description provided for @lastNameAr.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الأخير بالعربية'**
  String get lastNameAr;

  /// No description provided for @firstNameEn.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الأول بالإنجليزية'**
  String get firstNameEn;

  /// No description provided for @lastNameEn.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الأخير بالإنجليزية'**
  String get lastNameEn;

  /// No description provided for @jobTitle.
  ///
  /// In ar, this message translates to:
  /// **'المسمى الوظيفي'**
  String get jobTitle;

  /// No description provided for @department.
  ///
  /// In ar, this message translates to:
  /// **'القسم'**
  String get department;

  /// No description provided for @branch.
  ///
  /// In ar, this message translates to:
  /// **'الفرع'**
  String get branch;

  /// No description provided for @directManager.
  ///
  /// In ar, this message translates to:
  /// **'المدير المباشر'**
  String get directManager;

  /// No description provided for @phone.
  ///
  /// In ar, this message translates to:
  /// **'الهاتف'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get email;

  /// No description provided for @nationalId.
  ///
  /// In ar, this message translates to:
  /// **'الرقم القومي'**
  String get nationalId;

  /// No description provided for @hireDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ التعيين'**
  String get hireDate;

  /// No description provided for @salary.
  ///
  /// In ar, this message translates to:
  /// **'الراتب'**
  String get salary;

  /// No description provided for @currency.
  ///
  /// In ar, this message translates to:
  /// **'العملة'**
  String get currency;

  /// No description provided for @status.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get status;

  /// No description provided for @active.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In ar, this message translates to:
  /// **'غير نشط'**
  String get inactive;

  /// No description provided for @gender.
  ///
  /// In ar, this message translates to:
  /// **'الجنس'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In ar, this message translates to:
  /// **'ذكر'**
  String get male;

  /// No description provided for @female.
  ///
  /// In ar, this message translates to:
  /// **'أنثى'**
  String get female;

  /// No description provided for @birthDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الميلاد'**
  String get birthDate;

  /// No description provided for @address.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get address;

  /// No description provided for @resetPassword.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعيين كلمة المرور'**
  String get resetPassword;

  /// No description provided for @newPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الجديدة'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور'**
  String get confirmPassword;

  /// No description provided for @passwordMismatch.
  ///
  /// In ar, this message translates to:
  /// **'كلمتا المرور غير متطابقتان'**
  String get passwordMismatch;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إعادة تعيين كلمة المرور'**
  String get passwordResetSuccess;

  /// No description provided for @copyPassword.
  ///
  /// In ar, this message translates to:
  /// **'نسخ كلمة المرور'**
  String get copyPassword;

  /// No description provided for @passwordCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ كلمة المرور'**
  String get passwordCopied;

  /// No description provided for @transferEmployee.
  ///
  /// In ar, this message translates to:
  /// **'نقل الموظف'**
  String get transferEmployee;

  /// No description provided for @transferSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم نقل الموظف بنجاح'**
  String get transferSuccess;

  /// No description provided for @selectDepartment.
  ///
  /// In ar, this message translates to:
  /// **'اختر القسم'**
  String get selectDepartment;

  /// No description provided for @selectBranch.
  ///
  /// In ar, this message translates to:
  /// **'اختر الفرع'**
  String get selectBranch;

  /// No description provided for @selectJobTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر المسمى الوظيفي'**
  String get selectJobTitle;

  /// No description provided for @selectManager.
  ///
  /// In ar, this message translates to:
  /// **'اختر المدير'**
  String get selectManager;

  /// No description provided for @createEmployee.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء موظف جديد'**
  String get createEmployee;

  /// No description provided for @employeeCreated.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء الموظف بنجاح'**
  String get employeeCreated;

  /// No description provided for @employeeUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث بيانات الموظف'**
  String get employeeUpdated;

  /// No description provided for @suggestedUsername.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم المقترح'**
  String get suggestedUsername;

  /// No description provided for @usernameHint.
  ///
  /// In ar, this message translates to:
  /// **'سيتم توليده تلقائياً'**
  String get usernameHint;

  /// No description provided for @leaves.
  ///
  /// In ar, this message translates to:
  /// **'الإجازات'**
  String get leaves;

  /// No description provided for @leave.
  ///
  /// In ar, this message translates to:
  /// **'إجازة'**
  String get leave;

  /// No description provided for @leaveRequest.
  ///
  /// In ar, this message translates to:
  /// **'طلب إجازة'**
  String get leaveRequest;

  /// No description provided for @leaveRequests.
  ///
  /// In ar, this message translates to:
  /// **'طلبات الإجازات'**
  String get leaveRequests;

  /// No description provided for @myLeaves.
  ///
  /// In ar, this message translates to:
  /// **'إجازاتي'**
  String get myLeaves;

  /// No description provided for @leaveType.
  ///
  /// In ar, this message translates to:
  /// **'نوع الإجازة'**
  String get leaveType;

  /// No description provided for @leaveBalance.
  ///
  /// In ar, this message translates to:
  /// **'رصيد الإجازات'**
  String get leaveBalance;

  /// No description provided for @leaveFrom.
  ///
  /// In ar, this message translates to:
  /// **'من تاريخ'**
  String get leaveFrom;

  /// No description provided for @leaveTo.
  ///
  /// In ar, this message translates to:
  /// **'إلى تاريخ'**
  String get leaveTo;

  /// No description provided for @leaveDays.
  ///
  /// In ar, this message translates to:
  /// **'عدد الأيام'**
  String get leaveDays;

  /// No description provided for @leaveReason.
  ///
  /// In ar, this message translates to:
  /// **'سبب الإجازة'**
  String get leaveReason;

  /// No description provided for @leaveStatus.
  ///
  /// In ar, this message translates to:
  /// **'حالة الطلب'**
  String get leaveStatus;

  /// No description provided for @pending.
  ///
  /// In ar, this message translates to:
  /// **'معلق'**
  String get pending;

  /// No description provided for @approved.
  ///
  /// In ar, this message translates to:
  /// **'موافق عليه'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In ar, this message translates to:
  /// **'مرفوض'**
  String get rejected;

  /// No description provided for @cancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغي'**
  String get cancelled;

  /// No description provided for @approveLeave.
  ///
  /// In ar, this message translates to:
  /// **'قبول الإجازة'**
  String get approveLeave;

  /// No description provided for @rejectLeave.
  ///
  /// In ar, this message translates to:
  /// **'رفض الإجازة'**
  String get rejectLeave;

  /// No description provided for @annualLeave.
  ///
  /// In ar, this message translates to:
  /// **'إجازة سنوية'**
  String get annualLeave;

  /// No description provided for @sickLeave.
  ///
  /// In ar, this message translates to:
  /// **'إجازة مرضية'**
  String get sickLeave;

  /// No description provided for @unpaidLeave.
  ///
  /// In ar, this message translates to:
  /// **'إجازة بدون راتب'**
  String get unpaidLeave;

  /// No description provided for @emergencyLeave.
  ///
  /// In ar, this message translates to:
  /// **'إجازة طارئة'**
  String get emergencyLeave;

  /// No description provided for @maternityLeave.
  ///
  /// In ar, this message translates to:
  /// **'إجازة أمومة'**
  String get maternityLeave;

  /// No description provided for @paternityLeave.
  ///
  /// In ar, this message translates to:
  /// **'إجازة أبوة'**
  String get paternityLeave;

  /// No description provided for @noLeaveRequests.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات إجازة'**
  String get noLeaveRequests;

  /// No description provided for @remainingDays.
  ///
  /// In ar, this message translates to:
  /// **'الأيام المتبقية'**
  String get remainingDays;

  /// No description provided for @requests.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات'**
  String get requests;

  /// No description provided for @request.
  ///
  /// In ar, this message translates to:
  /// **'طلب'**
  String get request;

  /// No description provided for @myRequests.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get myRequests;

  /// No description provided for @newRequest.
  ///
  /// In ar, this message translates to:
  /// **'طلب جديد'**
  String get newRequest;

  /// No description provided for @requestType.
  ///
  /// In ar, this message translates to:
  /// **'نوع الطلب'**
  String get requestType;

  /// No description provided for @requestDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الطلب'**
  String get requestDate;

  /// No description provided for @requestStatus.
  ///
  /// In ar, this message translates to:
  /// **'حالة الطلب'**
  String get requestStatus;

  /// No description provided for @requestDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الطلب'**
  String get requestDetails;

  /// No description provided for @requestNotes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات الطلب'**
  String get requestNotes;

  /// No description provided for @noRequests.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات'**
  String get noRequests;

  /// No description provided for @approveRequest.
  ///
  /// In ar, this message translates to:
  /// **'قبول الطلب'**
  String get approveRequest;

  /// No description provided for @rejectRequest.
  ///
  /// In ar, this message translates to:
  /// **'رفض الطلب'**
  String get rejectRequest;

  /// No description provided for @requestApproved.
  ///
  /// In ar, this message translates to:
  /// **'تمت الموافقة على الطلب'**
  String get requestApproved;

  /// No description provided for @requestRejected.
  ///
  /// In ar, this message translates to:
  /// **'تم رفض الطلب'**
  String get requestRejected;

  /// No description provided for @rejectionReason.
  ///
  /// In ar, this message translates to:
  /// **'سبب الرفض'**
  String get rejectionReason;

  /// No description provided for @missions.
  ///
  /// In ar, this message translates to:
  /// **'المهمات'**
  String get missions;

  /// No description provided for @mission.
  ///
  /// In ar, this message translates to:
  /// **'مهمة'**
  String get mission;

  /// No description provided for @myMissions.
  ///
  /// In ar, this message translates to:
  /// **'مهماتي'**
  String get myMissions;

  /// No description provided for @allMissions.
  ///
  /// In ar, this message translates to:
  /// **'كل المهمات'**
  String get allMissions;

  /// No description provided for @newMission.
  ///
  /// In ar, this message translates to:
  /// **'مهمة جديدة'**
  String get newMission;

  /// No description provided for @missionDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل المهمة'**
  String get missionDetails;

  /// No description provided for @missionTitle.
  ///
  /// In ar, this message translates to:
  /// **'عنوان المهمة'**
  String get missionTitle;

  /// No description provided for @missionDescription.
  ///
  /// In ar, this message translates to:
  /// **'وصف المهمة'**
  String get missionDescription;

  /// No description provided for @missionLocation.
  ///
  /// In ar, this message translates to:
  /// **'موقع المهمة'**
  String get missionLocation;

  /// No description provided for @missionDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ المهمة'**
  String get missionDate;

  /// No description provided for @plannedStart.
  ///
  /// In ar, this message translates to:
  /// **'وقت البدء المخطط'**
  String get plannedStart;

  /// No description provided for @plannedEnd.
  ///
  /// In ar, this message translates to:
  /// **'وقت الانتهاء المخطط'**
  String get plannedEnd;

  /// No description provided for @actualStart.
  ///
  /// In ar, this message translates to:
  /// **'وقت البدء الفعلي'**
  String get actualStart;

  /// No description provided for @actualEnd.
  ///
  /// In ar, this message translates to:
  /// **'وقت الانتهاء الفعلي'**
  String get actualEnd;

  /// No description provided for @missionStatus.
  ///
  /// In ar, this message translates to:
  /// **'حالة المهمة'**
  String get missionStatus;

  /// No description provided for @missionPriority.
  ///
  /// In ar, this message translates to:
  /// **'أولوية المهمة'**
  String get missionPriority;

  /// No description provided for @priorityUrgent.
  ///
  /// In ar, this message translates to:
  /// **'عاجل'**
  String get priorityUrgent;

  /// No description provided for @priorityHigh.
  ///
  /// In ar, this message translates to:
  /// **'عالي'**
  String get priorityHigh;

  /// No description provided for @priorityNormal.
  ///
  /// In ar, this message translates to:
  /// **'عادي'**
  String get priorityNormal;

  /// No description provided for @assignees.
  ///
  /// In ar, this message translates to:
  /// **'المعينون'**
  String get assignees;

  /// No description provided for @addAssignee.
  ///
  /// In ar, this message translates to:
  /// **'إضافة موظف'**
  String get addAssignee;

  /// No description provided for @missionLead.
  ///
  /// In ar, this message translates to:
  /// **'قائد المهمة'**
  String get missionLead;

  /// No description provided for @assistant.
  ///
  /// In ar, this message translates to:
  /// **'مساعد'**
  String get assistant;

  /// No description provided for @clientName.
  ///
  /// In ar, this message translates to:
  /// **'اسم العميل'**
  String get clientName;

  /// No description provided for @clientPhone.
  ///
  /// In ar, this message translates to:
  /// **'هاتف العميل'**
  String get clientPhone;

  /// No description provided for @clientCompany.
  ///
  /// In ar, this message translates to:
  /// **'شركة العميل'**
  String get clientCompany;

  /// No description provided for @startMission.
  ///
  /// In ar, this message translates to:
  /// **'بدء المهمة'**
  String get startMission;

  /// No description provided for @endMission.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء المهمة'**
  String get endMission;

  /// No description provided for @acceptMission.
  ///
  /// In ar, this message translates to:
  /// **'قبول المهمة'**
  String get acceptMission;

  /// No description provided for @rejectMission.
  ///
  /// In ar, this message translates to:
  /// **'رفض المهمة'**
  String get rejectMission;

  /// No description provided for @withdrawalRequest.
  ///
  /// In ar, this message translates to:
  /// **'طلب انسحاب'**
  String get withdrawalRequest;

  /// No description provided for @withdrawalReason.
  ///
  /// In ar, this message translates to:
  /// **'سبب الانسحاب'**
  String get withdrawalReason;

  /// No description provided for @cancelMission.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء المهمة'**
  String get cancelMission;

  /// No description provided for @missionCancelled.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء المهمة'**
  String get missionCancelled;

  /// No description provided for @missionCompleted.
  ///
  /// In ar, this message translates to:
  /// **'تم إنهاء المهمة'**
  String get missionCompleted;

  /// No description provided for @missionStarted.
  ///
  /// In ar, this message translates to:
  /// **'تم بدء المهمة'**
  String get missionStarted;

  /// No description provided for @noMissions.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مهمات'**
  String get noMissions;

  /// No description provided for @todayMissions.
  ///
  /// In ar, this message translates to:
  /// **'مهمات اليوم'**
  String get todayMissions;

  /// No description provided for @upcomingMissions.
  ///
  /// In ar, this message translates to:
  /// **'المهمات القادمة'**
  String get upcomingMissions;

  /// No description provided for @pastMissions.
  ///
  /// In ar, this message translates to:
  /// **'المهمات السابقة'**
  String get pastMissions;

  /// No description provided for @missionFeedback.
  ///
  /// In ar, this message translates to:
  /// **'تقرير ما بعد الزيارة'**
  String get missionFeedback;

  /// No description provided for @writeFeedback.
  ///
  /// In ar, this message translates to:
  /// **'كتابة التقرير'**
  String get writeFeedback;

  /// No description provided for @feedbackRequired.
  ///
  /// In ar, this message translates to:
  /// **'يرجى كتابة التقرير قبل الإغلاق'**
  String get feedbackRequired;

  /// No description provided for @clientStatus.
  ///
  /// In ar, this message translates to:
  /// **'حالة العميل'**
  String get clientStatus;

  /// No description provided for @veryInterested.
  ///
  /// In ar, this message translates to:
  /// **'مهتم جداً'**
  String get veryInterested;

  /// No description provided for @interested.
  ///
  /// In ar, this message translates to:
  /// **'مهتم'**
  String get interested;

  /// No description provided for @thinking.
  ///
  /// In ar, this message translates to:
  /// **'يفكر'**
  String get thinking;

  /// No description provided for @notInterested.
  ///
  /// In ar, this message translates to:
  /// **'غير مهتم'**
  String get notInterested;

  /// No description provided for @postponed.
  ///
  /// In ar, this message translates to:
  /// **'مؤجل'**
  String get postponed;

  /// No description provided for @interestRating.
  ///
  /// In ar, this message translates to:
  /// **'تقييم الاهتمام'**
  String get interestRating;

  /// No description provided for @dealProbability.
  ///
  /// In ar, this message translates to:
  /// **'احتمالية التعاقد'**
  String get dealProbability;

  /// No description provided for @clientNeeds.
  ///
  /// In ar, this message translates to:
  /// **'احتياجات العميل'**
  String get clientNeeds;

  /// No description provided for @estimatedBudget.
  ///
  /// In ar, this message translates to:
  /// **'الميزانية التقديرية'**
  String get estimatedBudget;

  /// No description provided for @expectedDecisionDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ القرار المتوقع'**
  String get expectedDecisionDate;

  /// No description provided for @needsFollowup.
  ///
  /// In ar, this message translates to:
  /// **'يحتاج متابعة'**
  String get needsFollowup;

  /// No description provided for @followupDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ المتابعة'**
  String get followupDate;

  /// No description provided for @followupNotes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات المتابعة'**
  String get followupNotes;

  /// No description provided for @followupOwner.
  ///
  /// In ar, this message translates to:
  /// **'المسؤول عن المتابعة'**
  String get followupOwner;

  /// No description provided for @contractSigned.
  ///
  /// In ar, this message translates to:
  /// **'تم توقيع عقد'**
  String get contractSigned;

  /// No description provided for @dealValue.
  ///
  /// In ar, this message translates to:
  /// **'قيمة الصفقة'**
  String get dealValue;

  /// No description provided for @internalNotes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات داخلية'**
  String get internalNotes;

  /// No description provided for @requestMission.
  ///
  /// In ar, this message translates to:
  /// **'طلب مهمة'**
  String get requestMission;

  /// No description provided for @missionRequests.
  ///
  /// In ar, this message translates to:
  /// **'طلبات المهمات'**
  String get missionRequests;

  /// No description provided for @missionRequestSent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال طلب المهمة'**
  String get missionRequestSent;

  /// No description provided for @approveMission.
  ///
  /// In ar, this message translates to:
  /// **'قبول المهمة'**
  String get approveMission;

  /// No description provided for @missionApproved.
  ///
  /// In ar, this message translates to:
  /// **'تمت الموافقة على المهمة'**
  String get missionApproved;

  /// No description provided for @proofPhotos.
  ///
  /// In ar, this message translates to:
  /// **'صور الإثبات'**
  String get proofPhotos;

  /// No description provided for @addPhoto.
  ///
  /// In ar, this message translates to:
  /// **'إضافة صورة'**
  String get addPhoto;

  /// No description provided for @photoCaption.
  ///
  /// In ar, this message translates to:
  /// **'وصف الصورة'**
  String get photoCaption;

  /// No description provided for @locationTimeline.
  ///
  /// In ar, this message translates to:
  /// **'مسار التنقل'**
  String get locationTimeline;

  /// No description provided for @updateLocation.
  ///
  /// In ar, this message translates to:
  /// **'تحديث الموقع'**
  String get updateLocation;

  /// No description provided for @locationUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث الموقع'**
  String get locationUpdated;

  /// No description provided for @locationLabel.
  ///
  /// In ar, this message translates to:
  /// **'وصف الموقع'**
  String get locationLabel;

  /// No description provided for @autoAttendance.
  ///
  /// In ar, this message translates to:
  /// **'حضور تلقائي من المهمة'**
  String get autoAttendance;

  /// No description provided for @location.
  ///
  /// In ar, this message translates to:
  /// **'الموقع'**
  String get location;

  /// No description provided for @currentLocation.
  ///
  /// In ar, this message translates to:
  /// **'الموقع الحالي'**
  String get currentLocation;

  /// No description provided for @liveLocations.
  ///
  /// In ar, this message translates to:
  /// **'المواقع الحية'**
  String get liveLocations;

  /// No description provided for @dailyLocationReport.
  ///
  /// In ar, this message translates to:
  /// **'تقرير المواقع اليومي'**
  String get dailyLocationReport;

  /// No description provided for @locationSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الموقع'**
  String get locationSaved;

  /// No description provided for @locationFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحديد الموقع'**
  String get locationFailed;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'تم رفض إذن الموقع'**
  String get locationPermissionDenied;

  /// No description provided for @enableLocation.
  ///
  /// In ar, this message translates to:
  /// **'يرجى تفعيل خدمة الموقع'**
  String get enableLocation;

  /// No description provided for @outOfRange.
  ///
  /// In ar, this message translates to:
  /// **'أنت خارج النطاق المسموح'**
  String get outOfRange;

  /// No description provided for @withinRange.
  ///
  /// In ar, this message translates to:
  /// **'أنت داخل النطاق'**
  String get withinRange;

  /// No description provided for @distance.
  ///
  /// In ar, this message translates to:
  /// **'المسافة'**
  String get distance;

  /// No description provided for @latitude.
  ///
  /// In ar, this message translates to:
  /// **'خط العرض'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In ar, this message translates to:
  /// **'خط الطول'**
  String get longitude;

  /// No description provided for @company.
  ///
  /// In ar, this message translates to:
  /// **'الشركة'**
  String get company;

  /// No description provided for @companyInfo.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الشركة'**
  String get companyInfo;

  /// No description provided for @companyName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الشركة'**
  String get companyName;

  /// No description provided for @companyLogo.
  ///
  /// In ar, this message translates to:
  /// **'شعار الشركة'**
  String get companyLogo;

  /// No description provided for @companyAddress.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الشركة'**
  String get companyAddress;

  /// No description provided for @companyPhone.
  ///
  /// In ar, this message translates to:
  /// **'هاتف الشركة'**
  String get companyPhone;

  /// No description provided for @companyEmail.
  ///
  /// In ar, this message translates to:
  /// **'بريد الشركة'**
  String get companyEmail;

  /// No description provided for @companyWebsite.
  ///
  /// In ar, this message translates to:
  /// **'موقع الشركة'**
  String get companyWebsite;

  /// No description provided for @editCompanyInfo.
  ///
  /// In ar, this message translates to:
  /// **'تعديل بيانات الشركة'**
  String get editCompanyInfo;

  /// No description provided for @uploadLogo.
  ///
  /// In ar, this message translates to:
  /// **'رفع الشعار'**
  String get uploadLogo;

  /// No description provided for @changeLogo.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الشعار'**
  String get changeLogo;

  /// No description provided for @logoUploaded.
  ///
  /// In ar, this message translates to:
  /// **'تم رفع الشعار بنجاح'**
  String get logoUploaded;

  /// No description provided for @companyUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث بيانات الشركة'**
  String get companyUpdated;

  /// No description provided for @branches.
  ///
  /// In ar, this message translates to:
  /// **'الفروع'**
  String get branches;

  /// No description provided for @departments.
  ///
  /// In ar, this message translates to:
  /// **'الأقسام'**
  String get departments;

  /// No description provided for @managers.
  ///
  /// In ar, this message translates to:
  /// **'المديرون'**
  String get managers;

  /// No description provided for @organizationTree.
  ///
  /// In ar, this message translates to:
  /// **'الهيكل التنظيمي'**
  String get organizationTree;

  /// No description provided for @reports.
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get reports;

  /// No description provided for @report.
  ///
  /// In ar, this message translates to:
  /// **'تقرير'**
  String get report;

  /// No description provided for @generateReport.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء تقرير'**
  String get generateReport;

  /// No description provided for @reportDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ التقرير'**
  String get reportDate;

  /// No description provided for @fromDate.
  ///
  /// In ar, this message translates to:
  /// **'من تاريخ'**
  String get fromDate;

  /// No description provided for @toDate.
  ///
  /// In ar, this message translates to:
  /// **'إلى تاريخ'**
  String get toDate;

  /// No description provided for @exportPdf.
  ///
  /// In ar, this message translates to:
  /// **'تصدير PDF'**
  String get exportPdf;

  /// No description provided for @exportExcel.
  ///
  /// In ar, this message translates to:
  /// **'تصدير Excel'**
  String get exportExcel;

  /// No description provided for @printReport.
  ///
  /// In ar, this message translates to:
  /// **'طباعة التقرير'**
  String get printReport;

  /// No description provided for @poweredBy.
  ///
  /// In ar, this message translates to:
  /// **'Powered by MotionHR - JS Solutions'**
  String get poweredBy;

  /// No description provided for @payroll.
  ///
  /// In ar, this message translates to:
  /// **'الرواتب'**
  String get payroll;

  /// No description provided for @salary_slip.
  ///
  /// In ar, this message translates to:
  /// **'قسيمة الراتب'**
  String get salary_slip;

  /// No description provided for @allowances.
  ///
  /// In ar, this message translates to:
  /// **'البدلات'**
  String get allowances;

  /// No description provided for @deductions.
  ///
  /// In ar, this message translates to:
  /// **'الخصومات'**
  String get deductions;

  /// No description provided for @netSalary.
  ///
  /// In ar, this message translates to:
  /// **'صافي الراتب'**
  String get netSalary;

  /// No description provided for @basicSalary.
  ///
  /// In ar, this message translates to:
  /// **'الراتب الأساسي'**
  String get basicSalary;

  /// No description provided for @totalAllowances.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي البدلات'**
  String get totalAllowances;

  /// No description provided for @totalDeductions.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الخصومات'**
  String get totalDeductions;

  /// No description provided for @payrollMonth.
  ///
  /// In ar, this message translates to:
  /// **'شهر الراتب'**
  String get payrollMonth;

  /// No description provided for @payrollYear.
  ///
  /// In ar, this message translates to:
  /// **'سنة الراتب'**
  String get payrollYear;

  /// No description provided for @noPayroll.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بيانات رواتب'**
  String get noPayroll;

  /// No description provided for @announcements.
  ///
  /// In ar, this message translates to:
  /// **'الإعلانات'**
  String get announcements;

  /// No description provided for @announcement.
  ///
  /// In ar, this message translates to:
  /// **'إعلان'**
  String get announcement;

  /// No description provided for @noAnnouncements.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إعلانات'**
  String get noAnnouncements;

  /// No description provided for @newAnnouncement.
  ///
  /// In ar, this message translates to:
  /// **'إعلان جديد'**
  String get newAnnouncement;

  /// No description provided for @announcementTitle.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الإعلان'**
  String get announcementTitle;

  /// No description provided for @announcementContent.
  ///
  /// In ar, this message translates to:
  /// **'محتوى الإعلان'**
  String get announcementContent;

  /// No description provided for @announcementDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الإعلان'**
  String get announcementDate;

  /// No description provided for @publishAnnouncement.
  ///
  /// In ar, this message translates to:
  /// **'نشر الإعلان'**
  String get publishAnnouncement;

  /// No description provided for @chat.
  ///
  /// In ar, this message translates to:
  /// **'المحادثات'**
  String get chat;

  /// No description provided for @message.
  ///
  /// In ar, this message translates to:
  /// **'رسالة'**
  String get message;

  /// No description provided for @messages.
  ///
  /// In ar, this message translates to:
  /// **'الرسائل'**
  String get messages;

  /// No description provided for @sendMessage.
  ///
  /// In ar, this message translates to:
  /// **'إرسال رسالة'**
  String get sendMessage;

  /// No description provided for @typeMessage.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رسالة...'**
  String get typeMessage;

  /// No description provided for @noMessages.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد رسائل'**
  String get noMessages;

  /// No description provided for @online.
  ///
  /// In ar, this message translates to:
  /// **'متصل'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In ar, this message translates to:
  /// **'غير متصل'**
  String get offline;

  /// No description provided for @lastSeen.
  ///
  /// In ar, this message translates to:
  /// **'آخر ظهور'**
  String get lastSeen;

  /// No description provided for @groupChat.
  ///
  /// In ar, this message translates to:
  /// **'محادثة جماعية'**
  String get groupChat;

  /// No description provided for @newGroup.
  ///
  /// In ar, this message translates to:
  /// **'مجموعة جديدة'**
  String get newGroup;

  /// No description provided for @groupName.
  ///
  /// In ar, this message translates to:
  /// **'اسم المجموعة'**
  String get groupName;

  /// No description provided for @members.
  ///
  /// In ar, this message translates to:
  /// **'الأعضاء'**
  String get members;

  /// No description provided for @addMembers.
  ///
  /// In ar, this message translates to:
  /// **'إضافة أعضاء'**
  String get addMembers;

  /// No description provided for @changePassword.
  ///
  /// In ar, this message translates to:
  /// **'تغيير كلمة المرور'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الحالية'**
  String get currentPassword;

  /// No description provided for @newPasswordHint.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الجديدة (8 أحرف على الأقل)'**
  String get newPasswordHint;

  /// No description provided for @passwordChanged.
  ///
  /// In ar, this message translates to:
  /// **'تم تغيير كلمة المرور بنجاح'**
  String get passwordChanged;

  /// No description provided for @passwordTooShort.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور قصيرة جداً'**
  String get passwordTooShort;

  /// No description provided for @biometric.
  ///
  /// In ar, this message translates to:
  /// **'بصمة الإصبع / الوجه'**
  String get biometric;

  /// No description provided for @enableBiometric.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل البصمة'**
  String get enableBiometric;

  /// No description provided for @biometricEnabled.
  ///
  /// In ar, this message translates to:
  /// **'تم تفعيل البصمة'**
  String get biometricEnabled;

  /// No description provided for @biometricDisabled.
  ///
  /// In ar, this message translates to:
  /// **'تم تعطيل البصمة'**
  String get biometricDisabled;

  /// No description provided for @biometricNotAvailable.
  ///
  /// In ar, this message translates to:
  /// **'البصمة غير متوفرة على هذا الجهاز'**
  String get biometricNotAvailable;

  /// No description provided for @loginWithBiometric.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول بالبصمة'**
  String get loginWithBiometric;

  /// No description provided for @documents.
  ///
  /// In ar, this message translates to:
  /// **'المستندات'**
  String get documents;

  /// No description provided for @document.
  ///
  /// In ar, this message translates to:
  /// **'مستند'**
  String get document;

  /// No description provided for @noDocuments.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مستندات'**
  String get noDocuments;

  /// No description provided for @uploadDocument.
  ///
  /// In ar, this message translates to:
  /// **'رفع مستند'**
  String get uploadDocument;

  /// No description provided for @documentType.
  ///
  /// In ar, this message translates to:
  /// **'نوع المستند'**
  String get documentType;

  /// No description provided for @documentDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ المستند'**
  String get documentDate;

  /// No description provided for @movements.
  ///
  /// In ar, this message translates to:
  /// **'الحركات'**
  String get movements;

  /// No description provided for @noMovements.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد حركات'**
  String get noMovements;

  /// No description provided for @movementType.
  ///
  /// In ar, this message translates to:
  /// **'نوع الحركة'**
  String get movementType;

  /// No description provided for @movementDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الحركة'**
  String get movementDate;

  /// No description provided for @movementReason.
  ///
  /// In ar, this message translates to:
  /// **'سبب الحركة'**
  String get movementReason;

  /// No description provided for @reminders.
  ///
  /// In ar, this message translates to:
  /// **'التذكيرات'**
  String get reminders;

  /// No description provided for @reminder.
  ///
  /// In ar, this message translates to:
  /// **'تذكير'**
  String get reminder;

  /// No description provided for @noReminders.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تذكيرات'**
  String get noReminders;

  /// No description provided for @newReminder.
  ///
  /// In ar, this message translates to:
  /// **'تذكير جديد'**
  String get newReminder;

  /// No description provided for @reminderTitle.
  ///
  /// In ar, this message translates to:
  /// **'عنوان التذكير'**
  String get reminderTitle;

  /// No description provided for @reminderDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ التذكير'**
  String get reminderDate;

  /// No description provided for @reminderTime.
  ///
  /// In ar, this message translates to:
  /// **'وقت التذكير'**
  String get reminderTime;

  /// No description provided for @permissions.
  ///
  /// In ar, this message translates to:
  /// **'الصلاحيات'**
  String get permissions;

  /// No description provided for @accessDenied.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك صلاحية للوصول'**
  String get accessDenied;

  /// No description provided for @superAdmin.
  ///
  /// In ar, this message translates to:
  /// **'المشرف العام'**
  String get superAdmin;

  /// No description provided for @companyAdmin.
  ///
  /// In ar, this message translates to:
  /// **'مدير الشركة'**
  String get companyAdmin;

  /// No description provided for @manager.
  ///
  /// In ar, this message translates to:
  /// **'مدير'**
  String get manager;

  /// No description provided for @hrManager.
  ///
  /// In ar, this message translates to:
  /// **'مدير الموارد البشرية'**
  String get hrManager;

  /// No description provided for @employeeRole.
  ///
  /// In ar, this message translates to:
  /// **'موظف'**
  String get employeeRole;

  /// No description provided for @networkError.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في الاتصال بالإنترنت'**
  String get networkError;

  /// No description provided for @serverError.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في السيرفر، يرجى المحاولة لاحقاً'**
  String get serverError;

  /// No description provided for @timeoutError.
  ///
  /// In ar, this message translates to:
  /// **'انتهت مهلة الاتصال'**
  String get timeoutError;

  /// No description provided for @unknownError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع'**
  String get unknownError;

  /// No description provided for @tryAgain.
  ///
  /// In ar, this message translates to:
  /// **'حاول مرة أخرى'**
  String get tryAgain;

  /// No description provided for @connectionFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل الاتصال'**
  String get connectionFailed;

  /// No description provided for @checkConnection.
  ///
  /// In ar, this message translates to:
  /// **'تحقق من اتصالك بالإنترنت'**
  String get checkConnection;

  /// No description provided for @january.
  ///
  /// In ar, this message translates to:
  /// **'يناير'**
  String get january;

  /// No description provided for @february.
  ///
  /// In ar, this message translates to:
  /// **'فبراير'**
  String get february;

  /// No description provided for @march.
  ///
  /// In ar, this message translates to:
  /// **'مارس'**
  String get march;

  /// No description provided for @april.
  ///
  /// In ar, this message translates to:
  /// **'أبريل'**
  String get april;

  /// No description provided for @may.
  ///
  /// In ar, this message translates to:
  /// **'مايو'**
  String get may;

  /// No description provided for @june.
  ///
  /// In ar, this message translates to:
  /// **'يونيو'**
  String get june;

  /// No description provided for @july.
  ///
  /// In ar, this message translates to:
  /// **'يوليو'**
  String get july;

  /// No description provided for @august.
  ///
  /// In ar, this message translates to:
  /// **'أغسطس'**
  String get august;

  /// No description provided for @september.
  ///
  /// In ar, this message translates to:
  /// **'سبتمبر'**
  String get september;

  /// No description provided for @october.
  ///
  /// In ar, this message translates to:
  /// **'أكتوبر'**
  String get october;

  /// No description provided for @november.
  ///
  /// In ar, this message translates to:
  /// **'نوفمبر'**
  String get november;

  /// No description provided for @december.
  ///
  /// In ar, this message translates to:
  /// **'ديسمبر'**
  String get december;

  /// No description provided for @monday.
  ///
  /// In ar, this message translates to:
  /// **'الإثنين'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In ar, this message translates to:
  /// **'الثلاثاء'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In ar, this message translates to:
  /// **'الأربعاء'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In ar, this message translates to:
  /// **'الخميس'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In ar, this message translates to:
  /// **'الجمعة'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In ar, this message translates to:
  /// **'السبت'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In ar, this message translates to:
  /// **'الأحد'**
  String get sunday;

  /// No description provided for @version.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار'**
  String get version;

  /// No description provided for @appVersion.
  ///
  /// In ar, this message translates to:
  /// **'MotionHR v1.0'**
  String get appVersion;

  /// No description provided for @contactSupport.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع الدعم'**
  String get contactSupport;

  /// No description provided for @termsOfService.
  ///
  /// In ar, this message translates to:
  /// **'شروط الخدمة'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية'**
  String get privacyPolicy;

  /// No description provided for @aboutApp.
  ///
  /// In ar, this message translates to:
  /// **'عن التطبيق'**
  String get aboutApp;

  /// No description provided for @checkUpdate.
  ///
  /// In ar, this message translates to:
  /// **'التحقق من التحديثات'**
  String get checkUpdate;

  /// No description provided for @darkMode.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الداكن'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الفاتح'**
  String get lightMode;

  /// No description provided for @fontSize.
  ///
  /// In ar, this message translates to:
  /// **'حجم الخط'**
  String get fontSize;

  /// No description provided for @logoutConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من تسجيل الخروج؟'**
  String get logoutConfirm;

  /// No description provided for @sessionExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى'**
  String get sessionExpired;

  /// No description provided for @importEmployees.
  ///
  /// In ar, this message translates to:
  /// **'استيراد الموظفين'**
  String get importEmployees;

  /// No description provided for @downloadTemplate.
  ///
  /// In ar, this message translates to:
  /// **'تحميل القالب'**
  String get downloadTemplate;

  /// No description provided for @excelImport.
  ///
  /// In ar, this message translates to:
  /// **'استيراد من Excel'**
  String get excelImport;

  /// No description provided for @importSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم الاستيراد بنجاح'**
  String get importSuccess;

  /// No description provided for @importFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل الاستيراد'**
  String get importFailed;

  /// No description provided for @importErrors.
  ///
  /// In ar, this message translates to:
  /// **'أخطاء الاستيراد'**
  String get importErrors;

  /// No description provided for @rowNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم الصف'**
  String get rowNumber;

  /// No description provided for @totalImported.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المستوردين'**
  String get totalImported;

  /// No description provided for @totalFailed.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الفاشلين'**
  String get totalFailed;

  /// No description provided for @selectFile.
  ///
  /// In ar, this message translates to:
  /// **'اختر ملفاً'**
  String get selectFile;

  /// No description provided for @noFileSelected.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم اختيار ملف'**
  String get noFileSelected;

  /// No description provided for @geofence.
  ///
  /// In ar, this message translates to:
  /// **'المناطق الجغرافية'**
  String get geofence;

  /// No description provided for @geofenceArea.
  ///
  /// In ar, this message translates to:
  /// **'نطاق العمل'**
  String get geofenceArea;

  /// No description provided for @enterGeofence.
  ///
  /// In ar, this message translates to:
  /// **'دخلت نطاق العمل'**
  String get enterGeofence;

  /// No description provided for @exitGeofence.
  ///
  /// In ar, this message translates to:
  /// **'خرجت من نطاق العمل'**
  String get exitGeofence;

  /// No description provided for @allowedRadius.
  ///
  /// In ar, this message translates to:
  /// **'النطاق المسموح (متر)'**
  String get allowedRadius;

  /// No description provided for @workLocation.
  ///
  /// In ar, this message translates to:
  /// **'موقع العمل'**
  String get workLocation;

  /// No description provided for @addWorkLocation.
  ///
  /// In ar, this message translates to:
  /// **'إضافة موقع عمل'**
  String get addWorkLocation;

  /// No description provided for @excel_import_employees.
  ///
  /// In ar, this message translates to:
  /// **'استيراد موظفين'**
  String get excel_import_employees;

  /// No description provided for @pdf_employee_report.
  ///
  /// In ar, this message translates to:
  /// **'تقرير الموظف'**
  String get pdf_employee_report;

  /// No description provided for @pdf_attendance_report.
  ///
  /// In ar, this message translates to:
  /// **'تقرير الحضور'**
  String get pdf_attendance_report;

  /// No description provided for @pdf_mission_report.
  ///
  /// In ar, this message translates to:
  /// **'تقرير المهمة'**
  String get pdf_mission_report;

  /// No description provided for @pdf_location_report.
  ///
  /// In ar, this message translates to:
  /// **'تقرير المواقع'**
  String get pdf_location_report;

  /// No description provided for @missionAutoCheckin.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل حضورك تلقائياً عبر المهمة'**
  String get missionAutoCheckin;

  /// No description provided for @missionAutoCheckout.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل انصرافك تلقائياً بعد انتهاء المهمة'**
  String get missionAutoCheckout;

  /// No description provided for @cannotCheckoutActiveMission.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن تسجيل الانصراف أثناء وجود مهمة نشطة'**
  String get cannotCheckoutActiveMission;

  /// No description provided for @missionCreatedByEmployee.
  ///
  /// In ar, this message translates to:
  /// **'مهمة مقترحة من الموظف'**
  String get missionCreatedByEmployee;

  /// No description provided for @missionPendingApproval.
  ///
  /// In ar, this message translates to:
  /// **'في انتظار الموافقة'**
  String get missionPendingApproval;

  /// No description provided for @managerApproval.
  ///
  /// In ar, this message translates to:
  /// **'موافقة المدير'**
  String get managerApproval;

  /// No description provided for @hrApproval.
  ///
  /// In ar, this message translates to:
  /// **'موافقة الموارد البشرية'**
  String get hrApproval;

  /// No description provided for @approvalRequired.
  ///
  /// In ar, this message translates to:
  /// **'يتطلب موافقة'**
  String get approvalRequired;

  /// No description provided for @approvalGranted.
  ///
  /// In ar, this message translates to:
  /// **'تمت الموافقة'**
  String get approvalGranted;

  /// No description provided for @approvalDenied.
  ///
  /// In ar, this message translates to:
  /// **'تم الرفض'**
  String get approvalDenied;

  /// No description provided for @submitForApproval.
  ///
  /// In ar, this message translates to:
  /// **'إرسال للموافقة'**
  String get submitForApproval;

  /// No description provided for @pendingManagerApproval.
  ///
  /// In ar, this message translates to:
  /// **'في انتظار موافقة المدير'**
  String get pendingManagerApproval;

  /// No description provided for @pendingHrApproval.
  ///
  /// In ar, this message translates to:
  /// **'في انتظار موافقة الموارد البشرية'**
  String get pendingHrApproval;

  /// No description provided for @fullyApproved.
  ///
  /// In ar, this message translates to:
  /// **'تمت الموافقة الكاملة'**
  String get fullyApproved;

  /// No description provided for @addendum.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة إضافية'**
  String get addendum;

  /// No description provided for @addNote.
  ///
  /// In ar, this message translates to:
  /// **'إضافة ملاحظة'**
  String get addNote;

  /// No description provided for @yourNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظتك'**
  String get yourNote;

  /// No description provided for @participantNotes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات المشاركين'**
  String get participantNotes;

  /// No description provided for @createFollowupMission.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء مهمة متابعة'**
  String get createFollowupMission;

  /// No description provided for @followupCreated.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء مهمة المتابعة'**
  String get followupCreated;

  /// No description provided for @feedbackDashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة تحكم الفيدباك'**
  String get feedbackDashboard;

  /// No description provided for @veryInterestedClients.
  ///
  /// In ar, this message translates to:
  /// **'عملاء مهتمون جداً'**
  String get veryInterestedClients;

  /// No description provided for @upcomingFollowups.
  ///
  /// In ar, this message translates to:
  /// **'المتابعات القادمة'**
  String get upcomingFollowups;

  /// No description provided for @totalDealsExpected.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الصفقات المتوقعة'**
  String get totalDealsExpected;

  /// No description provided for @signedContracts.
  ///
  /// In ar, this message translates to:
  /// **'العقود الموقعة'**
  String get signedContracts;

  /// No description provided for @preferredContact.
  ///
  /// In ar, this message translates to:
  /// **'وسيلة التواصل المفضلة'**
  String get preferredContact;

  /// No description provided for @contactViaPhone.
  ///
  /// In ar, this message translates to:
  /// **'هاتف'**
  String get contactViaPhone;

  /// No description provided for @contactViaWhatsapp.
  ///
  /// In ar, this message translates to:
  /// **'واتساب'**
  String get contactViaWhatsapp;

  /// No description provided for @contactViaEmail.
  ///
  /// In ar, this message translates to:
  /// **'بريد إلكتروني'**
  String get contactViaEmail;

  /// No description provided for @contactViaVisit.
  ///
  /// In ar, this message translates to:
  /// **'زيارة'**
  String get contactViaVisit;

  /// No description provided for @interestedIn.
  ///
  /// In ar, this message translates to:
  /// **'مهتم بـ'**
  String get interestedIn;

  /// No description provided for @clientPosition.
  ///
  /// In ar, this message translates to:
  /// **'المنصب'**
  String get clientPosition;

  /// No description provided for @clientActualAddress.
  ///
  /// In ar, this message translates to:
  /// **'العنوان الفعلي'**
  String get clientActualAddress;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
