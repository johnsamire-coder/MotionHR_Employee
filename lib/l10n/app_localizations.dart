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
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
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
  /// In en, this message translates to:
  /// **'MotionHR'**
  String get appName;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @stayLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Stay logged in'**
  String get stayLoggedIn;

  /// No description provided for @stayLoggedInDesc.
  ///
  /// In en, this message translates to:
  /// **'Account stays open for 72 hours or until logout'**
  String get stayLoggedInDesc;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Please contact your HR manager to reset your password.'**
  String get forgotPasswordDesc;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome, sign in to continue'**
  String get welcome;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Language'**
  String get chooseLanguage;

  /// No description provided for @chooseLanguageDesc.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language to use the app'**
  String get chooseLanguageDesc;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @loginBiometric.
  ///
  /// In en, this message translates to:
  /// **'Login with Biometric'**
  String get loginBiometric;

  /// No description provided for @loginError.
  ///
  /// In en, this message translates to:
  /// **'Invalid login credentials'**
  String get loginError;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get connectionError;

  /// No description provided for @enterUsernamePassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter username and password'**
  String get enterUsernamePassword;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @quickManagement.
  ///
  /// In en, this message translates to:
  /// **'Quick Management'**
  String get quickManagement;

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// No description provided for @pendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending Requests'**
  String get pendingRequests;

  /// No description provided for @attendanceToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Attendance'**
  String get attendanceToday;

  /// No description provided for @liveLocations.
  ///
  /// In en, this message translates to:
  /// **'Live Locations'**
  String get liveLocations;

  /// No description provided for @employees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employees;

  /// No description provided for @addEmployee.
  ///
  /// In en, this message translates to:
  /// **'Add Employee'**
  String get addEmployee;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @payroll.
  ///
  /// In en, this message translates to:
  /// **'Payroll'**
  String get payroll;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @companyCharter.
  ///
  /// In en, this message translates to:
  /// **'Company Charter'**
  String get companyCharter;

  /// No description provided for @missions.
  ///
  /// In en, this message translates to:
  /// **'Missions'**
  String get missions;

  /// No description provided for @companyInfo.
  ///
  /// In en, this message translates to:
  /// **'Company Info'**
  String get companyInfo;

  /// No description provided for @orgTree.
  ///
  /// In en, this message translates to:
  /// **'Org Chart'**
  String get orgTree;

  /// No description provided for @locationReport.
  ///
  /// In en, this message translates to:
  /// **'Location Report'**
  String get locationReport;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check In'**
  String get checkIn;

  /// No description provided for @checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check Out'**
  String get checkOut;

  /// No description provided for @checkedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked In'**
  String get checkedIn;

  /// No description provided for @checkedOut.
  ///
  /// In en, this message translates to:
  /// **'Checked Out'**
  String get checkedOut;

  /// No description provided for @checkInTime.
  ///
  /// In en, this message translates to:
  /// **'Check-in Time'**
  String get checkInTime;

  /// No description provided for @checkOutTime.
  ///
  /// In en, this message translates to:
  /// **'Check-out Time'**
  String get checkOutTime;

  /// No description provided for @shift.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get shift;

  /// No description provided for @remainingTime.
  ///
  /// In en, this message translates to:
  /// **'Remaining Time'**
  String get remainingTime;

  /// No description provided for @shiftEnded.
  ///
  /// In en, this message translates to:
  /// **'Shift ended, you can check out'**
  String get shiftEnded;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'Previous Days'**
  String get history;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @earlyLeavePermission.
  ///
  /// In en, this message translates to:
  /// **'You have early leave permission'**
  String get earlyLeavePermission;

  /// No description provided for @attendanceDone.
  ///
  /// In en, this message translates to:
  /// **'Attendance recorded successfully'**
  String get attendanceDone;

  /// No description provided for @greatWork.
  ///
  /// In en, this message translates to:
  /// **'Great work today 👏'**
  String get greatWork;

  /// No description provided for @employeeCode.
  ///
  /// In en, this message translates to:
  /// **'Employee Code'**
  String get employeeCode;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @nationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get nationalId;

  /// No description provided for @birthDate.
  ///
  /// In en, this message translates to:
  /// **'Birth Date'**
  String get birthDate;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @branch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get branch;

  /// No description provided for @department.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get department;

  /// No description provided for @jobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Title'**
  String get jobTitle;

  /// No description provided for @directManager.
  ///
  /// In en, this message translates to:
  /// **'Direct Manager'**
  String get directManager;

  /// No description provided for @hireDate.
  ///
  /// In en, this message translates to:
  /// **'Hire Date'**
  String get hireDate;

  /// No description provided for @basicSalary.
  ///
  /// In en, this message translates to:
  /// **'Basic Salary'**
  String get basicSalary;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @createEmployee.
  ///
  /// In en, this message translates to:
  /// **'Create Employee'**
  String get createEmployee;

  /// No description provided for @editEmployee.
  ///
  /// In en, this message translates to:
  /// **'Edit Employee'**
  String get editEmployee;

  /// No description provided for @employeeDetails.
  ///
  /// In en, this message translates to:
  /// **'Employee Details'**
  String get employeeDetails;

  /// No description provided for @transferEmployee.
  ///
  /// In en, this message translates to:
  /// **'Transfer Employee'**
  String get transferEmployee;

  /// No description provided for @employeesList.
  ///
  /// In en, this message translates to:
  /// **'Employees List'**
  String get employeesList;

  /// No description provided for @noEmployees.
  ///
  /// In en, this message translates to:
  /// **'No employees found'**
  String get noEmployees;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @onLeave.
  ///
  /// In en, this message translates to:
  /// **'On Leave'**
  String get onLeave;

  /// No description provided for @suspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get suspended;

  /// No description provided for @resigned.
  ///
  /// In en, this message translates to:
  /// **'Resigned'**
  String get resigned;

  /// No description provided for @terminated.
  ///
  /// In en, this message translates to:
  /// **'Terminated'**
  String get terminated;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @leaves.
  ///
  /// In en, this message translates to:
  /// **'Leaves'**
  String get leaves;

  /// No description provided for @myRequests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequests;

  /// No description provided for @myLeaves.
  ///
  /// In en, this message translates to:
  /// **'My Leaves'**
  String get myLeaves;

  /// No description provided for @submitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get submitRequest;

  /// No description provided for @requestType.
  ///
  /// In en, this message translates to:
  /// **'Request Type'**
  String get requestType;

  /// No description provided for @leaveType.
  ///
  /// In en, this message translates to:
  /// **'Leave Type'**
  String get leaveType;

  /// No description provided for @requestTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Title'**
  String get requestTitle;

  /// No description provided for @requestDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get requestDetails;

  /// No description provided for @fromDate.
  ///
  /// In en, this message translates to:
  /// **'From Date'**
  String get fromDate;

  /// No description provided for @toDate.
  ///
  /// In en, this message translates to:
  /// **'To Date'**
  String get toDate;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get cancelRequest;

  /// No description provided for @cancelRequestConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this request?'**
  String get cancelRequestConfirm;

  /// No description provided for @cancelReason.
  ///
  /// In en, this message translates to:
  /// **'Cancel Reason (optional)'**
  String get cancelReason;

  /// No description provided for @noRequests.
  ///
  /// In en, this message translates to:
  /// **'No requests found'**
  String get noRequests;

  /// No description provided for @requestLeave.
  ///
  /// In en, this message translates to:
  /// **'Request Leave'**
  String get requestLeave;

  /// No description provided for @leaveBalance.
  ///
  /// In en, this message translates to:
  /// **'Remaining Balance'**
  String get leaveBalance;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @missionTitle.
  ///
  /// In en, this message translates to:
  /// **'Mission Title'**
  String get missionTitle;

  /// No description provided for @missionDetails.
  ///
  /// In en, this message translates to:
  /// **'Mission Details'**
  String get missionDetails;

  /// No description provided for @missionLocation.
  ///
  /// In en, this message translates to:
  /// **'Mission Location'**
  String get missionLocation;

  /// No description provided for @clientName.
  ///
  /// In en, this message translates to:
  /// **'Client Name'**
  String get clientName;

  /// No description provided for @clientPhone.
  ///
  /// In en, this message translates to:
  /// **'Client Phone'**
  String get clientPhone;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @plannedStart.
  ///
  /// In en, this message translates to:
  /// **'Planned Start Time'**
  String get plannedStart;

  /// No description provided for @plannedEnd.
  ///
  /// In en, this message translates to:
  /// **'Planned End Time'**
  String get plannedEnd;

  /// No description provided for @startMission.
  ///
  /// In en, this message translates to:
  /// **'Start Mission'**
  String get startMission;

  /// No description provided for @endMission.
  ///
  /// In en, this message translates to:
  /// **'End Mission'**
  String get endMission;

  /// No description provided for @acceptMission.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptMission;

  /// No description provided for @rejectMission.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectMission;

  /// No description provided for @myMissions.
  ///
  /// In en, this message translates to:
  /// **'My Missions'**
  String get myMissions;

  /// No description provided for @noMissions.
  ///
  /// In en, this message translates to:
  /// **'No missions found'**
  String get noMissions;

  /// No description provided for @missionFeedback.
  ///
  /// In en, this message translates to:
  /// **'Visit Feedback'**
  String get missionFeedback;

  /// No description provided for @writeFeedback.
  ///
  /// In en, this message translates to:
  /// **'Write Feedback'**
  String get writeFeedback;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChanged;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @biometricLogin.
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get biometricLogin;

  /// No description provided for @biometricPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in with biometric'**
  String get biometricPrompt;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get companyName;

  /// No description provided for @companyLogo.
  ///
  /// In en, this message translates to:
  /// **'Company Logo'**
  String get companyLogo;

  /// No description provided for @companyAddress.
  ///
  /// In en, this message translates to:
  /// **'Company Address'**
  String get companyAddress;

  /// No description provided for @companyPhone.
  ///
  /// In en, this message translates to:
  /// **'Company Phone'**
  String get companyPhone;

  /// No description provided for @branches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get branches;

  /// No description provided for @departments.
  ///
  /// In en, this message translates to:
  /// **'Departments'**
  String get departments;

  /// No description provided for @managers.
  ///
  /// In en, this message translates to:
  /// **'Managers'**
  String get managers;

  /// No description provided for @uploadLogo.
  ///
  /// In en, this message translates to:
  /// **'Upload Logo'**
  String get uploadLogo;

  /// No description provided for @editCompany.
  ///
  /// In en, this message translates to:
  /// **'Edit Company Info'**
  String get editCompany;

  /// No description provided for @attendanceReport.
  ///
  /// In en, this message translates to:
  /// **'Attendance Report'**
  String get attendanceReport;

  /// No description provided for @leavesReport.
  ///
  /// In en, this message translates to:
  /// **'Leaves Report'**
  String get leavesReport;

  /// No description provided for @lateReport.
  ///
  /// In en, this message translates to:
  /// **'Late Report'**
  String get lateReport;

  /// No description provided for @absenceReport.
  ///
  /// In en, this message translates to:
  /// **'Absence Report'**
  String get absenceReport;

  /// No description provided for @workHoursReport.
  ///
  /// In en, this message translates to:
  /// **'Work Hours Report'**
  String get workHoursReport;

  /// No description provided for @requestsReport.
  ///
  /// In en, this message translates to:
  /// **'Requests Report'**
  String get requestsReport;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @exportExcel.
  ///
  /// In en, this message translates to:
  /// **'Export Excel'**
  String get exportExcel;

  /// No description provided for @print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// No description provided for @poweredBy.
  ///
  /// In en, this message translates to:
  /// **'Powered by MotionHR - JS Solutions'**
  String get poweredBy;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @goodbye.
  ///
  /// In en, this message translates to:
  /// **'Goodbye'**
  String get goodbye;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired, please login again'**
  String get sessionExpired;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionDenied;

  /// No description provided for @locationPermission.
  ///
  /// In en, this message translates to:
  /// **'Location permission required'**
  String get locationPermission;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @uploadFile.
  ///
  /// In en, this message translates to:
  /// **'Upload File'**
  String get uploadFile;

  /// No description provided for @fileUploaded.
  ///
  /// In en, this message translates to:
  /// **'File uploaded'**
  String get fileUploaded;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @by.
  ///
  /// In en, this message translates to:
  /// **'By'**
  String get by;

  /// No description provided for @at.
  ///
  /// In en, this message translates to:
  /// **'At'**
  String get at;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @number.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get number;

  /// No description provided for @copyPassword.
  ///
  /// In en, this message translates to:
  /// **'Copy Password'**
  String get copyPassword;

  /// No description provided for @passwordCopied.
  ///
  /// In en, this message translates to:
  /// **'Password copied'**
  String get passwordCopied;

  /// No description provided for @newMission.
  ///
  /// In en, this message translates to:
  /// **'New Mission'**
  String get newMission;

  /// No description provided for @feedbackDashboard.
  ///
  /// In en, this message translates to:
  /// **'Feedback Dashboard'**
  String get feedbackDashboard;

  /// No description provided for @pendingMissionRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending Mission Requests'**
  String get pendingMissionRequests;

  /// No description provided for @noFeedback.
  ///
  /// In en, this message translates to:
  /// **'No feedback'**
  String get noFeedback;

  /// No description provided for @contractSigned.
  ///
  /// In en, this message translates to:
  /// **'Contract Signed'**
  String get contractSigned;

  /// No description provided for @veryInterested.
  ///
  /// In en, this message translates to:
  /// **'Very Interested'**
  String get veryInterested;

  /// No description provided for @thinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking'**
  String get thinking;

  /// No description provided for @notInterested.
  ///
  /// In en, this message translates to:
  /// **'Not Interested'**
  String get notInterested;

  /// No description provided for @postponed.
  ///
  /// In en, this message translates to:
  /// **'Postponed'**
  String get postponed;

  /// No description provided for @followupDate.
  ///
  /// In en, this message translates to:
  /// **'Follow-up Date'**
  String get followupDate;

  /// No description provided for @internalNotes.
  ///
  /// In en, this message translates to:
  /// **'Internal Notes'**
  String get internalNotes;

  /// No description provided for @warnings.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get warnings;

  /// No description provided for @participants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participants;

  /// No description provided for @missionLead.
  ///
  /// In en, this message translates to:
  /// **'Mission Lead'**
  String get missionLead;

  /// No description provided for @assistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get assistant;

  /// No description provided for @accompaniedManager.
  ///
  /// In en, this message translates to:
  /// **'Accompanied Manager'**
  String get accompaniedManager;

  /// No description provided for @trainee.
  ///
  /// In en, this message translates to:
  /// **'Trainee'**
  String get trainee;

  /// No description provided for @withdrawRequest.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Request'**
  String get withdrawRequest;

  /// No description provided for @withdrawReason.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal Reason'**
  String get withdrawReason;

  /// No description provided for @cancelMission.
  ///
  /// In en, this message translates to:
  /// **'Cancel Mission'**
  String get cancelMission;

  /// No description provided for @cancelMissionReason.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Reason'**
  String get cancelMissionReason;

  /// No description provided for @replaceEmployee.
  ///
  /// In en, this message translates to:
  /// **'Replace Employee'**
  String get replaceEmployee;

  /// No description provided for @currentEmployee.
  ///
  /// In en, this message translates to:
  /// **'Current Employee'**
  String get currentEmployee;

  /// No description provided for @newEmployee.
  ///
  /// In en, this message translates to:
  /// **'New Employee'**
  String get newEmployee;

  /// No description provided for @managerActions.
  ///
  /// In en, this message translates to:
  /// **'Manager Actions'**
  String get managerActions;

  /// No description provided for @locationUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update Location'**
  String get locationUpdate;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location Description'**
  String get locationLabel;

  /// No description provided for @uploadAttachment.
  ///
  /// In en, this message translates to:
  /// **'Upload Attachment'**
  String get uploadAttachment;

  /// No description provided for @attachmentCaption.
  ///
  /// In en, this message translates to:
  /// **'Attachment Caption'**
  String get attachmentCaption;

  /// No description provided for @missionStarted.
  ///
  /// In en, this message translates to:
  /// **'Mission Started'**
  String get missionStarted;

  /// No description provided for @missionEnded.
  ///
  /// In en, this message translates to:
  /// **'Mission Ended'**
  String get missionEnded;

  /// No description provided for @autoCheckin.
  ///
  /// In en, this message translates to:
  /// **'Mission started and attendance recorded automatically'**
  String get autoCheckin;

  /// No description provided for @feedbackRequired.
  ///
  /// In en, this message translates to:
  /// **'Please write visit feedback'**
  String get feedbackRequired;

  /// No description provided for @feedbackSaved.
  ///
  /// In en, this message translates to:
  /// **'Feedback saved successfully'**
  String get feedbackSaved;

  /// No description provided for @requestSentToManager.
  ///
  /// In en, this message translates to:
  /// **'Request sent to manager. Awaiting approval.'**
  String get requestSentToManager;

  /// No description provided for @approved_msg.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved_msg;

  /// No description provided for @rejected_msg.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected_msg;

  /// No description provided for @cancelled_msg.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled_msg;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @leavesTab.
  ///
  /// In en, this message translates to:
  /// **'Leaves'**
  String get leavesTab;

  /// No description provided for @requestsTab.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requestsTab;

  /// No description provided for @myMissionsTab.
  ///
  /// In en, this message translates to:
  /// **'Missions'**
  String get myMissionsTab;

  /// No description provided for @myItemsTab.
  ///
  /// In en, this message translates to:
  /// **'My Items'**
  String get myItemsTab;

  /// No description provided for @mainPage.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get mainPage;

  /// No description provided for @pendingTab.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get pendingTab;

  /// No description provided for @attendanceTab.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendanceTab;

  /// No description provided for @locationsTab.
  ///
  /// In en, this message translates to:
  /// **'Locations'**
  String get locationsTab;

  /// No description provided for @interested.
  ///
  /// In en, this message translates to:
  /// **'Interested'**
  String get interested;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
