# 📊 MotionHR - Feature-Level Comparison Report

## 📈 Summary

| Metric | Count |
|--------|-------|
| Web Pages | 91 |
| Mobile Screens | 100 |
| Web Features | 88 |
| Mobile Features | 95 |
| ✅ Matched Features | 60 |
| ❌ Missing in Mobile | 28 |
| 📱 Extra in Mobile (not in Web) | 42 |

## ❌ Web Features Missing in Mobile

**Total: 28**

| Web Feature | Web Route | Expected Mobile |
|-------------|-----------|-----------------|
| `employee:leaves` | `/employee/leaves` | `employee:leaves` |
| `employee:missions` | `/employee/missions` | `employee:employee_missions` |
| `employee:notifications` | `/employee/notifications` | `employee:notifications` |
| `employee:org-chart` | `/employee/org-chart` | `employee:organization_tree` |
| `employee:permissions` | `/employee/permissions` | `employee:permissions` |
| `employee:regulations` | `/employee/regulations` | `employee:charter` |
| `hr:attendance` | `/hr/attendance` | `manager:manager_attendance` |
| `hr:dashboard` | `/hr/dashboard` | `manager:dashboard` |
| `hr:geofence` | `/hr/geofence` | `manager:manager_geofence` |
| `hr:locations` | `/hr/locations` | `manager:manager_live_locations` |
| `hr:permissions/defaults` | `/hr/permissions/defaults` | `unknown` |
| `hr:regulations` | `/hr/regulations` | `manager:manager_charter` |
| `hr:requests` | `/hr/requests` | `manager:manager_pending` |
| `manager:attendance` | `/manager/attendance` | `manager:manager_attendance` |
| `manager:dashboard` | `/manager/dashboard` | `manager:dashboard` |
| `manager:locations` | `/manager/locations` | `manager:manager_live_locations` |
| `manager:my-attendance` | `/manager/my-attendance` | `manager:my_attendance` |
| `manager:my-field-visits` | `/manager/my-field-visits` | `manager:my_field_visits` |
| `manager:my-leaves` | `/manager/my-leaves` | `manager:my_leaves` |
| `manager:my-missions` | `/manager/my-missions` | `manager:my_missions` |
| `manager:my-payslip` | `/manager/my-payslip` | `manager:my_payslip` |
| `manager:my-permissions` | `/manager/my-permissions` | `manager:my_permissions` |
| `manager:my-profile` | `/manager/my-profile` | `manager:my_profile` |
| `manager:my-requests` | `/manager/my-requests` | `manager:my_requests` |
| `manager:notifications` | `/manager/notifications` | `manager:notifications` |
| `manager:regulations` | `/manager/regulations` | `manager:manager_charter` |
| `manager:requests` | `/manager/requests` | `manager:manager_pending` |
| `manager:team` | `/manager/team` | `manager:manager_team` |

## 📱 Mobile Features Not in Web

**Total: 42**

- `auth:activate_account` → `auth/activate_account_screen.dart`
- `common:location_picker` → `common/location_picker_screen.dart`
- `employee:announcement_detail` → `employee/announcement_detail_screen.dart`
- `employee:employee_documents` → `employee/employee_documents_screen.dart`
- `employee:employee_movements` → `employee/employee_movements_screen.dart`
- `employee:item_detail` → `employee/item_detail_screen.dart`
- `employee:my_shift` → `employee/my_shift_screen.dart`
- `employee:my_work_locations` → `employee/my_work_locations_screen.dart`
- `manager:company_edit` → `manager/company_edit_screen.dart`
- `manager:create_announcement` → `manager/create_announcement_screen.dart`
- `manager:create_employee` → `manager/create_employee_screen.dart`
- `manager:create_mission` → `manager/create_mission_screen.dart`
- `manager:department_detail` → `manager/department_detail_screen.dart`
- `manager:employee_permissions` → `manager/employee_permissions_screen.dart`
- `manager:mission_detail` → `manager/mission_detail_screen.dart`
- `manager:official_holidays` → `manager/official_holidays_screen.dart`
- `manager:payroll/create_edit_allowance_rule` → `manager/payroll/create_edit_allowance_rule_screen.dart`
- `manager:payroll/create_edit_bonus_rule` → `manager/payroll/create_edit_bonus_rule_screen.dart`
- `manager:payroll/create_edit_eos_policy` → `manager/payroll/create_edit_eos_policy_screen.dart`
- `manager:payroll/create_edit_insurance_policy` → `manager/payroll/create_edit_insurance_policy_screen.dart`
- `manager:payroll/create_edit_leave_rule` → `manager/payroll/create_edit_leave_rule_screen.dart`
- `manager:payroll/create_edit_payroll_cycle` → `manager/payroll/create_edit_payroll_cycle_screen.dart`
- `manager:payroll/create_edit_penalty_rule` → `manager/payroll/create_edit_penalty_rule_screen.dart`
- `manager:payroll/create_edit_tax_policy` → `manager/payroll/create_edit_tax_policy_screen.dart`
- `manager:payroll/eos_policy` → `manager/payroll/eos_policy_screen.dart`
- `manager:payroll/insurance_policies` → `manager/payroll/insurance_policies_screen.dart`
- `manager:payroll/leave_rules` → `manager/payroll/leave_rules_screen.dart`
- `manager:payroll/payroll_bonus_penalty` → `manager/payroll/payroll_bonus_penalty_screen.dart`
- `manager:payroll/payroll_cycle` → `manager/payroll/payroll_cycle_screen.dart`
- `manager:payroll/payroll_employee_detail` → `manager/payroll/payroll_employee_detail_screen.dart`
- `manager:payroll/payroll_payslip` → `manager/payroll/payroll_payslip_screen.dart`
- `manager:payroll/payroll_run_detail` → `manager/payroll/payroll_run_detail_screen.dart`
- `manager:payroll/payroll_settings` → `manager/payroll/payroll_settings_screen.dart`
- `manager:payroll/payroll_summary` → `manager/payroll/payroll_summary_screen.dart`
- `manager:payroll/tax_policy` → `manager/payroll/tax_policy_screen.dart`
- `manager:payroll_policy` → `manager/payroll_policy_screen.dart`
- `manager:permissions_hub` → `manager/permissions_hub_screen.dart`
- `manager:reports/base_report` → `manager/reports/base_report_screen.dart`
- `manager:role_detail` → `manager/role_detail_screen.dart`
- `manager:shifts/assign_shift` → `manager/shifts/assign_shift_screen.dart`
- `manager:shifts/assignment_detail` → `manager/shifts/assignment_detail_screen.dart`
- `manager:shifts/create_edit_shift` → `manager/shifts/create_edit_shift_screen.dart`

