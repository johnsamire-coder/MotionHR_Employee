# 📋 MotionHR - التقرير الشامل والمفصّل (v2)

**النطاق:** كل الشاشات، التبويبات، الأزرار، الـ APIs، والانتقالات
**المصدر:** فحص Flutter code — كل class بمحتواه الخاص

---

## 📊 الملخص التنفيذي

| القسم | العدد |
|-------|-------|
| 👤 شاشات الموظف | 25 |
| 👨‍💼 شاشات المدير/صاحب الشركة | 49 |
| 💰 شاشات الرواتب | 26 |
| ⏰ شاشات الشيفتات | 6 |
| 📊 شاشات التقارير | 13 |
| 🔐 شاشات المصادقة | 4 |
| 🔧 المشتركة | 1 |
| 🌐 المشتركة العامة | 3 |
| **الإجمالي** | **127** |

---

## 👤 شاشات الموظف
### عدد الشاشات: 25

### 1. `AnnouncementDetailScreen`

**📁 الملف:** `lib/screens/employee/announcement_detail_screen.dart`

**🏷️ عنوان الشاشة:**
- تفاصيل الإعلان / Announcement Details

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/announcements/mark-read`

---

### 2. `AnnouncementsScreen`

**📁 الملف:** `lib/screens/employee/announcements_screen.dart`

**🏷️ عنوان الشاشة:**
- إعلانات الشركة / Company Announcements

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/announcements/list`

**➡️ تنتقل إلى:**
- `AnnouncementDetailScreen`

---

### 3. `CharterReportScreen`

**📁 الملف:** `lib/main.dart`

**🏷️ عنوان الشاشة:**
- تقرير الموافقات / Approvals Report

---

### 4. `CharterScreen`

**📁 الملف:** `lib/main.dart`

**🏷️ عنوان الشاشة:**
- لائحة الشركة / Company Charter

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/charter`
- `/attendance/api/mobile/charter/accept`

**➡️ تنتقل إلى:**
- `widget`

---

### 5. `EmployeeDocumentsScreen`

**📁 الملف:** `lib/screens/employee/employee_documents_screen.dart`

**🏷️ عنوان الشاشة:**
- المستندات

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/employee/documents`

---

### 6. `EmployeeHomeScreen`

**📁 الملف:** `lib/main.dart`

**🏷️ عنوان الشاشة:**
- الرئيسية / Home

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/attendance`
- `/attendance/api/mobile/employee/partial-checkout`
- `/attendance/api/mobile/employee/resume-checkin`
- `/attendance/api/mobile/status/{var}`

**➡️ تنتقل إلى:**
- `HistoryScreen`
- `FieldVisitsScreen`
- `MyWorkLocationsScreen`
- `MyShiftScreen`

---

### 7. `EmployeeMissionDetailScreen`

**📁 الملف:** `lib/screens/employee_mission_detail_screen.dart`

**📋 عناصر القائمة (List Tiles):**
- يحتاج متابعة

---

### 8. `EmployeeMissionsScreen`

**📁 الملف:** `lib/screens/employee_missions_screen.dart`

**🏷️ عنوان الشاشة:**
- l10n.myMissions

**➡️ تنتقل إلى:**
- `EmployeeMissionDetailScreen`
- `LocationPickerScreen`

---

### 9. `EmployeeMovementsScreen`

**📁 الملف:** `lib/screens/employee/employee_movements_screen.dart`

**🏷️ عنوان الشاشة:**
- تاريخ الموظف

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/employee/movements`

---

### 10. `EmployeePayslipScreen`

**📁 الملف:** `lib/screens/employee/employee_payslip_screen.dart`

**🏷️ عنوان الشاشة:**
- كشف راتبي / My Payslip

---

### 11. `EmployeeProfileScreen`

**📁 الملف:** `lib/screens/employee/employee_profile_screen.dart`

**🏷️ عنوان الشاشة:**
- l10n.profile

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/employee/profile`

**➡️ تنتقل إلى:**
- `EmployeeMovementsScreen`
- `EmployeePayslipScreen`
- `EmployeeSummaryScreen`
- `EmployeeDocumentsScreen`

---

### 12. `EmployeeShell`

**📁 الملف:** `lib/main.dart`

**➡️ تنتقل إلى:**
- `OrganizationTreeScreen`
- `EmployeeProfileScreen`
- `LoginScreen`
- `ChangePasswordScreen`
- `SettingsScreen`
- `AnnouncementsScreen`
- `CharterScreen`

---

### 13. `EmployeeSummaryScreen`

**📁 الملف:** `lib/screens/employee/employee_summary_screen.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/employee/summary`
- `/attendance/api/mobile/manager/employees/{var}/summary`

---

### 14. `FieldVisitsScreen`

**📁 الملف:** `lib/screens/employee/field_visits_screen.dart`

**🏷️ عنوان الشاشة:**
- الزيارات الميدانية / Field Visits

---

### 15. `HistoryScreen`

**📁 الملف:** `lib/main.dart`

**🏷️ عنوان الشاشة:**
- سجل الأيام / Days History

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/history`

