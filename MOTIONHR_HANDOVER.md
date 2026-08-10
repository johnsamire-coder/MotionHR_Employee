# 📱 MotionHR - الوثيقة الشاملة والمرجع الرسمي

**تاريخ الإصدار:** 2026-08-10
**نوع الوثيقة:** Handover Document + Technical Reference
**نطاق التغطية:** كل شاشات التطبيق، الأدوار، APIs، والانتقالات

---

## 📖 مقدمة

**MotionHR** هو نظام متكامل لإدارة الموارد البشرية يتكون من:
- 📱 **تطبيق موبايل موحّد** (Flutter) - نفس التطبيق لكل الأدوار
- 🌐 **بوابة ويب** (Next.js) - لـ HR وصاحب الشركة
- ⚙️ **Backend** (Django) - يخدم الاتنين

**إجمالي الشاشات:** 127 شاشة
**إجمالي الـ APIs:** 73 endpoint

---

## 📑 جدول المحتويات

1. [👥 الأدوار في النظام](#-الأدوار-في-النظام)
2. [🔐 دور المصادقة (Auth)](#-دور-المصادقة-auth)
3. [👤 دور الموظف](#-دور-الموظف)
4. [👨‍💼 دور المدير](#-دور-المدير)
5. [🏢 دور صاحب الشركة](#-دور-صاحب-الشركة)
6. [💰 نظام الرواتب](#-نظام-الرواتب)
7. [⏰ نظام الشيفتات](#-نظام-الشيفتات)
8. [📊 التقارير](#-التقارير)
9. [🌐 مرجع الـ APIs](#-مرجع-الـ-apis)

---

## 👥 الأدوار في النظام

| الدور | الوصف | الشاشة الرئيسية |
|-------|-------|-------------------|
| **Employee** (موظف) | الموظف العادي - حضور، إجازات، طلبات | `EmployeeShell` |
| **Manager** (مدير) | مدير قسم - يشوف فريقه فقط | `ManagerShell` |
| **Company Admin** (صاحب الشركة) | كامل الصلاحيات | `ManagerDashboard` |
| **HR Manager** (مدير HR) | نفس Company Admin | `ManagerDashboard` |
| **Super Admin** | إدارة النظام كاملة | `ManagerDashboard` |

### 🔀 آلية التوجيه (Routing)

عند تسجيل الدخول، `ManagerHomeRouter` بيقرر أي شاشة يفتح:

```
Login → قراءة role من التخزين
  ↓
  ├─ employee → EmployeeShell
  ├─ manager → ManagerShell (شاشة الموظف + tabs إضافية)
  └─ company_admin/super_admin/owner/hr_manager
     → ManagerDashboard (كل الميزات)
```

---

## 🔐 دور المصادقة (Auth)

> شاشات تسجيل الدخول والتفعيل

### 1. `LoginScreen`

**📝 الوصف:** شاشة تسجيل الدخول الرئيسية - المستخدم يدخل username وpassword
**📁 الملف:** `lib/main.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/charter`
- `/attendance/api/mobile/login`

**➡️ ينتقل إلى:**
- `CharterScreen` - 📜 لائحة الشركة
- `ChangePasswordScreen` - شاشة تغيير كلمة المرور
- `ManagerHomeRouter` - 🎯 موزع ذكي
- `ActivateAccountScreen` - شاشة تفعيل الحساب
- `EmployeeShell` - 🏠 الحاوية الرئيسية للموظف

---

### 2. `ChangePasswordScreen`

**📝 الوصف:** شاشة تغيير كلمة المرور - المستخدم يدخل الكلمة القديمة والجديدة
**📁 الملف:** `lib/main.dart`
**🏷️ العنوان:** l10n.changePassword

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/change-password`

**➡️ ينتقل إلى:**
- `ManagerHomeRouter` - 🎯 موزع ذكي
- `EmployeeShell` - 🏠 الحاوية الرئيسية للموظف

---

### 3. `ActivateAccountScreen`

**📝 الوصف:** شاشة تفعيل الحساب - للحسابات الجديدة اللي محتاجة تفعيل
**📁 الملف:** `lib/screens/auth/activate_account_screen.dart`
**🏷️ العنوان:** تفعيل الحساب لأول مرة / First Time Activation

---

### 4. `SplashScreen`

**📝 الوصف:** شاشة البداية اللي بتظهر عند فتح التطبيق
**📁 الملف:** `lib/main.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/charter`

**➡️ ينتقل إلى:**
- `ManagerHomeRouter` - 🎯 موزع ذكي
- `EmployeeShell` - 🏠 الحاوية الرئيسية للموظف
- `LoginScreen` - شاشة تسجيل الدخول الرئيسية
- `CharterScreen` - 📜 لائحة الشركة

---

## 👤 دور الموظف

> شاشات الموظف العادي - يشوف بياناته الشخصية ويقدم طلبات

### 1. `EmployeeShell`

**📝 الوصف:** 🏠 الحاوية الرئيسية للموظف - فيها 5 تبويبات: Home, Leaves, Requests, Missions, My Items
**📁 الملف:** `lib/main.dart`

**➡️ ينتقل إلى:**
- `OrganizationTreeScreen` - 🌳 الهيكل التنظيمي
- `CharterScreen` - 📜 لائحة الشركة
- `LoginScreen` - شاشة تسجيل الدخول الرئيسية
- `EmployeeProfileScreen` - 👤 الملف الشخصي للموظف
- `SettingsScreen` - ⚙️ الإعدادات العامة
- `ChangePasswordScreen` - شاشة تغيير كلمة المرور
- `AnnouncementsScreen` - 📢 عرض الإعلانات المرسلة للموظفين

---

### 2. `EmployeeHomeScreen`

**📝 الوصف:** 🏠 الشاشة الرئيسية للموظف - Check-in/out، الحضور اليوم، الشيفت
**📁 الملف:** `lib/main.dart`
**🏷️ العنوان:** الرئيسية / Home

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/attendance`
- `/attendance/api/mobile/employee/partial-checkout`
- `/attendance/api/mobile/employee/resume-checkin`
- `/attendance/api/mobile/status/{var}`

**➡️ ينتقل إلى:**
- `FieldVisitsScreen` - 📍 الزيارات الميدانية للموظف
- `MyShiftScreen` - ⏰ شيفت الموظف الحالي
- `MyWorkLocationsScreen` - 📌 مواقع عمل الموظف المعتمدة
- `HistoryScreen` - 📅 سجل الحضور التاريخي للموظف

---

### 3. `LeavesScreen`

**📝 الوصف:** 🌴 شاشة الإجازات والأذونات - عرض الرصيد وتقديم طلبات
**📁 الملف:** `lib/main.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/employee/permission-balance`
- `/attendance/api/mobile/leave-types`

**➡️ ينتقل إلى:**
- `LeaveRequestScreen` - 📝 نموذج تقديم طلب إجازة جديد

---

### 4. `LeaveRequestScreen`

**📝 الوصف:** 📝 نموذج تقديم طلب إجازة جديد
**📁 الملف:** `lib/main.dart`
**🏷️ العنوان:** طلب إجازة / Leave Request

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/leave-request`

---

### 5. `RequestsScreen`

**📝 الوصف:** 📋 شاشة الطلبات - عرض وتقديم طلبات (سلف، شهادات، إلخ)
**📁 الملف:** `lib/screens/employee/requests_screen.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/my-requests`
- `/attendance/api/mobile/request-types`
- `/attendance/api/mobile/submit-request`

**➡️ ينتقل إلى:**

---

### 6. `HistoryScreen`

**📝 الوصف:** 📅 سجل الحضور التاريخي للموظف
**📁 الملف:** `lib/main.dart`
**🏷️ العنوان:** سجل الأيام / Days History

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/history`

---

### 7. `CharterScreen`

**📝 الوصف:** 📜 لائحة الشركة - عرض والموافقة
**📁 الملف:** `lib/main.dart`
**🏷️ العنوان:** لائحة الشركة / Company Charter

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/charter`
- `/attendance/api/mobile/charter/accept`

**➡️ ينتقل إلى:**

---

### 8. `AnnouncementsScreen`

**📝 الوصف:** 📢 عرض الإعلانات المرسلة للموظفين
**📁 الملف:** `lib/screens/employee/announcements_screen.dart`
**🏷️ العنوان:** إعلانات الشركة / Company Announcements

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/announcements/list`

**➡️ ينتقل إلى:**
- `AnnouncementDetailScreen` - 📢 تفاصيل إعلان محدد

---

### 9. `AnnouncementDetailScreen`

**📝 الوصف:** 📢 تفاصيل إعلان محدد
**📁 الملف:** `lib/screens/employee/announcement_detail_screen.dart`
**🏷️ العنوان:** تفاصيل الإعلان / Announcement Details

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/announcements/mark-read`

---

### 10. `NotificationsScreen`

**📝 الوصف:** 🔔 الإشعارات - كل الإشعارات المستلمة
**📁 الملف:** `lib/main.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/notifications`
- `/attendance/api/mobile/notifications/mark-read`

**➡️ ينتقل إلى:**

---

### 11. `EmployeeProfileScreen`

**📝 الوصف:** 👤 الملف الشخصي للموظف
**📁 الملف:** `lib/screens/employee/employee_profile_screen.dart`
**🏷️ العنوان:** l10n.profile

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/employee/profile`

**➡️ ينتقل إلى:**
- `EmployeeMovementsScreen` - 🔄 حركات الموظف (نقل، ترقية)
- `EmployeeDocumentsScreen` - 📄 مستندات الموظف
- `EmployeeSummaryScreen` - 📊 ملخص بيانات الموظف
- `EmployeePayslipScreen` - 💵 كشف رواتب الموظف الشخصي

---

### 12. `EmployeePayslipScreen`

**📝 الوصف:** 💵 كشف رواتب الموظف الشخصي
**📁 الملف:** `lib/screens/employee/employee_payslip_screen.dart`
**🏷️ العنوان:** كشف راتبي / My Payslip

---

### 13. `EmployeeSummaryScreen`

**📝 الوصف:** 📊 ملخص بيانات الموظف
**📁 الملف:** `lib/screens/employee/employee_summary_screen.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/employee/summary`
- `/attendance/api/mobile/manager/employees/{var}/summary`

---

### 14. `EmployeeDocumentsScreen`

**📝 الوصف:** 📄 مستندات الموظف
**📁 الملف:** `lib/screens/employee/employee_documents_screen.dart`
**🏷️ العنوان:** المستندات

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/employee/documents`

---

### 15. `EmployeeMovementsScreen`

**📝 الوصف:** 🔄 حركات الموظف (نقل، ترقية)
**📁 الملف:** `lib/screens/employee/employee_movements_screen.dart`
**🏷️ العنوان:** تاريخ الموظف

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/employee/movements`

---

### 16. `EmployeeMissionsScreen`

**📝 الوصف:** 🎯 مهمات الموظف الميدانية
**📁 الملف:** `lib/screens/employee_missions_screen.dart`
**🏷️ العنوان:** l10n.myMissions

**➡️ ينتقل إلى:**
- `EmployeeMissionDetailScreen` - 🎯 تفاصيل مهمة محددة
- `LocationPickerScreen` - 📍 اختيار موقع من الخريطة

---

### 17. `EmployeeMissionDetailScreen`

**📝 الوصف:** 🎯 تفاصيل مهمة محددة
**📁 الملف:** `lib/screens/employee_mission_detail_screen.dart`

---

### 18. `FieldVisitsScreen`

**📝 الوصف:** 📍 الزيارات الميدانية للموظف
**📁 الملف:** `lib/screens/employee/field_visits_screen.dart`
**🏷️ العنوان:** الزيارات الميدانية / Field Visits

---

### 19. `MyShiftScreen`

**📝 الوصف:** ⏰ شيفت الموظف الحالي
**📁 الملف:** `lib/screens/employee/my_shift_screen.dart`
**🏷️ العنوان:** شيفتي / My Shift

---

### 20. `MyWorkLocationsScreen`

**📝 الوصف:** 📌 مواقع عمل الموظف المعتمدة
**📁 الملف:** `lib/screens/employee/my_work_locations_screen.dart`
**🏷️ العنوان:** مواقع عملي / My Work Locations

---

### 21. `MyItemsScreen`

**📝 الوصف:** 📦 الطلبات والإجازات المقدمة سابقاً
**📁 الملف:** `lib/main.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/my-leaves/{var}/cancel`
- `/attendance/api/mobile/my-requests/{var}/cancel`
- `/attendance/api/mobile/{var}`

**➡️ ينتقل إلى:**
- `ItemDetailScreen` - 📦 تفاصيل طلب/إجازة

---

### 22. `ItemDetailScreen`

**📝 الوصف:** 📦 تفاصيل طلب/إجازة
**📁 الملف:** `lib/screens/employee/item_detail_screen.dart`

---

## 👨‍💼 دور المدير

> شاشات المدير - يشوف فريقه ويوافق على طلباتهم

### 1. `ManagerShell`

**📝 الوصف:** 🏢 الحاوية الرئيسية للمدير - Home, Team, Requests, More
**📁 الملف:** `lib/main.dart`

**➡️ ينتقل إلى:**
- `LoginScreen` - شاشة تسجيل الدخول الرئيسية

---

### 2. `ManagerTeamScreen`

**📝 الوصف:** 👥 عرض فريق المدير
**📁 الملف:** `lib/main.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/attendance`
- `/attendance/api/mobile/manager/live-locations`
- `/attendance/api/mobile/manager/pending`

**➡️ ينتقل إلى:**
- `ManagerMissionsScreen` - 🎯 إدارة المهمات
- `ReportsHubScreen` - 📊 مركز التقارير
- `ManagerPendingScreen` - ⏳ الطلبات المعلقة للموافقة
- `ManagerEmployeesListScreen` - 👥 قائمة كل الموظفين
- `ManagerAttendanceScreen` - 📊 حضور الفريق اليوم
- `ManagerLiveLocationsScreen` - 📍 المواقع المباشرة للموظفين

---

### 3. `ManagerPendingScreen`

**📝 الوصف:** ⏳ الطلبات المعلقة للموافقة
**📁 الملف:** `lib/main.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/action`
- `/attendance/api/mobile/manager/pending`

---

### 4. `ManagerAttendanceScreen`

**📝 الوصف:** 📊 حضور الفريق اليوم
**📁 الملف:** `lib/main.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/attendance`

---

### 5. `ManagerLiveLocationsScreen`

**📝 الوصف:** 📍 المواقع المباشرة للموظفين
**📁 الملف:** `lib/main.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/live-locations`

---

### 6. `ManagerMissionsScreen`

**📝 الوصف:** 🎯 إدارة المهمات
**📁 الملف:** `lib/screens/manager/manager_missions_screen.dart`
**🏷️ العنوان:** إدارة المهمات / Missions Management

**➡️ ينتقل إلى:**
- `MissionDetailScreen`
- `CreateMissionScreen`

---

### 7. `ManagerAnnouncementsScreen`

**📝 الوصف:** 📢 إدارة الإعلانات
**📁 الملف:** `lib/screens/manager/manager_announcements_screen.dart`
**🏷️ العنوان:** إدارة الإعلانات / Manage Announcements

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/announcements/list`
- `/attendance/api/mobile/manager/announcements/${ann`

**➡️ ينتقل إلى:**
- `CreateAnnouncementScreen`

---

### 8. `ManagerMyRequestsHubScreen`

**📝 الوصف:** 📋 طلبات المدير الشخصية
**📁 الملف:** `lib/main.dart`

**➡️ ينتقل إلى:**
- `_ManagerPreviousRequestsWrapperScreen`
- `RequestsScreen` - 📋 شاشة الطلبات
- `_ManagerLeavesPermissionsWrapperScreen`

---

### 9. `ManagerMoreScreen`

**📝 الوصف:** ⚙️ قائمة المزيد للمدير
**📁 الملف:** `lib/main.dart`

**➡️ ينتقل إلى:**
- `ManagerAnnouncementsScreen` - 📢 إدارة الإعلانات
- `_ManagerMyMissionsWrapperScreen`
- `ChangePasswordScreen` - شاشة تغيير كلمة المرور
- `EmployeeProfileScreen` - 👤 الملف الشخصي للموظف
- `FieldVisitsScreen` - 📍 الزيارات الميدانية للموظف
- `SettingsScreen` - ⚙️ الإعدادات العامة
- `_ManagerMyPermissionsWrapperScreen`

---

## 🏢 دور صاحب الشركة

> كل ميزات النظام - إدارة موظفين، سياسات، صلاحيات، تقارير

### 1. `ManagerHomeRouter`

**📝 الوصف:** 🎯 موزع ذكي - يفتح ManagerDashboard لصاحب الشركة و ManagerShell للمدير
**📁 الملف:** `lib/main.dart`

---

### 2. `ManagerDashboard`

**📝 الوصف:** 📊 لوحة تحكم صاحب الشركة الكاملة - كل الميزات في مكان واحد
**📁 الملف:** `lib/main.dart`

**🎴 الميزات المتاحة (Grid Cards):**
- Branches
- Company Charter
- Departments
- Employees
- Flex Adjustments
- Geofence
- Import Tools
- Job Titles
- Live Locations
- Offboarding
- Pending Requests
- Permissions
- Policies Hub
- Shifts
- Today
- Work Locations
- addEmployee
- announcements
- companyInfo
- missions

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/attendance`
- `/attendance/api/mobile/manager/live-locations`
- `/attendance/api/mobile/manager/pending`

**➡️ ينتقل إلى:**
- `CreateEmployeeScreen` - ➕ إضافة موظف جديد
- `CompanyInfoScreen` - 🏢 معلومات الشركة
- `LeaveRecallScreen` - ↩️ استدعاء إجازة
- `ManagerMissionsScreen` - 🎯 إدارة المهمات
- `BranchesScreen` - 🏢 إدارة الفروع
- `ManagerCharterScreen` - 📜 إدارة لائحة الشركة
- `FlexAdjustmentsScreen` - 🔧 تسويات الشيفت المرن
- `OffboardingScreen` - 🚪 إنهاء خدمة موظف
- `JobTitlesScreen` - 💼 إدارة المسميات الوظيفية
- `ManagerLiveLocationsScreen` - 📍 المواقع المباشرة للموظفين
- `ShiftsScreen` - ⏰ إدارة الشيفتات
- `ManagerAnnouncementsScreen` - 📢 إدارة الإعلانات
- `DepartmentsManagementScreen` - 🏛️ إدارة الأقسام
- `PoliciesHubScreen` - 📋 مركز السياسات الرئيسي
- `ManagerGeofenceScreen` - 📍 إعداد النطاق الجغرافي

---

### 3. `ManagerEmployeesListScreen`

**📝 الوصف:** 👥 قائمة كل الموظفين
**📁 الملف:** `lib/screens/manager/manager_employees_list_screen.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/employees`

**➡️ ينتقل إلى:**
- `ManagerEmployeeDetailScreen` - 👤 تفاصيل موظف

---

### 4. `ManagerEmployeeDetailScreen`

**📝 الوصف:** 👤 تفاصيل موظف - عرض وتعديل
**📁 الملف:** `lib/screens/manager/manager_employee_detail_screen.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/employees/{var}`
- `/attendance/api/mobile/manager/employees/{var}/reset-password`
- `/attendance/api/mobile/manager/employees/{var}/update`

**➡️ ينتقل إلى:**
- `EmployeeSummaryScreen` - 📊 ملخص بيانات الموظف

---

### 5. `CreateEmployeeScreen`

**📝 الوصف:** ➕ إضافة موظف جديد
**📁 الملف:** `lib/screens/manager/create_employee_screen.dart`
**🏷️ العنوان:** إضافة موظف جديد / Add New Employee

---

### 6. `ManagerCharterScreen`

**📝 الوصف:** 📜 إدارة لائحة الشركة
**📁 الملف:** `lib/main.dart`
**🏷️ العنوان:** إدارة لائحة الشركة / Company Charter Management

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/charter`
- `/attendance/api/mobile/manager/charter/acceptances`
- `/attendance/api/mobile/manager/charter/update`

**➡️ ينتقل إلى:**
- `CharterReportScreen`

---

### 7. `ManagerGeofenceScreen`

**📝 الوصف:** 📍 إعداد النطاق الجغرافي
**📁 الملف:** `lib/main.dart`
**🏷️ العنوان:** نطاق موقع الشركة / Company Geofence

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/geofence`
- `/attendance/api/mobile/geofence/set`

---

### 8. `CompanyInfoScreen`

**📝 الوصف:** 🏢 معلومات الشركة
**📁 الملف:** `lib/screens/manager/company_info_screen.dart`
**🏷️ العنوان:** l10n.companyInfo

**➡️ ينتقل إلى:**
- `CompanyEditScreen` - ✏️ تعديل بيانات الشركة

---

### 9. `CompanyEditScreen`

**📝 الوصف:** ✏️ تعديل بيانات الشركة
**📁 الملف:** `lib/screens/manager/company_edit_screen.dart`

---

### 10. `DepartmentsManagementScreen`

**📝 الوصف:** 🏛️ إدارة الأقسام
**📁 الملف:** `lib/screens/manager/departments_management_screen.dart`
**🏷️ العنوان:** إدارة الأقسام / Departments

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/departments/add`
- `/attendance/api/mobile/manager/departments/list`
- `/attendance/api/mobile/manager/permissions/roles`

**➡️ ينتقل إلى:**
- `DepartmentDetailScreen` - 🏛️ تفاصيل قسم محدد

---

### 11. `DepartmentDetailScreen`

**📝 الوصف:** 🏛️ تفاصيل قسم محدد
**📁 الملف:** `lib/screens/manager/department_detail_screen.dart`
**🏷️ العنوان:** ${_dept[

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/departments/${_dept`
- `/attendance/api/mobile/manager/departments/list`
- `/attendance/api/mobile/manager/employees`
- `/attendance/api/mobile/manager/employees/{var}/transfer`

---

### 12. `BranchesScreen`

**📝 الوصف:** 🏢 إدارة الفروع
**📁 الملف:** `lib/screens/manager/branches_screen.dart`
**🏷️ العنوان:** الفروع / Branches

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/branches`

---

### 13. `JobTitlesScreen`

**📝 الوصف:** 💼 إدارة المسميات الوظيفية
**📁 الملف:** `lib/screens/manager/job_titles_screen.dart`
**🏷️ العنوان:** المسميات الوظيفية / Job Titles

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/job-titles`

---

### 14. `OrganizationTreeScreen`

**📝 الوصف:** 🌳 الهيكل التنظيمي
**📁 الملف:** `lib/screens/manager/organization_tree_screen.dart`
**🏷️ العنوان:** الهيكل التنظيمي / Organization Tree

---

### 15. `OfficialHolidaysScreen`

**📝 الوصف:** 📅 الإجازات الرسمية
**📁 الملف:** `lib/screens/manager/official_holidays_screen.dart`
**🏷️ العنوان:** الإجازات الرسمية / Official Holidays | إرسال إشعار للموظفين / Notify Employees

**➡️ ينتقل إلى:**

---

### 16. `OffboardingScreen`

**📝 الوصف:** 🚪 إنهاء خدمة موظف
**📁 الملف:** `lib/screens/manager/offboarding_screen.dart`
**🏷️ العنوان:** إنهاء الخدمة / Offboarding

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/employees`
- `/attendance/api/mobile/manager/offboarding/list`
- `/attendance/api/mobile/manager/offboarding/{var}`
- `/attendance/api/mobile/manager/offboarding/{var}/reactivate`

---

### 17. `ImportToolsScreen`

**📝 الوصف:** 📥 استيراد بيانات (Excel)
**📁 الملف:** `lib/screens/manager/import_tools_screen.dart`
**🏷️ العنوان:** أدوات الاستيراد / Import Tools

---

### 18. `ReminderSettingsScreen`

**📝 الوصف:** ⏰ إعدادات التنبيهات
**📁 الملف:** `lib/screens/manager/reminder_settings_screen.dart`
**🏷️ العنوان:** التذكيرات التلقائية / Automatic Reminders

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/reminders/trigger`

---

### 19. `WorkLocationsApprovalScreen`

**📝 الوصف:** 📍 اعتماد مواقع العمل
**📁 الملف:** `lib/screens/manager/work_locations_approval_screen.dart`
**🏷️ العنوان:** مواقع العمل / Work Locations

---

### 20. `LocationReportScreen`

**📝 الوصف:** 📊 تقرير المواقع
**📁 الملف:** `lib/screens/manager/location_report_screen.dart`
**🏷️ العنوان:** تقرير المواقع اليومي / Daily Location Report

---

### 21. `PoliciesHubScreen`

**📝 الوصف:** 📋 مركز السياسات الرئيسي
**📁 الملف:** `lib/screens/manager/policies_hub_screen.dart`
**🏷️ العنوان:** مركز السياسات / Policies Hub

**➡️ ينتقل إلى:**
- `TaxPolicyScreen` - 💸 سياسات الضرائب
- `BonusRulesScreen` - 💰 قواعد المكافآت
- `InsurancePoliciesScreen` - 🏥 سياسات التأمين
- `LeavePolicyScreen` - ⚙️ سياسات الإجازات
- `PayrollCycleScreen` - 🔄 دورات الرواتب
- `EosPolicyScreen` - 👋 سياسات نهاية الخدمة
- `PayrollPolicyScreen` - ⚙️ سياسات الرواتب
- `AttendancePolicyScreen` - ⚙️ سياسات الحضور والانصراف
- `PenaltyRulesScreen` - ⚠️ قواعد الخصومات
- `OfficialHolidaysScreen` - 📅 الإجازات الرسمية
- `LeaveRulesScreen` - 📋 قواعد الإجازات
- `ManualEntriesScreen` - ✏️ إدخالات يدوية
- `AllowanceRulesScreen` - 💵 قواعد البدلات

---

### 22. `AttendancePolicyScreen`

**📝 الوصف:** ⚙️ سياسات الحضور والانصراف
**📁 الملف:** `lib/screens/manager/attendance_policy_screen.dart`
**🏷️ العنوان:** سياسات الحضور والانصراف / Attendance Policies

**➡️ ينتقل إلى:**

---

### 23. `LeavePolicyScreen`

**📝 الوصف:** ⚙️ سياسات الإجازات
**📁 الملف:** `lib/screens/manager/leave_policy_screen.dart`
**🏷️ العنوان:** سياسات الإجازات / Leave Policies | تعديل أرصدة الإجازات / Leave Balance Adjustments | قواعد أنواع الإجازات / Leave Type Rules

**➡️ ينتقل إلى:**

---

### 24. `WorkPolicyScreen`

**📝 الوصف:** ⚙️ سياسات العمل
**📁 الملف:** `lib/screens/manager/work_policy_screen.dart`
**🏷️ العنوان:** إعدادات أيام العمل / Work Days Settings

---

### 25. `PayrollPolicyScreen`

**📝 الوصف:** ⚙️ سياسات الرواتب
**📁 الملف:** `lib/screens/manager/payroll_policy_screen.dart`
**🏷️ العنوان:** سياسة المرتبات / Payroll Policy | قواعد الجزاءات / Disciplinary Rules | الجزاءات التأديبية / Disciplinary Actions

**➡️ ينتقل إلى:**

---

### 26. `LeaveRecallScreen`

**📝 الوصف:** ↩️ استدعاء إجازة
**📁 الملف:** `lib/screens/manager/leave_recall_screen.dart`
**🏷️ العنوان:** استدعاء من الإجازة / Leave Recall

---

### 27. `FlexAdjustmentsScreen`

**📝 الوصف:** 🔧 تسويات الشيفت المرن
**📁 الملف:** `lib/screens/manager/flex_adjustments_screen.dart`
**🏷️ العنوان:** تسويات الشيفت المرن / Flex Shift Adjustments

---

### 28. `PermissionsHubScreen`

**📝 الوصف:** 🔐 مركز الصلاحيات
**📁 الملف:** `lib/screens/manager/permissions_hub_screen.dart`
**🏷️ العنوان:** ${isAr ?  | الصلاحيات الافتراضية / Default Permissions | إدارة الصلاحيات / Permissions

**➡️ ينتقل إلى:**

---

### 29. `PermissionsManagementScreen`

**📝 الوصف:** 🔐 إدارة الصلاحيات
**📁 الملف:** `lib/screens/manager/permissions_management_screen.dart`
**🏷️ العنوان:** إدارة الصلاحيات / Permissions Management

**➡️ ينتقل إلى:**
- `PermissionsExportScreen` - 📤 تصدير الصلاحيات
- `PermissionsAssignScreen` - 👤 تعيين صلاحيات لموظف
- `PermissionsHubScreen` - 🔐 مركز الصلاحيات
- `PermissionsRolesScreen` - 🎭 إدارة الأدوار
- `PermissionsOverridesScreen` - ⚠️ استثناءات الصلاحيات

---

### 30. `PermissionsAssignScreen`

**📝 الوصف:** 👤 تعيين صلاحيات لموظف
**📁 الملف:** `lib/screens/manager/permissions_assign_screen.dart`
**🏷️ العنوان:** تعيين الأدوار / Assign Roles

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/permissions/assign-role`
- `/attendance/api/mobile/manager/permissions/roles`
- `/attendance/api/mobile/manager/permissions/users`

---

### 31. `PermissionsRolesScreen`

**📝 الوصف:** 🎭 إدارة الأدوار
**📁 الملف:** `lib/screens/manager/permissions_roles_screen.dart`
**🏷️ العنوان:** الأدوار / Roles

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/permissions/roles`
- `/attendance/api/mobile/manager/permissions/roles/create`
- `/attendance/api/mobile/manager/permissions/roles/{var}/delete`

**➡️ ينتقل إلى:**
- `RoleDetailScreen` - 🎭 تفاصيل دور محدد

---

### 32. `PermissionsOverridesScreen`

**📝 الوصف:** ⚠️ استثناءات الصلاحيات
**📁 الملف:** `lib/screens/manager/permissions_overrides_screen.dart`
**🏷️ العنوان:** استثناءات المستخدمين / User Overrides | $name

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/permissions/available`
- `/attendance/api/mobile/manager/permissions/override/remove`
- `/attendance/api/mobile/manager/permissions/override/set`
- `/attendance/api/mobile/manager/permissions/users`
- `/attendance/api/mobile/manager/permissions/users/${widget.user`

**➡️ ينتقل إلى:**

---

### 33. `PermissionsExportScreen`

**📝 الوصف:** 📤 تصدير الصلاحيات
**📁 الملف:** `lib/screens/manager/permissions_export_screen.dart`
**🏷️ العنوان:** تصدير الصلاحيات / Export Permissions

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/permissions/export`
- `/attendance/api/mobile/manager/permissions/roles`
- `/attendance/api/mobile/manager/permissions/users`

---

### 34. `EmployeePermissionsScreen`

**📝 الوصف:** 🔐 صلاحيات موظف محدد
**📁 الملف:** `lib/screens/manager/employee_permissions_screen.dart`
**🏷️ العنوان:** أذونات ${widget.employeeName} / ${widget.employeeName} Permissions

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/employees/{var}/permission-balance`
- `/attendance/api/mobile/manager/employees/{var}/permission-grant`
- `/attendance/api/mobile/manager/employees/{var}/permission-rollback`

---

### 35. `RoleDetailScreen`

**📝 الوصف:** 🎭 تفاصيل دور محدد
**📁 الملف:** `lib/screens/manager/role_detail_screen.dart`
**🏷️ العنوان:** تفاصيل الدور / Role Details

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/permissions/available`
- `/attendance/api/mobile/manager/permissions/roles/{var}/update`

---

## 💰 نظام الرواتب

> كل ما يخص الرواتب، البدلات، والسياسات المالية

### 1. `PayrollHubScreen`

**📝 الوصف:** 💰 مركز الرواتب
**📁 الملف:** `lib/screens/manager/payroll/payroll_hub_screen.dart`
**🏷️ العنوان:** نظام الرواتب / Payroll System | l10n.payroll

**➡️ ينتقل إلى:**

---

### 2. `PayrollRunScreen`

**📝 الوصف:** 💵 تشغيل دورة رواتب
**📁 الملف:** `lib/screens/manager/payroll/payroll_run_screen.dart`

**➡️ ينتقل إلى:**
- `PayrollRunDetailScreen` - 💵 تفاصيل دورة رواتب

---

### 3. `PayrollRunDetailScreen`

**📝 الوصف:** 💵 تفاصيل دورة رواتب
**📁 الملف:** `lib/screens/manager/payroll/payroll_run_detail_screen.dart`

**➡️ ينتقل إلى:**
- `PayrollPayslipScreen` - 💵 كشف رواتب
- `PayrollBonusPenaltyScreen` - 💰 المكافآت والخصومات

---

### 4. `PayrollPayslipScreen`

**📝 الوصف:** 💵 كشف رواتب
**📁 الملف:** `lib/screens/manager/payroll/payroll_payslip_screen.dart`

---

### 5. `PayrollSummaryScreen`

**📝 الوصف:** 📊 ملخص الرواتب
**📁 الملف:** `lib/screens/manager/payroll/payroll_summary_screen.dart`
**🏷️ العنوان:** ملخص الرواتب / Payroll Summary

**➡️ ينتقل إلى:**
- `PayrollEmployeeDetailScreen` - 👤 تفاصيل رواتب موظف

---

### 6. `PayrollEmployeeDetailScreen`

**📝 الوصف:** 👤 تفاصيل رواتب موظف
**📁 الملف:** `lib/screens/manager/payroll/payroll_employee_detail_screen.dart`

---

### 7. `PayrollSettingsScreen`

**📝 الوصف:** ⚙️ إعدادات الرواتب
**📁 الملف:** `lib/screens/manager/payroll/payroll_settings_screen.dart`
**🏷️ العنوان:** إعدادات الرواتب / Payroll Settings

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/payroll/settings`

---

### 8. `PayrollCycleScreen`

**📝 الوصف:** 🔄 دورات الرواتب
**📁 الملف:** `lib/screens/manager/payroll/payroll_cycle_screen.dart`
**🏷️ العنوان:** دورة الرواتب

**➡️ ينتقل إلى:**
- `CreateEditPayrollCycleScreen` - ✏️ إنشاء/تعديل دورة

---

### 9. `PayrollBonusPenaltyScreen`

**📝 الوصف:** 💰 المكافآت والخصومات
**📁 الملف:** `lib/screens/manager/payroll/payroll_bonus_penalty_screen.dart`

---

### 10. `CompanyPoliciesScreen`

**📝 الوصف:** 📋 سياسات الشركة المالية
**📁 الملف:** `lib/screens/manager/payroll/company_policies_screen.dart`
**🏷️ العنوان:** السياسات العامة / Company Policies | شهري / Monthly

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager`

**➡️ ينتقل إلى:**

---

### 11. `ManualEntriesScreen`

**📝 الوصف:** ✏️ إدخالات يدوية
**📁 الملف:** `lib/screens/manager/payroll/manual_entries_screen.dart`
**🏷️ العنوان:** الإدخالات اليدوية

---

### 12. `TaxPolicyScreen`

**📝 الوصف:** 💸 سياسات الضرائب
**📁 الملف:** `lib/screens/manager/payroll/tax_policy_screen.dart`
**🏷️ العنوان:** سياسة الضرائب

**➡️ ينتقل إلى:**
- `CreateEditTaxPolicyScreen` - ✏️ إنشاء/تعديل سياسة ضريبة

---

### 13. `InsurancePoliciesScreen`

**📝 الوصف:** 🏥 سياسات التأمين
**📁 الملف:** `lib/screens/manager/payroll/insurance_policies_screen.dart`
**🏷️ العنوان:** سياسات التأمين

**➡️ ينتقل إلى:**
- `CreateEditInsurancePolicyScreen` - ✏️ إنشاء/تعديل تأمين

---

### 14. `EosPolicyScreen`

**📝 الوصف:** 👋 سياسات نهاية الخدمة
**📁 الملف:** `lib/screens/manager/payroll/eos_policy_screen.dart`
**🏷️ العنوان:** مكافأة نهاية الخدمة

**➡️ ينتقل إلى:**
- `CreateEditEosPolicyScreen` - ✏️ إنشاء/تعديل نهاية خدمة

---

### 15. `LeaveRulesScreen`

**📝 الوصف:** 📋 قواعد الإجازات
**📁 الملف:** `lib/screens/manager/payroll/leave_rules_screen.dart`
**🏷️ العنوان:** قواعد الإجازات

**➡️ ينتقل إلى:**
- `CreateEditLeaveRuleScreen` - ✏️ إنشاء/تعديل قاعدة إجازة

---

### 16. `BonusRulesScreen`

**📝 الوصف:** 💰 قواعد المكافآت
**📁 الملف:** `lib/screens/manager/payroll/bonus_rules_screen.dart`
**🏷️ العنوان:** قواعد المكافآت والأوفرتايم

**➡️ ينتقل إلى:**
- `CreateEditBonusRuleScreen` - ✏️ إنشاء/تعديل مكافأة

---

### 17. `PenaltyRulesScreen`

**📝 الوصف:** ⚠️ قواعد الخصومات
**📁 الملف:** `lib/screens/manager/payroll/penalty_rules_screen.dart`
**🏷️ العنوان:** قواعد الجزاءات

**➡️ ينتقل إلى:**
- `CreateEditPenaltyRuleScreen` - ✏️ إنشاء/تعديل خصم

---

### 18. `AllowanceRulesScreen`

**📝 الوصف:** 💵 قواعد البدلات
**📁 الملف:** `lib/screens/manager/payroll/allowance_rules_screen.dart`
**🏷️ العنوان:** قواعد البدلات

**➡️ ينتقل إلى:**
- `CreateEditAllowanceRuleScreen` - ✏️ إنشاء/تعديل بدل

---

### 19. `CreateEditAllowanceRuleScreen`

**📝 الوصف:** ✏️ إنشاء/تعديل بدل
**📁 الملف:** `lib/screens/manager/payroll/create_edit_allowance_rule_screen.dart`

---

### 20. `CreateEditBonusRuleScreen`

**📝 الوصف:** ✏️ إنشاء/تعديل مكافأة
**📁 الملف:** `lib/screens/manager/payroll/create_edit_bonus_rule_screen.dart`

---

### 21. `CreateEditPenaltyRuleScreen`

**📝 الوصف:** ✏️ إنشاء/تعديل خصم
**📁 الملف:** `lib/screens/manager/payroll/create_edit_penalty_rule_screen.dart`

---

### 22. `CreateEditLeaveRuleScreen`

**📝 الوصف:** ✏️ إنشاء/تعديل قاعدة إجازة
**📁 الملف:** `lib/screens/manager/payroll/create_edit_leave_rule_screen.dart`

---

### 23. `CreateEditTaxPolicyScreen`

**📝 الوصف:** ✏️ إنشاء/تعديل سياسة ضريبة
**📁 الملف:** `lib/screens/manager/payroll/create_edit_tax_policy_screen.dart`
**🏷️ العنوان:** إعفاء حصة الموظف من التأمين الاجتماعي

---

### 24. `CreateEditInsurancePolicyScreen`

**📝 الوصف:** ✏️ إنشاء/تعديل تأمين
**📁 الملف:** `lib/screens/manager/payroll/create_edit_insurance_policy_screen.dart`

---

### 25. `CreateEditEosPolicyScreen`

**📝 الوصف:** ✏️ إنشاء/تعديل نهاية خدمة
**📁 الملف:** `lib/screens/manager/payroll/create_edit_eos_policy_screen.dart`
**🏷️ العنوان:** تشمل البدلات في أساس الحساب

---

### 26. `CreateEditPayrollCycleScreen`

**📝 الوصف:** ✏️ إنشاء/تعديل دورة
**📁 الملف:** `lib/screens/manager/payroll/create_edit_payroll_cycle_screen.dart`

---

## ⏰ نظام الشيفتات

> إدارة الشيفتات والمناوبات

### 1. `ShiftsScreen`

**📝 الوصف:** ⏰ إدارة الشيفتات
**📁 الملف:** `lib/screens/manager/shifts/shifts_screen.dart`
**🏷️ العنوان:** إدارة الشيفتات / Shift Management

**➡️ ينتقل إلى:**
- `ShiftOverrideScreen` - 🔄 استثناءات الشيفتات
- `CreateEditShiftScreen` - ✏️ إنشاء/تعديل شيفت
- `AssignmentDetailScreen` - 📋 تفاصيل تعيين شيفت
- `ShiftRotationScreen` - 🔁 دوران الشيفتات
- `AssignShiftScreen` - 📌 تعيين شيفت لموظف

---

### 2. `CreateEditShiftScreen`

**📝 الوصف:** ✏️ إنشاء/تعديل شيفت
**📁 الملف:** `lib/screens/manager/shifts/create_edit_shift_screen.dart`
**🏷️ العنوان:** يمتد لليوم التالي (ليلي) / Crosses midnight

---

### 3. `AssignShiftScreen`

**📝 الوصف:** 📌 تعيين شيفت لموظف
**📁 الملف:** `lib/screens/manager/shifts/assign_shift_screen.dart`

---

### 4. `AssignmentDetailScreen`

**📝 الوصف:** 📋 تفاصيل تعيين شيفت
**📁 الملف:** `lib/screens/manager/shifts/assignment_detail_screen.dart`
**🏷️ العنوان:** تفاصيل التعيين / Assignment Details

---

### 5. `ShiftOverrideScreen`

**📝 الوصف:** 🔄 استثناءات الشيفتات
**📁 الملف:** `lib/screens/manager/shifts/shift_override_screen.dart`
**🏷️ العنوان:** استثناءات الشيفتات / Shift Overrides

---

### 6. `ShiftRotationScreen`

**📝 الوصف:** 🔁 دوران الشيفتات
**📁 الملف:** `lib/screens/manager/shifts/shift_rotation_screen.dart`
**🏷️ العنوان:** تناوب الشيفتات / Shift Rotation

---

## 📊 التقارير

> كل التقارير المتاحة في النظام

### 1. `ReportsHubScreen`

**📝 الوصف:** 📊 مركز التقارير
**📁 الملف:** `lib/screens/manager/reports/reports_hub_screen.dart`
**🏷️ العنوان:** l10n.reports

**➡️ ينتقل إلى:**

---

### 2. `AttendanceReportScreen`

**📝 الوصف:** 📊 تقرير الحضور الشهري
**📁 الملف:** `lib/screens/manager/reports/attendance_report_screen.dart`

---

### 3. `DailyAttendanceReportScreen`

**📝 الوصف:** 📊 تقرير الحضور اليومي
**📁 الملف:** `lib/screens/manager/reports/daily_attendance_report_screen.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/reports/daily-attendance`

---

### 4. `AbsenceReportScreen`

**📝 الوصف:** 📊 تقرير الغياب
**📁 الملف:** `lib/screens/manager/reports/absence_report_screen.dart`

---

### 5. `LateReportScreen`

**📝 الوصف:** 📊 تقرير التأخيرات
**📁 الملف:** `lib/screens/manager/reports/late_report_screen.dart`

---

### 6. `WorkHoursReportScreen`

**📝 الوصف:** 📊 تقرير ساعات العمل
**📁 الملف:** `lib/screens/manager/reports/work_hours_report_screen.dart`

---

### 7. `LeavesReportScreen`

**📝 الوصف:** 📊 تقرير الإجازات الأساسي
**📁 الملف:** `lib/screens/manager/reports/leaves_report_screen.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/my-leaves/{var}/cancel`

---

### 8. `LeavesEnhancedReportScreen`

**📝 الوصف:** 📊 تقرير الإجازات المطوّر
**📁 الملف:** `lib/screens/manager/reports/leaves_enhanced_report_screen.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/reports/leaves-enhanced`

---

### 9. `RequestsReportScreen`

**📝 الوصف:** 📊 تقرير الطلبات
**📁 الملف:** `lib/screens/manager/reports/requests_report_screen.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/action`

---

### 10. `PermissionsReportScreen`

**📝 الوصف:** 📊 تقرير الأذونات
**📁 الملف:** `lib/screens/manager/reports/permissions_report_screen.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/reports/permissions`

---

### 11. `ShiftsReportScreen`

**📝 الوصف:** 📊 تقرير الشيفتات
**📁 الملف:** `lib/screens/manager/reports/shifts_report_screen.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/reports/shifts`

---

### 12. `PayrollReportScreen`

**📝 الوصف:** 📊 تقرير الرواتب
**📁 الملف:** `lib/screens/manager/reports/payroll_report_screen.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/reports/payroll`

---

### 13. `CharterReportScreen`

**📝 الوصف:** شاشة في النظام
**📁 الملف:** `lib/main.dart`
**🏷️ العنوان:** تقرير الموافقات / Approvals Report

---

## 🌐 مرجع الـ APIs

**إجمالي الـ APIs المستخدمة:** 73

### 📢 الإعلانات (2 API)

- `/attendance/api/mobile/announcements/list`
- `/attendance/api/mobile/announcements/mark-read`

### 📊 الحضور (1 API)

- `/attendance/api/mobile/attendance`

### 🏢 الفروع (1 API)

- `/attendance/api/mobile/branches`

### 🔑 تغيير كلمة السر (1 API)

- `/attendance/api/mobile/change-password`

### 📜 اللائحة (2 API)

- `/attendance/api/mobile/charter`
- `/attendance/api/mobile/charter/accept`

### 👤 الموظف (7 API)

- `/attendance/api/mobile/employee/documents`
- `/attendance/api/mobile/employee/movements`
- `/attendance/api/mobile/employee/partial-checkout`
- `/attendance/api/mobile/employee/permission-balance`
- `/attendance/api/mobile/employee/profile`
- `/attendance/api/mobile/employee/resume-checkin`
- `/attendance/api/mobile/employee/summary`

### 📍 النطاق الجغرافي (2 API)

- `/attendance/api/mobile/geofence`
- `/attendance/api/mobile/geofence/set`

### 📅 السجل (1 API)

- `/attendance/api/mobile/history`

### 💼 المسميات (1 API)

- `/attendance/api/mobile/job-titles`

### 🌴 طلب إجازة (1 API)

- `/attendance/api/mobile/leave-request`

### 🌴 أنواع الإجازات (1 API)

- `/attendance/api/mobile/leave-types`

### 🔐 تسجيل الدخول (1 API)

- `/attendance/api/mobile/login`

### 👨‍💼 المدير (43 API)

- `/attendance/api/mobile/manager`
- `/attendance/api/mobile/manager/action`
- `/attendance/api/mobile/manager/announcements/${ann`
- `/attendance/api/mobile/manager/announcements/${widget.announcement`
- `/attendance/api/mobile/manager/announcements/create`
- `/attendance/api/mobile/manager/attendance`
- `/attendance/api/mobile/manager/charter/acceptances`
- `/attendance/api/mobile/manager/charter/update`
- `/attendance/api/mobile/manager/departments/${_dept`
- `/attendance/api/mobile/manager/departments/add`
- `/attendance/api/mobile/manager/departments/list`
- `/attendance/api/mobile/manager/employees`
- `/attendance/api/mobile/manager/employees/{var}`
- `/attendance/api/mobile/manager/employees/{var}/permission-balance`
- `/attendance/api/mobile/manager/employees/{var}/permission-grant`
- `/attendance/api/mobile/manager/employees/{var}/permission-rollback`
- `/attendance/api/mobile/manager/employees/{var}/reset-password`
- `/attendance/api/mobile/manager/employees/{var}/summary`
- `/attendance/api/mobile/manager/employees/{var}/transfer`
- `/attendance/api/mobile/manager/employees/{var}/update`
- `/attendance/api/mobile/manager/live-locations`
- `/attendance/api/mobile/manager/offboarding/list`
- `/attendance/api/mobile/manager/offboarding/{var}`
- `/attendance/api/mobile/manager/offboarding/{var}/reactivate`
- `/attendance/api/mobile/manager/payroll/settings`
- `/attendance/api/mobile/manager/pending`
- `/attendance/api/mobile/manager/permissions/assign-role`
- `/attendance/api/mobile/manager/permissions/available`
- `/attendance/api/mobile/manager/permissions/export`
- `/attendance/api/mobile/manager/permissions/override/remove`
- `/attendance/api/mobile/manager/permissions/override/set`
- `/attendance/api/mobile/manager/permissions/roles`
- `/attendance/api/mobile/manager/permissions/roles/create`
- `/attendance/api/mobile/manager/permissions/roles/{var}/delete`
- `/attendance/api/mobile/manager/permissions/roles/{var}/update`
- `/attendance/api/mobile/manager/permissions/users`
- `/attendance/api/mobile/manager/permissions/users/${widget.user`
- `/attendance/api/mobile/manager/reminders/trigger`
- `/attendance/api/mobile/manager/reports/daily-attendance`
- `/attendance/api/mobile/manager/reports/leaves-enhanced`
- `/attendance/api/mobile/manager/reports/payroll`
- `/attendance/api/mobile/manager/reports/permissions`
- `/attendance/api/mobile/manager/reports/shifts`

### 🌴 إجازاتي (1 API)

- `/attendance/api/mobile/my-leaves/{var}/cancel`

### 📋 طلباتي (2 API)

- `/attendance/api/mobile/my-requests`
- `/attendance/api/mobile/my-requests/{var}/cancel`

### 🔔 الإشعارات (2 API)

- `/attendance/api/mobile/notifications`
- `/attendance/api/mobile/notifications/mark-read`

### 📝 أنواع الطلبات (1 API)

- `/attendance/api/mobile/request-types`

### 📊 الحالة (1 API)

- `/attendance/api/mobile/status/{var}`

### 📝 تقديم طلب (1 API)

- `/attendance/api/mobile/submit-request`

### 📂 {var} (1 API)

- `/attendance/api/mobile/{var}`

---

## 📞 ملاحظات نهائية

- ✅ التطبيق **موحّد** لكل الأدوار (App واحد)
- ✅ الـ Routing بيتم عن طريق **role** من الباك إند
- ✅ كل الميزات **مطابقة** بين الويب والموبايل
- ⏰ **Base URL الحالي:** `https://app.jssolutions-eg.com`
- 📱 **Flutter Version:** 3.44.6+
- 🔄 آخر تحديث: مطابق مع GitHub main branch

---

*تم إنشاء هذه الوثيقة تلقائياً باستخدام أدوات فحص الكود المتقدمة*