## ✅ Matched Features

**Total: 60**

| Web Feature | Mobile Feature |
|-------------|----------------|
| `employee:announcements` | `employee:announcements` |
| `employee:attendance` | `employee:employee_summary` |
| `employee:dashboard` | `employee:employee_summary` |
| `employee:field-visits` | `employee:field_visits` |
| `employee:payslip` | `employee:employee_payslip` |
| `employee:profile` | `employee:employee_profile` |
| `employee:requests` | `employee:requests` |
| `hr:announcements` | `manager:manager_announcements` |
| `hr:branches` | `manager:branches` |
| `hr:company` | `manager:company_info` |
| `hr:company-policies` | `manager:payroll/company_policies` |
| `hr:departments` | `manager:departments_management` |
| `hr:employees` | `manager:manager_employees_list` |
| `hr:employees/detail` | `manager:manager_employee_detail` |
| `hr:employees/import` | `manager:import_tools` |
| `hr:flex-shift` | `manager:flex_adjustments` |
| `hr:job-titles` | `manager:job_titles` |
| `hr:leave-recall` | `manager:leave_recall` |
| `hr:leaves` | `manager:leave_policy` |
| `hr:manual-entries` | `manager:payroll/manual_entries` |
| `hr:missions` | `manager:manager_missions` |
| `hr:org-chart` | `manager:organization_tree` |
| `hr:payroll` | `manager:payroll/payroll_hub` |
| `hr:payroll-runs` | `manager:payroll/payroll_run` |
| `hr:permissions` | `manager:permissions_management` |
| `hr:permissions/assign` | `manager:permissions_assign` |
| `hr:permissions/exceptions` | `manager:permissions_overrides` |
| `hr:permissions/export` | `manager:permissions_export` |
| `hr:permissions/roles` | `manager:permissions_roles` |
| `hr:policies` | `manager:policies_hub` |
| `hr:policies/allowance` | `manager:payroll/allowance_rules` |
| `hr:policies/attendance` | `manager:attendance_policy` |
| `hr:policies/bonus` | `manager:payroll/bonus_rules` |
| `hr:policies/deduction` | `manager:payroll/penalty_rules` |
| `hr:policies/leave` | `manager:leave_policy` |
| `hr:policies/work` | `manager:work_policy` |
| `hr:reminders` | `manager:reminder_settings` |
| `hr:reports` | `manager:reports/reports_hub` |
| `hr:reports/absence` | `manager:reports/absence_report` |
| `hr:reports/daily-attendance` | `manager:reports/daily_attendance_report` |
| `hr:reports/late` | `manager:reports/late_report` |
| `hr:reports/leaves-basic` | `manager:reports/leaves_report` |
| `hr:reports/leaves-enhanced` | `manager:reports/leaves_enhanced_report` |
| `hr:reports/location-tracking` | `manager:location_report` |
| `hr:reports/monthly-attendance` | `manager:reports/attendance_report` |
| `hr:reports/payroll` | `manager:reports/payroll_report` |
| `hr:reports/permissions` | `manager:reports/permissions_report` |
| `hr:reports/requests` | `manager:reports/requests_report` |
| `hr:reports/shifts` | `manager:reports/shifts_report` |
| `hr:reports/work-hours` | `manager:reports/work_hours_report` |
| `hr:settings` | `manager:reminder_settings` |
| `hr:shifts` | `manager:shifts/shifts` |
| `hr:shifts/exceptions` | `manager:shifts/shift_override` |
| `hr:shifts/rotations` | `manager:shifts/shift_rotation` |
| `hr:termination` | `manager:offboarding` |
| `hr:work-locations` | `manager:work_locations_approval` |
| `manager:announcements` | `manager:manager_announcements` |
| `manager:missions` | `manager:manager_missions` |
| `manager:org-chart` | `manager:organization_tree` |
| `manager:reports` | `manager:reports/reports_hub` |