---

### 16. `ItemDetailScreen`

**📁 الملف:** `lib/screens/employee/item_detail_screen.dart`

---

### 17. `LeaveRequestScreen`

**📁 الملف:** `lib/main.dart`

**🏷️ عنوان الشاشة:**
- طلب إجازة / Leave Request

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/leave-request`

---

### 18. `LeavesScreen`

**📁 الملف:** `lib/main.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/employee/permission-balance`
- `/attendance/api/mobile/leave-types`

**➡️ تنتقل إلى:**
- `LeaveRequestScreen`

---

### 19. `ManagerCharterScreen`

**📁 الملف:** `lib/main.dart`

**🏷️ عنوان الشاشة:**
- إدارة لائحة الشركة / Company Charter Management

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/charter`
- `/attendance/api/mobile/manager/charter/acceptances`
- `/attendance/api/mobile/manager/charter/update`

**➡️ تنتقل إلى:**
- `CharterReportScreen`

---

### 20. `MyItemsScreen`

**📁 الملف:** `lib/main.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/my-leaves/{var}/cancel`
- `/attendance/api/mobile/my-requests/{var}/cancel`
- `/attendance/api/mobile/{var}`

**➡️ تنتقل إلى:**
- `ItemDetailScreen`

---

### 21. `MyShiftScreen`

**📁 الملف:** `lib/screens/employee/my_shift_screen.dart`

**🏷️ عنوان الشاشة:**
- شيفتي / My Shift

---

### 22. `MyWorkLocationsScreen`

**📁 الملف:** `lib/screens/employee/my_work_locations_screen.dart`

**🏷️ عنوان الشاشة:**
- مواقع عملي / My Work Locations

---

### 23. `NotificationsScreen`

**📁 الملف:** `lib/main.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/notifications`
- `/attendance/api/mobile/notifications/mark-read`

**➡️ تنتقل إلى:**
- `page`

---

### 24. `RequestsScreen`

**📁 الملف:** `lib/screens/employee/requests_screen.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/my-requests`
- `/attendance/api/mobile/request-types`
- `/attendance/api/mobile/submit-request`

**➡️ تنتقل إلى:**
- `RequestFormScreen`

---

### 25. `_ManagerLeavesPermissionsWrapperScreen`

**📁 الملف:** `lib/main.dart`

**🏷️ عنوان الشاشة:**
- إجازاتي وأذوناتي / My Leaves & Permissions

---

## 👨‍💼 شاشات المدير/صاحب الشركة
### عدد الشاشات: 49

### 1. `AttendancePolicyScreen`

**📁 الملف:** `lib/screens/manager/attendance_policy_screen.dart`

**🏷️ عنوان الشاشة:**
- سياسات الحضور والانصراف / Attendance Policies

**➡️ تنتقل إلى:**
- `CreateEditPolicyScreen`

---

### 2. `BranchesScreen`

**📁 الملف:** `lib/screens/manager/branches_screen.dart`

