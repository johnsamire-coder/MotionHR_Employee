# 🎯 MotionHR - وثيقة الميزات الشاملة (v3)

**تاريخ الإصدار:** 2026-08-10 10:25
**نطاق التغطية:** UI + Background Services + Auto Actions

---

## 🔒 الميزات الخفية / Background Services

> **مهم:** دي ميزات بتشتغل في الخلفية بدون تفاعل من المستخدم

### 🔥 Firebase Cloud Messaging (FCM)

**الوظيفة:** استقبال Push Notifications من السيرفر

**الميزات:**
- ✅ Firebase Cloud Messaging
- ✅ Firebase Background Handler (يعمل حتى مع إغلاق التطبيق)
- ✅ Background Message Handler

**Trigger:** يبدأ تلقائياً عند فتح التطبيق
**Behavior:** يستقبل إشعارات حتى لو التطبيق مقفول

---

### 📍 Background Location Tracking

**الوظيفة:** تتبع موقع الموظف بشكل دوري

**الميزات:**
- ✅ Background Tracking (تتبع خلفي)
- ✅ Stop Tracking on Logout

**Trigger:** يبدأ بعد Login وينتهي عند Logout
**Frequency:** كل ساعة (Timer.periodic)
**Permissions:** Location (Always)

---

### ⚡ Auto Actions (الإجراءات التلقائية)

- ✅ Auto Check-in Monitoring (بدء المراقبة عند الدخول)
- ✅ Location Tracking (تتبع الموقع كل ساعة)
- ✅ Stop Location Tracking

---

## ⚙️ خدمات النظام (Services)

**العدد الإجمالي:** 41 service

### 🔴 Background Services (بتشتغل في الخلفية) - 3

#### 📦 `auto_checkin_service.dart`
**📁 الملف:** `lib/services/auto_checkin_service.dart`

**🎯 الميزات:**
- ✅ Geolocator (تحديد الموقع)
- ✅ SharedPreferences (تخزين محلي)

**⏰ Timers (توقيتات):**
- `minutes: 2`

**🔐 الصلاحيات المطلوبة:** Location

**🔧 الـ Methods:**
- `_getToken()`
- `syncStateFromBackend()`
- `_checkAndProcess()`
- `_performAutoCheckin()`
- `startMonitoring()`
- `_getCurrentPosition()`
- `_checkPermissions()`
- `_performAutoCheckout()`
- `stopMonitoring()`
- `_resetDailyState()`

**🌐 APIs:**
- `/attendance/api/mobile/employee/auto-check-in`
- `/attendance/api/mobile/employee/auto-check-out`
- `/attendance/api/mobile/employee/auto-checkin-status`
- `/attendance/api/mobile/manager/geofence`

---

#### 📦 `location_tracking_service.dart`
**📁 الملف:** `lib/services/location_tracking_service.dart`

**🎯 الميزات:**
- ✅ Geolocator (تحديد الموقع)
- ✅ Offline Queue (طابور طلبات أوفلاين)

**⏰ Timers (توقيتات):**
- `hours: 1`

**🔐 الصلاحيات المطلوبة:** Location

**🔧 الـ Methods:**
- `startTracking()`
- `_saveCurrentLocation()`
- `stopTracking()`

**🌐 APIs:**
- `/attendance/api/mobile/employee/save-location`
- `/attendance/api/mobile/manager/location-report`

---

#### 📦 `offline_queue_service.dart`
**📁 الملف:** `lib/services/offline_queue_service.dart`

**🎯 الميزات:**
- ✅ Offline Queue (طابور طلبات أوفلاين)

**⏰ Timers (توقيتات):**
- `seconds: 30`

**🔧 الـ Methods:**
- `_initDb()`
- `enqueue()`
- `_processRow()`
- `clearAll()`
- `startAutoSync()`
- `getPendingCount()`
- `syncAll()`
- `stopAutoSync()`

---

### 🔵 Regular Services - 38

#### `allowance_rule_service.dart`
**📁 الملف:** `lib/services/allowance_rule_service.dart`
**🔧 Methods:** `deleteRule`
**🌐 APIs:** 1
  - `/attendance/api/mobile/manager/rules/allowance`

#### `api_client.dart`
**📁 الملف:** `lib/services/api_client.dart`

#### `api_service.dart`
**📁 الملف:** `lib/services/api_service.dart`
**🎯 الميزات:**
- SharedPreferences (تخزين محلي)

#### `app_strings.dart`
**📁 الملف:** `lib/services/app_strings.dart`

#### `attachment_service.dart`
**📁 الملف:** `lib/services/attachment_service.dart`
**🎯 الميزات:**
- SharedPreferences (تخزين محلي)
**🔧 Methods:** `_getToken`, `pickImageFromCamera`, `downloadAndOpen`, `upload`, `delete`, `pickFile`, `pickImageFromGallery`
**🌐 APIs:** 4
  - `/attendance/api/mobile/attachments/list`
  - `/attendance/api/mobile/attachments/upload`
  - `/attendance/api/mobile/attachments/{var}/delete`
  - `/attendance/api/mobile/attachments/{var}/download`