**🏷️ عنوان الشاشة:**
- الفروع / Branches

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/branches`

---

### 3. `CompanyEditScreen`

**📁 الملف:** `lib/screens/manager/company_edit_screen.dart`

---

### 4. `CompanyInfoScreen`

**📁 الملف:** `lib/screens/manager/company_info_screen.dart`

**🏷️ عنوان الشاشة:**
- l10n.companyInfo

**➡️ تنتقل إلى:**
- `CompanyEditScreen`

---

### 5. `CreateAnnouncementScreen`

**📁 الملف:** `lib/screens/manager/create_announcement_screen.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/announcements/${widget.announcement`
- `/attendance/api/mobile/manager/announcements/create`

---

### 6. `CreateEmployeeScreen`

**📁 الملف:** `lib/screens/manager/create_employee_screen.dart`

**🏷️ عنوان الشاشة:**
- إضافة موظف جديد / Add New Employee

---

### 7. `CreateMissionScreen`

**📁 الملف:** `lib/screens/manager/create_mission_screen.dart`

**🏷️ عنوان الشاشة:**
- إنشاء مهمة جديدة / Create New Mission

**➡️ تنتقل إلى:**
- `LocationPickerScreen`

---

### 8. `DepartmentDetailScreen`

**📁 الملف:** `lib/screens/manager/department_detail_screen.dart`

**🏷️ عنوان الشاشة:**
- ${_dept[

**📋 عناصر القائمة (List Tiles):**
- ${d[

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/departments/${_dept`
- `/attendance/api/mobile/manager/departments/list`
- `/attendance/api/mobile/manager/employees`
- `/attendance/api/mobile/manager/employees/{var}/transfer`

---

### 9. `DepartmentsManagementScreen`

**📁 الملف:** `lib/screens/manager/departments_management_screen.dart`

**🏷️ عنوان الشاشة:**
- إدارة الأقسام / Departments

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/departments/add`
- `/attendance/api/mobile/manager/departments/list`
- `/attendance/api/mobile/manager/permissions/roles`

**➡️ تنتقل إلى:**
- `DepartmentDetailScreen`

---

### 10. `EmployeePermissionsScreen`

**📁 الملف:** `lib/screens/manager/employee_permissions_screen.dart`

**🏷️ عنوان الشاشة:**
- أذونات ${widget.employeeName} / ${widget.employeeName} Permissions

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/employees/{var}/permission-balance`
- `/attendance/api/mobile/manager/employees/{var}/permission-grant`
- `/attendance/api/mobile/manager/employees/{var}/permission-rollback`

---

### 11. `FlexAdjustmentsScreen`

**📁 الملف:** `lib/screens/manager/flex_adjustments_screen.dart`

**🏷️ عنوان الشاشة:**
- تسويات الشيفت المرن / Flex Shift Adjustments

---

### 12. `ImportToolsScreen`

**📁 الملف:** `lib/screens/manager/import_tools_screen.dart`

**🏷️ عنوان الشاشة:**
- أدوات الاستيراد / Import Tools

---

### 13. `JobTitlesScreen`

**📁 الملف:** `lib/screens/manager/job_titles_screen.dart`

**🏷️ عنوان الشاشة:**
- المسميات الوظيفية / Job Titles

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/job-titles`

---

### 14. `LeavePolicyScreen`

**📁 الملف:** `lib/screens/manager/leave_policy_screen.dart`

**🏷️ عنوان الشاشة:**
- قواعد أنواع الإجازات / Leave Type Rules
- سياسات الإجازات / Leave Policies
- تعديل أرصدة الإجازات / Leave Balance Adjustments

**➡️ تنتقل إلى:**
- `LeaveBalanceAdjustmentScreen`
- `LeaveTypeRulesScreen`
- `CreateEditLeavePolicyScreen`

---

### 15. `LeaveRecallScreen`

**📁 الملف:** `lib/screens/manager/leave_recall_screen.dart`

**🏷️ عنوان الشاشة:**
- استدعاء من الإجازة / Leave Recall

---

### 16. `LocationReportScreen`

**📁 الملف:** `lib/screens/manager/location_report_screen.dart`

**🏷️ عنوان الشاشة:**
- تقرير المواقع اليومي / Daily Location Report

---

### 17. `ManagerAnnouncementsScreen`

**📁 الملف:** `lib/screens/manager/manager_announcements_screen.dart`

**🏷️ عنوان الشاشة:**
- إدارة الإعلانات / Manage Announcements

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/announcements/list`
- `/attendance/api/mobile/manager/announcements/${ann`

**➡️ تنتقل إلى:**
- `CreateAnnouncementScreen`

---

### 18. `ManagerAttendanceScreen`

**📁 الملف:** `lib/main.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/attendance`

---

### 19. `ManagerDashboard`

**📁 الملف:** `lib/main.dart`

**🎴 الكارتات الرئيسية (Grid Cards):**
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
- organizationTree
- payroll
- reminders
- reports
- أدوات الاستيراد
- إدارة الأقسام
- إنهاء الخدمة
- استدعاء / Leave Recall
- الحضور اليوم
- الشيفتات

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/attendance`
- `/attendance/api/mobile/manager/live-locations`
- `/attendance/api/mobile/manager/pending`

**➡️ تنتقل إلى:**
- `ManagerPendingScreen`
- `WorkLocationsApprovalScreen`
- `ManagerAnnouncementsScreen`
- `CompanyInfoScreen`
- `ImportToolsScreen`
- `FlexAdjustmentsScreen`
- `ManagerCharterScreen`
- `ManagerLiveLocationsScreen`
- `PoliciesHubScreen`
- `JobTitlesScreen`
- `PayrollHubScreen`
- `ManagerEmployeesListScreen`
- `DepartmentsManagementScreen`
- `ReportsHubScreen`
- `PermissionsManagementScreen`
- `LeaveRecallScreen`
- `ManagerAttendanceScreen`
- `ManagerMissionsScreen`
- `ManagerGeofenceScreen`
- `ShiftsScreen`

---

### 20. `ManagerEmployeeDetailScreen`

**📁 الملف:** `lib/screens/manager/manager_employee_detail_screen.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/employees/{var}`
- `/attendance/api/mobile/manager/employees/{var}/reset-password`
- `/attendance/api/mobile/manager/employees/{var}/update`

**➡️ تنتقل إلى:**
- `EmployeeSummaryScreen`

---

### 21. `ManagerEmployeesListScreen`

**📁 الملف:** `lib/screens/manager/manager_employees_list_screen.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/employees`

**➡️ تنتقل إلى:**
- `ManagerEmployeeDetailScreen`

---

### 22. `ManagerGeofenceScreen`

**📁 الملف:** `lib/main.dart`

**🏷️ عنوان الشاشة:**
- نطاق موقع الشركة / Company Geofence

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/geofence`
- `/attendance/api/mobile/geofence/set`

---

### 23. `ManagerHomeRouter`

**📁 الملف:** `lib/main.dart`

---

### 24. `ManagerLiveLocationsScreen`

**📁 الملف:** `lib/main.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/live-locations`

---

### 25. `ManagerMissionsScreen`

**📁 الملف:** `lib/screens/manager/manager_missions_screen.dart`

**🏷️ عنوان الشاشة:**
- إدارة المهمات / Missions Management

**➡️ تنتقل إلى:**
- `CreateMissionScreen`
- `MissionDetailScreen`

---

### 26. `ManagerMoreScreen`

**📁 الملف:** `lib/main.dart`

**➡️ تنتقل إلى:**
- `ManagerAnnouncementsScreen`
- `EmployeeProfileScreen`
- `ChangePasswordScreen`
- `_ManagerMyMissionsWrapperScreen`
- `SettingsScreen`
- `FieldVisitsScreen`
- `_ManagerMyPermissionsWrapperScreen`

---

### 27. `ManagerMyRequestsHubScreen`

**📁 الملف:** `lib/main.dart`

**➡️ تنتقل إلى:**
- `_ManagerLeavesPermissionsWrapperScreen`
- `RequestsScreen`
- `_ManagerPreviousRequestsWrapperScreen`

---

### 28. `ManagerPendingScreen`

**📁 الملف:** `lib/main.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/action`
- `/attendance/api/mobile/manager/pending`

---

### 29. `ManagerShell`

**📁 الملف:** `lib/main.dart`

**➡️ تنتقل إلى:**
- `LoginScreen`

---

### 30. `ManagerTeamScreen`

**📁 الملف:** `lib/main.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/attendance`
- `/attendance/api/mobile/manager/live-locations`
- `/attendance/api/mobile/manager/pending`

**➡️ تنتقل إلى:**
- `ManagerPendingScreen`
- `ReportsHubScreen`
- `ManagerLiveLocationsScreen`
- `ManagerEmployeesListScreen`
- `ManagerAttendanceScreen`
- `ManagerMissionsScreen`

---

### 31. `MissionDetailScreen`

**📁 الملف:** `lib/screens/manager/mission_detail_screen.dart`

---

### 32. `OffboardingScreen`

**📁 الملف:** `lib/screens/manager/offboarding_screen.dart`

**🏷️ عنوان الشاشة:**
- إنهاء الخدمة / Offboarding

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/employees`
- `/attendance/api/mobile/manager/offboarding/list`
- `/attendance/api/mobile/manager/offboarding/{var}`
- `/attendance/api/mobile/manager/offboarding/{var}/reactivate`

---

### 33. `OfficialHolidaysScreen`

**📁 الملف:** `lib/screens/manager/official_holidays_screen.dart`

**🏷️ عنوان الشاشة:**
- الإجازات الرسمية / Official Holidays
- إرسال إشعار للموظفين / Notify Employees

**➡️ تنتقل إلى:**
- `CreateEditOfficialHolidayScreen`

---

### 34. `OrganizationTreeScreen`

**📁 الملف:** `lib/screens/manager/organization_tree_screen.dart`

**🏷️ عنوان الشاشة:**
- الهيكل التنظيمي / Organization Tree

---

### 35. `PayrollPolicyScreen`

**📁 الملف:** `lib/screens/manager/payroll_policy_screen.dart`

**🏷️ عنوان الشاشة:**
- سياسة المرتبات / Payroll Policy
- الجزاءات التأديبية / Disciplinary Actions
- قواعد الجزاءات / Disciplinary Rules
- تعديل سياسة المرتبات / Edit Payroll Policy

**➡️ تنتقل إلى:**
- `DisciplinaryActionsScreen`
- `EditPayrollPolicyScreen`
- `DisciplinaryRulesScreen`

---

### 36. `PermissionsAssignScreen`

**📁 الملف:** `lib/screens/manager/permissions_assign_screen.dart`

**🏷️ عنوان الشاشة:**
- تعيين الأدوار / Assign Roles

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/permissions/assign-role`
- `/attendance/api/mobile/manager/permissions/roles`
- `/attendance/api/mobile/manager/permissions/users`

---

### 37. `PermissionsExportScreen`

**📁 الملف:** `lib/screens/manager/permissions_export_screen.dart`

**🏷️ عنوان الشاشة:**
- تصدير الصلاحيات / Export Permissions

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/permissions/export`
- `/attendance/api/mobile/manager/permissions/roles`
- `/attendance/api/mobile/manager/permissions/users`

---

### 38. `PermissionsHubScreen`

**📁 الملف:** `lib/screens/manager/permissions_hub_screen.dart`

**🏷️ عنوان الشاشة:**
- الصلاحيات الافتراضية / Default Permissions
- إدارة الصلاحيات / Permissions
- ${isAr ? 

**➡️ تنتقل إلى:**
- `PermissionsTargetScreen`
- `DefaultRolePermissionsScreen`

---

### 39. `PermissionsManagementScreen`

**📁 الملف:** `lib/screens/manager/permissions_management_screen.dart`

**🏷️ عنوان الشاشة:**
- إدارة الصلاحيات / Permissions Management

**➡️ تنتقل إلى:**
- `PermissionsRolesScreen`
- `PermissionsHubScreen`
- `PermissionsExportScreen`
- `PermissionsAssignScreen`
- `PermissionsOverridesScreen`

---

### 40. `PermissionsOverridesScreen`

**📁 الملف:** `lib/screens/manager/permissions_overrides_screen.dart`

**🏷️ عنوان الشاشة:**
- استثناءات المستخدمين / User Overrides
- $name

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/permissions/available`
- `/attendance/api/mobile/manager/permissions/override/remove`
- `/attendance/api/mobile/manager/permissions/override/set`
- `/attendance/api/mobile/manager/permissions/users`
- `/attendance/api/mobile/manager/permissions/users/${widget.user`

**➡️ تنتقل إلى:**
- `_UserOverrideCheckboxScreen`

---

### 41. `PermissionsRolesScreen`

**📁 الملف:** `lib/screens/manager/permissions_roles_screen.dart`

**🏷️ عنوان الشاشة:**
- الأدوار / Roles

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/permissions/roles`
- `/attendance/api/mobile/manager/permissions/roles/create`
- `/attendance/api/mobile/manager/permissions/roles/{var}/delete`

**➡️ تنتقل إلى:**
- `RoleDetailScreen`

---

### 42. `PoliciesHubScreen`

**📁 الملف:** `lib/screens/manager/policies_hub_screen.dart`

**🏷️ عنوان الشاشة:**
- مركز السياسات / Policies Hub

**➡️ تنتقل إلى:**
- `AttendancePolicyScreen`
- `AllowanceRulesScreen`
- `TaxPolicyScreen`
- `BonusRulesScreen`
- `LeaveRulesScreen`
- `LeavePolicyScreen`
- `EosPolicyScreen`
- `ManualEntriesScreen`
- `OfficialHolidaysScreen`
- `PenaltyRulesScreen`
- `PayrollCycleScreen`
- `PayrollPolicyScreen`
- `InsurancePoliciesScreen`

---

### 43. `ReminderSettingsScreen`

**📁 الملف:** `lib/screens/manager/reminder_settings_screen.dart`

**🏷️ عنوان الشاشة:**
- التذكيرات التلقائية / Automatic Reminders

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/reminders/trigger`

---

### 44. `RoleDetailScreen`

**📁 الملف:** `lib/screens/manager/role_detail_screen.dart`

**🏷️ عنوان الشاشة:**
- تفاصيل الدور / Role Details

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/permissions/available`
- `/attendance/api/mobile/manager/permissions/roles/{var}/update`

---

### 45. `WorkLocationsApprovalScreen`

**📁 الملف:** `lib/screens/manager/work_locations_approval_screen.dart`

**🏷️ عنوان الشاشة:**
- مواقع العمل / Work Locations

---

### 46. `WorkPolicyScreen`

**📁 الملف:** `lib/screens/manager/work_policy_screen.dart`

**🏷️ عنوان الشاشة:**
- إعدادات أيام العمل / Work Days Settings

---

### 47. `_ManagerMyMissionsWrapperScreen`

**📁 الملف:** `lib/main.dart`

**🏷️ عنوان الشاشة:**
- مهماتي / My Missions

---

### 48. `_ManagerMyPermissionsWrapperScreen`

**📁 الملف:** `lib/main.dart`

**🏷️ عنوان الشاشة:**
- أذوناتي / My Permissions

---

### 49. `_ManagerPreviousRequestsWrapperScreen`

**📁 الملف:** `lib/main.dart`

**🏷️ عنوان الشاشة:**
- طلباتي السابقة / Previous Requests

---

## 💰 شاشات الرواتب
### عدد الشاشات: 26

### 1. `AllowanceRulesScreen`

**📁 الملف:** `lib/screens/manager/payroll/allowance_rules_screen.dart`

**🏷️ عنوان الشاشة:**
- قواعد البدلات

**➡️ تنتقل إلى:**
- `CreateEditAllowanceRuleScreen`

---

### 2. `BonusRulesScreen`

**📁 الملف:** `lib/screens/manager/payroll/bonus_rules_screen.dart`

**🏷️ عنوان الشاشة:**
- قواعد المكافآت والأوفرتايم

**➡️ تنتقل إلى:**
- `CreateEditBonusRuleScreen`

---

### 3. `CompanyPoliciesScreen`

**📁 الملف:** `lib/screens/manager/payroll/company_policies_screen.dart`

**🏷️ عنوان الشاشة:**
- شهري / Monthly
- السياسات العامة / Company Policies

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager`

**➡️ تنتقل إلى:**
- `AddEditPolicyScreen`

---

### 4. `CreateEditAllowanceRuleScreen`

**📁 الملف:** `lib/screens/manager/payroll/create_edit_allowance_rule_screen.dart`

**🔘 الأزرار:**
- حفظ

---

### 5. `CreateEditBonusRuleScreen`

**📁 الملف:** `lib/screens/manager/payroll/create_edit_bonus_rule_screen.dart`

**🔘 الأزرار:**
- حفظ

---

### 6. `CreateEditEosPolicyScreen`

**📁 الملف:** `lib/screens/manager/payroll/create_edit_eos_policy_screen.dart`

**🏷️ عنوان الشاشة:**
- تشمل البدلات في أساس الحساب

**📋 عناصر القائمة (List Tiles):**
- تشمل البدلات في أساس الحساب

**🔘 الأزرار:**
- حفظ

---

### 7. `CreateEditInsurancePolicyScreen`

**📁 الملف:** `lib/screens/manager/payroll/create_edit_insurance_policy_screen.dart`

**🔘 الأزرار:**
- حفظ

---

### 8. `CreateEditLeaveRuleScreen`

**📁 الملف:** `lib/screens/manager/payroll/create_edit_leave_rule_screen.dart`

**🔘 الأزرار:**
- حفظ

---

### 9. `CreateEditPayrollCycleScreen`

**📁 الملف:** `lib/screens/manager/payroll/create_edit_payroll_cycle_screen.dart`

**📋 عناصر القائمة (List Tiles):**
- توليد Payroll تلقائي يوم القفل
- الموافقة مطلوبة قبل الصرف
- السياسة نشطة

**🔘 الأزرار:**
- حفظ

---

### 10. `CreateEditPenaltyRuleScreen`

**📁 الملف:** `lib/screens/manager/payroll/create_edit_penalty_rule_screen.dart`

**🔘 الأزرار:**
- حفظ

---

### 11. `CreateEditTaxPolicyScreen`

**📁 الملف:** `lib/screens/manager/payroll/create_edit_tax_policy_screen.dart`

**🏷️ عنوان الشاشة:**
- إعفاء حصة الموظف من التأمين الاجتماعي

**📋 عناصر القائمة (List Tiles):**
- إعفاء حصة الموظف من التأمين الطبي
- إعفاء حصة الموظف من التأمين الاجتماعي

**🔘 الأزرار:**
- حفظ

---

### 12. `EosPolicyScreen`

**📁 الملف:** `lib/screens/manager/payroll/eos_policy_screen.dart`

**🏷️ عنوان الشاشة:**
- مكافأة نهاية الخدمة

**🔘 الأزرار:**
- إعادة المحاولة

**➡️ تنتقل إلى:**
- `CreateEditEosPolicyScreen`

---

### 13. `InsurancePoliciesScreen`

**📁 الملف:** `lib/screens/manager/payroll/insurance_policies_screen.dart`

**🏷️ عنوان الشاشة:**
- سياسات التأمين

**📑 التبويبات (Tabs):**
- طبي ($medicalCount)
- اجتماعي ($socialCount)
- الكل (${_policies.length})

**🔘 الأزرار:**
- إعادة المحاولة

**➡️ تنتقل إلى:**
- `CreateEditInsurancePolicyScreen`

---

### 14. `LeaveRulesScreen`

**📁 الملف:** `lib/screens/manager/payroll/leave_rules_screen.dart`

**🏷️ عنوان الشاشة:**
- قواعد الإجازات

**➡️ تنتقل إلى:**
- `CreateEditLeaveRuleScreen`

---

### 15. `ManualEntriesScreen`

**📁 الملف:** `lib/screens/manager/payroll/manual_entries_screen.dart`

**🏷️ عنوان الشاشة:**
- الإدخالات اليدوية

**📑 التبويبات (Tabs):**
- جزاءات
- بدلات
- مكافآت

---

### 16. `PayrollBonusPenaltyScreen`

**📁 الملف:** `lib/screens/manager/payroll/payroll_bonus_penalty_screen.dart`

---

### 17. `PayrollCycleScreen`

**📁 الملف:** `lib/screens/manager/payroll/payroll_cycle_screen.dart`

**🏷️ عنوان الشاشة:**
- دورة الرواتب

**🔘 الأزرار:**
- إعادة المحاولة

**➡️ تنتقل إلى:**
- `CreateEditPayrollCycleScreen`

---

### 18. `PayrollEmployeeDetailScreen`

**📁 الملف:** `lib/screens/manager/payroll/payroll_employee_detail_screen.dart`

---

### 19. `PayrollHubScreen`

**📁 الملف:** `lib/screens/manager/payroll/payroll_hub_screen.dart`

**🏷️ عنوان الشاشة:**
- l10n.payroll
- نظام الرواتب / Payroll System

**➡️ تنتقل إلى:**
- `screen`

---

### 20. `PayrollPayslipScreen`

**📁 الملف:** `lib/screens/manager/payroll/payroll_payslip_screen.dart`

---

### 21. `PayrollRunDetailScreen`

**📁 الملف:** `lib/screens/manager/payroll/payroll_run_detail_screen.dart`

**➡️ تنتقل إلى:**
- `PayrollBonusPenaltyScreen`
- `PayrollPayslipScreen`

---

### 22. `PayrollRunScreen`

**📁 الملف:** `lib/screens/manager/payroll/payroll_run_screen.dart`

**➡️ تنتقل إلى:**
- `PayrollRunDetailScreen`

---

### 23. `PayrollSettingsScreen`

**📁 الملف:** `lib/screens/manager/payroll/payroll_settings_screen.dart`

**🏷️ عنوان الشاشة:**
- إعدادات الرواتب / Payroll Settings

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/payroll/settings`

---

### 24. `PayrollSummaryScreen`

**📁 الملف:** `lib/screens/manager/payroll/payroll_summary_screen.dart`

**🏷️ عنوان الشاشة:**
- ملخص الرواتب / Payroll Summary

**➡️ تنتقل إلى:**
- `PayrollEmployeeDetailScreen`

---

### 25. `PenaltyRulesScreen`

**📁 الملف:** `lib/screens/manager/payroll/penalty_rules_screen.dart`

**🏷️ عنوان الشاشة:**
- قواعد الجزاءات

**➡️ تنتقل إلى:**
- `CreateEditPenaltyRuleScreen`

---

### 26. `TaxPolicyScreen`

**📁 الملف:** `lib/screens/manager/payroll/tax_policy_screen.dart`

**🏷️ عنوان الشاشة:**
- سياسة الضرائب

**🔘 الأزرار:**
- إعادة المحاولة

**➡️ تنتقل إلى:**
- `CreateEditTaxPolicyScreen`

---

## ⏰ شاشات الشيفتات
### عدد الشاشات: 6

### 1. `AssignShiftScreen`

**📁 الملف:** `lib/screens/manager/shifts/assign_shift_screen.dart`

---

### 2. `AssignmentDetailScreen`

**📁 الملف:** `lib/screens/manager/shifts/assignment_detail_screen.dart`

**🏷️ عنوان الشاشة:**
- تفاصيل التعيين / Assignment Details

---

### 3. `CreateEditShiftScreen`

**📁 الملف:** `lib/screens/manager/shifts/create_edit_shift_screen.dart`

**🏷️ عنوان الشاشة:**
- يمتد لليوم التالي (ليلي) / Crosses midnight

---

### 4. `ShiftOverrideScreen`

**📁 الملف:** `lib/screens/manager/shifts/shift_override_screen.dart`

**🏷️ عنوان الشاشة:**
- استثناءات الشيفتات / Shift Overrides

---

### 5. `ShiftRotationScreen`

**📁 الملف:** `lib/screens/manager/shifts/shift_rotation_screen.dart`

**🏷️ عنوان الشاشة:**
- تناوب الشيفتات / Shift Rotation

---

### 6. `ShiftsScreen`

**📁 الملف:** `lib/screens/manager/shifts/shifts_screen.dart`

**🏷️ عنوان الشاشة:**
- إدارة الشيفتات / Shift Management

**➡️ تنتقل إلى:**
- `AssignmentDetailScreen`
- `AssignShiftScreen`
- `CreateEditShiftScreen`
- `ShiftOverrideScreen`
- `ShiftRotationScreen`

---

## 📊 شاشات التقارير
### عدد الشاشات: 13

### 1. `AbsenceReportScreen`

**📁 الملف:** `lib/screens/manager/reports/absence_report_screen.dart`

---

### 2. `AttendanceReportScreen`

**📁 الملف:** `lib/screens/manager/reports/attendance_report_screen.dart`

---

### 3. `BaseReportScreen`

**📁 الملف:** `lib/screens/manager/reports/base_report_screen.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/{var}`

---

### 4. `DailyAttendanceReportScreen`

**📁 الملف:** `lib/screens/manager/reports/daily_attendance_report_screen.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/reports/daily-attendance`

---

### 5. `LateReportScreen`

**📁 الملف:** `lib/screens/manager/reports/late_report_screen.dart`

---

### 6. `LeavesEnhancedReportScreen`

**📁 الملف:** `lib/screens/manager/reports/leaves_enhanced_report_screen.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/reports/leaves-enhanced`

---

### 7. `LeavesReportScreen`

**📁 الملف:** `lib/screens/manager/reports/leaves_report_screen.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/my-leaves/{var}/cancel`

---

### 8. `PayrollReportScreen`

**📁 الملف:** `lib/screens/manager/reports/payroll_report_screen.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/reports/payroll`

---

### 9. `PermissionsReportScreen`

**📁 الملف:** `lib/screens/manager/reports/permissions_report_screen.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/reports/permissions`

---

### 10. `ReportsHubScreen`

**📁 الملف:** `lib/screens/manager/reports/reports_hub_screen.dart`

**🏷️ عنوان الشاشة:**
- l10n.reports

**➡️ تنتقل إلى:**
- `screen`

---

### 11. `RequestsReportScreen`

**📁 الملف:** `lib/screens/manager/reports/requests_report_screen.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/action`

---

### 12. `ShiftsReportScreen`

**📁 الملف:** `lib/screens/manager/reports/shifts_report_screen.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/manager/reports/shifts`

---

### 13. `WorkHoursReportScreen`

**📁 الملف:** `lib/screens/manager/reports/work_hours_report_screen.dart`

---

## 🔐 شاشات المصادقة
### عدد الشاشات: 4

### 1. `ActivateAccountScreen`

**📁 الملف:** `lib/screens/auth/activate_account_screen.dart`

**🏷️ عنوان الشاشة:**
- تفعيل الحساب لأول مرة / First Time Activation

---

### 2. `ChangePasswordScreen`

**📁 الملف:** `lib/main.dart`

**🏷️ عنوان الشاشة:**
- l10n.changePassword

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/change-password`

**➡️ تنتقل إلى:**
- `EmployeeShell`
- `ManagerHomeRouter`

---

### 3. `LoginScreen`

**📁 الملف:** `lib/main.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/charter`
- `/attendance/api/mobile/login`

**➡️ تنتقل إلى:**
- `ChangePasswordScreen`
- `EmployeeShell`
- `ActivateAccountScreen`
- `ManagerHomeRouter`
- `CharterScreen`

---

### 4. `SplashScreen`

**📁 الملف:** `lib/main.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/charter`

**➡️ تنتقل إلى:**
- `EmployeeShell`
- `LoginScreen`
- `ManagerHomeRouter`
- `CharterScreen`

---

## 🔧 المشتركة
### عدد الشاشات: 1

### 1. `LocationPickerScreen`

**📁 الملف:** `lib/screens/common/location_picker_screen.dart`

**🏷️ عنوان الشاشة:**
- اختر الموقع / Pick Location

---

## 🌐 المشتركة العامة
### عدد الشاشات: 3

### 1. `FirstLaunchLanguageScreen`

**📁 الملف:** `lib/screens/first_launch_language_screen.dart`

---

### 2. `OldRequestsScreen`

**📁 الملف:** `lib/main.dart`

**🌐 الـ APIs المستخدمة:**
- `/attendance/api/mobile/request-types`
- `/attendance/api/mobile/submit-request`

---

### 3. `SettingsScreen`

**📁 الملف:** `lib/screens/settings_screen.dart`

**🏷️ عنوان الشاشة:**
- الإعدادات / Settings

---