#### `attendance_policy_service.dart`
**📁 الملف:** `lib/services/attendance_policy_service.dart`
**🔧 Methods:** `deletePolicy`
**🌐 APIs:** 4
  - `/attendance/api/mobile/manager/attendance-policy`
  - `/attendance/api/mobile/manager/attendance-policy/{var}`
  - `/attendance/api/mobile/manager/attendance-policy/{var}/approve`
  - `/attendance/api/mobile/manager/attendance-policy/{var}/assign`

#### `auth_storage_service.dart`
**📁 الملف:** `lib/services/auth_storage_service.dart`
**🎯 الميزات:**
- SharedPreferences (تخزين محلي)
**🔧 Methods:** `getSavedToken`, `clearStayLoggedIn`, `saveRememberMe`, `saveToken`, `clearAll`, `refreshLoginTime`, `saveStayLoggedIn`

#### `biometric_auth_service.dart`
**📁 الملف:** `lib/services/biometric_auth_service.dart`
**🔧 Methods:** `authenticate`, `isBiometricAvailable`

#### `bonus_rule_service.dart`
**📁 الملف:** `lib/services/bonus_rule_service.dart`
**🔧 Methods:** `deleteRule`
**🌐 APIs:** 1
  - `/attendance/api/mobile/manager/rules/bonus`

#### `branding_service.dart`
**📁 الملف:** `lib/services/branding_service.dart`
**🔧 Methods:** `ensureFontsLoaded`, `clearCache`

#### `connectivity_service.dart`
**📁 الملف:** `lib/services/connectivity_service.dart`
**🔧 Methods:** `hasInternetConnection`

#### `disciplinary_service.dart`
**📁 الملف:** `lib/services/disciplinary_service.dart`
**🔧 Methods:** `deleteRule`
**🌐 APIs:** 4
  - `/attendance/api/mobile/manager/attendance-policy/{var}/disciplinary-rules`
  - `/attendance/api/mobile/manager/attendance-policy/{var}/disciplinary-rules/{var}`
  - `/attendance/api/mobile/manager/disciplinary/actions`
  - `/attendance/api/mobile/manager/disciplinary/actions/{var}/review`

#### `employee_management_service.dart`
**📁 الملف:** `lib/services/employee_management_service.dart`
**🔧 Methods:** `updateCompanyInfo`, `uploadCompanyLogo`
**🌐 APIs:** 11
  - `/accounts/api/mobile/activate-account`
  - `/attendance/api/mobile/manager/branches`
  - `/attendance/api/mobile/manager/company-info`
  - `/attendance/api/mobile/manager/company-info/update`
  - `/attendance/api/mobile/manager/company-info/upload-logo`

#### `employee_pdf_service.dart`
**📁 الملف:** `lib/services/employee_pdf_service.dart`
**🔧 Methods:** `generateEmployeePdf`, `openWhatsApp`, `sharePdf`

#### `eos_policy_service.dart`
**📁 الملف:** `lib/services/eos_policy_service.dart`
**🔧 Methods:** `deletePolicy`
**🌐 APIs:** 2
  - `/attendance/api/mobile/manager/eos/calculate`
  - `/attendance/api/mobile/manager/eos/policies`

#### `field_visits_service.dart`
**📁 الملف:** `lib/services/field_visits_service.dart`
**🎯 الميزات:**
- SharedPreferences (تخزين محلي)

#### `flex_adjustment_service.dart`
**📁 الملف:** `lib/services/flex_adjustment_service.dart`
**🔧 Methods:** `reviewFlexAdjustment`
**🌐 APIs:** 3
  - `/attendance/api/mobile/manager/employees/{var}/flex-adjustments`
  - `/attendance/api/mobile/manager/flex-adjustments`
  - `/attendance/api/mobile/manager/flex-adjustments/{var}/review`

#### `insurance_policy_service.dart`
**📁 الملف:** `lib/services/insurance_policy_service.dart`
**🔧 Methods:** `deletePolicy`
**🌐 APIs:** 1
  - `/attendance/api/mobile/manager`

#### `language_service.dart`
**📁 الملف:** `lib/services/language_service.dart`
**🎯 الميزات:**
- SharedPreferences (تخزين محلي)
**🔧 Methods:** `loadSavedLanguage`, `changeLanguage`

#### `leave_policy_service.dart`
**📁 الملف:** `lib/services/leave_policy_service.dart`
**🔧 Methods:** `deletePolicy`
**🌐 APIs:** 6
  - `/attendance/api/mobile/leave-types`
  - `/attendance/api/mobile/manager/leave-balance-adjustments`
  - `/attendance/api/mobile/manager/leave-policy`
  - `/attendance/api/mobile/manager/leave-policy/apply-to-existing`
  - `/attendance/api/mobile/manager/leave-policy/{var}`

#### `leave_rule_service.dart`
**📁 الملف:** `lib/services/leave_rule_service.dart`
**🔧 Methods:** `deleteRule`
**🌐 APIs:** 1
  - `/attendance/api/mobile/manager/rules/leave`

#### `local_notification_service.dart`
**📁 الملف:** `lib/services/local_notification_service.dart`
**🎯 الميزات:**
- Local Notifications (تنبيهات محلية)
**🔧 Methods:** `init`, `showSyncSuccess`, `show`

#### `lookups_service.dart`
**📁 الملف:** `lib/services/lookups_service.dart`
**🌐 APIs:** 1
  - `/attendance/api/mobile/manager`

#### `manual_entries_service.dart`
**📁 الملف:** `lib/services/manual_entries_service.dart`
**🌐 APIs:** 1
  - `/attendance/api/mobile/manager/entries`

#### `missions_service.dart`
**📁 الملف:** `lib/services/missions_service.dart`
**🌐 APIs:** 9
  - `/employee/missions`
  - `/employee/missions/assignments/{var}/end`
  - `/employee/missions/assignments/{var}/locations`
  - `/employee/missions/assignments/{var}/respond`
  - `/employee/missions/assignments/{var}/start`

#### `official_holidays_service.dart`
**📁 الملف:** `lib/services/official_holidays_service.dart`
**🔧 Methods:** `deleteHoliday`
**🌐 APIs:** 2
  - `/attendance/api/mobile/manager/official-holidays`
  - `/attendance/api/mobile/manager/official-holidays/{var}`

#### `payroll_cycle_service.dart`
**📁 الملف:** `lib/services/payroll_cycle_service.dart`
**🔧 Methods:** `deletePolicy`
**🌐 APIs:** 1
  - `/attendance/api/mobile/manager/payroll-cycle-policies`

#### `payroll_run_service.dart`
**📁 الملف:** `lib/services/payroll_run_service.dart`

#### `payroll_service.dart`
**📁 الملف:** `lib/services/payroll_service.dart`
**🎯 الميزات:**
- SharedPreferences (تخزين محلي)

#### `penalty_rule_service.dart`
**📁 الملف:** `lib/services/penalty_rule_service.dart`
**🔧 Methods:** `deleteRule`
**🌐 APIs:** 1
  - `/attendance/api/mobile/manager/rules/penalty`

#### `permissions_service.dart`
**📁 الملف:** `lib/services/permissions_service.dart`
**🔧 Methods:** `setRoleOverride`
**🌐 APIs:** 4
  - `/attendance/api/mobile/manager/permissions/defaults`
  - `/attendance/api/mobile/manager/permissions/override/bulk`
  - `/attendance/api/mobile/manager/permissions/summary`
  - `/attendance/api/mobile/permissions/my`

#### `report_excel_service.dart`
**📁 الملف:** `lib/services/report_excel_service.dart`
**🔧 Methods:** `exportLateReport`, `exportAbsenceReport`, `exportPayrollRunReport`, `exportAndOpen`, `exportLocationReport`, `exportRequestsReport`, `_buildAndSave`, `exportAndShare`

#### `report_pdf_service.dart`
**📁 الملف:** `lib/services/report_pdf_service.dart`
**🔧 Methods:** `printReport`

#### `reports_service.dart`
**📁 الملف:** `lib/services/reports_service.dart`
**🎯 الميزات:**
- SharedPreferences (تخزين محلي)

#### `shifts_service.dart`
**📁 الملف:** `lib/services/shifts_service.dart`
**🔧 Methods:** `deleteShiftOverride`, `deleteAssignment`, `updateAssignment`, `deleteShift`, `deleteRotation`
**🌐 APIs:** 23
  - `/attendance/api/mobile/leave-recall/create`
  - `/attendance/api/mobile/leave-recall/list`
  - `/attendance/api/mobile/leave-recall/{var}/review`
  - `/attendance/api/mobile/manager/employees/{var}/effective-shift`
  - `/attendance/api/mobile/manager/employees/{var}/shifts`

#### `tax_policy_service.dart`
**📁 الملف:** `lib/services/tax_policy_service.dart`
**🔧 Methods:** `deletePolicy`
**🌐 APIs:** 2
  - `/attendance/api/mobile/manager/tax/calculate`
  - `/attendance/api/mobile/manager/tax/policies`

#### `work_locations_service.dart`
**📁 الملف:** `lib/services/work_locations_service.dart`
**🎯 الميزات:**
- SharedPreferences (تخزين محلي)

#### `work_policy_service.dart`
**📁 الملف:** `lib/services/work_policy_service.dart`
**🎯 الميزات:**
- SharedPreferences (تخزين محلي)
**🔧 Methods:** `_getToken`, `savePolicy`

---

## 🔧 background_service.dart (الملف الرئيسي للـ Background)

**📁 الملف:** `lib/background_service.dart`

**🎯 الميزات:**
- Geolocator (تحديد الموقع)
- SharedPreferences (تخزين محلي)

---

## 📊 الإحصائيات النهائية

| القسم | العدد |
|-------|-------|
| Background Services | 3 |
| Regular Services | 38 |
| Firebase Features | 3 |
| Background Tasks | 2 |
| Auto Actions | 3 |
