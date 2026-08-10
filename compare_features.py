"""
MotionHR - Web vs Mobile FEATURE Comparison
--------------------------------------------
مقارنة على مستوى الميزات (Features) مش الـ APIs
"""
import json
import re
from pathlib import Path
from collections import defaultdict

WEB_FILE = Path("C:/MotionHR/web/inventory_web.json")
MOBILE_FILE = Path("C:/MotionHR/MotionHR_Clean/inventory_mobile.json")
OUTPUT_MD = Path("C:/MotionHR/MotionHR_Clean/feature_comparison.md")

web = json.loads(WEB_FILE.read_text(encoding="utf-8"))
mobile = json.loads(MOBILE_FILE.read_text(encoding="utf-8"))

# ============================================
# استخرج feature name من web page route
# مثال: /hr/employees -> hr:employees
#       /employee/leaves -> employee:leaves
# ============================================
def web_route_to_feature(route):
    parts = route.strip('/').split('/')
    if not parts or parts == ['']:
        return None
    role = parts[0]  # hr, employee, manager
    if role not in ('hr', 'employee', 'manager'):
        return None
    if len(parts) < 2:
        return f"{role}:home"
    # امسك أول جزء بعد الـ role
    feature = parts[1].replace('[id]', 'detail').replace('[', '').replace(']', '')
    if len(parts) > 2:
        sub = parts[2].replace('[id]', 'detail').replace('[', '').replace(']', '')
        feature = f"{feature}/{sub}"
    return f"{role}:{feature}"

# ============================================
# استخرج feature من mobile screen path
# مثال: manager/branches_screen.dart -> manager:branches
#       employee/announcements_screen.dart -> employee:announcements
# ============================================
def mobile_screen_to_feature(screen_path):
    if not screen_path or screen_path == 'main.dart':
        return None
    parts = screen_path.replace('.dart', '').split('/')
    if len(parts) < 2:
        return None
    role = parts[0]
    if role not in ('manager', 'employee', 'auth', 'common'):
        return None
    # امسك اسم الشاشة وشيل _screen
    screen_name = parts[-1].replace('_screen', '').replace('_page', '')
    # لو في subfolder (زي payroll/tax_policy)
    if len(parts) == 3:
        screen_name = f"{parts[1]}/{parts[-1].replace('_screen', '').replace('_page', '')}"
    # حول hr و employee
    if role == 'manager':
        return f"manager:{screen_name}"
    return f"{role}:{screen_name}"

# ============================================
# استخرج الميزات
# ============================================
print("[EXTRACT] Web features from pages...")
web_features = set()
web_feature_map = {}
for page in web['pages']:
    feature = web_route_to_feature(page['route'])
    if feature:
        web_features.add(feature)
        web_feature_map[feature] = page['route']

print("[EXTRACT] Mobile features from screens...")
mobile_features = set()
mobile_feature_map = {}
for screen in mobile['screens']:
    feature = mobile_screen_to_feature(screen.get('screen_path', ''))
    if feature:
        mobile_features.add(feature)
        mobile_feature_map[feature] = screen.get('screen_path', '')

# ============================================
# اعمل mapping بين web و mobile features
# مثال: hr:employees == manager:manager_employees_list
# ============================================
FEATURE_MAPPING = {
    # HR = Manager في الموبايل (الـ Company Admin)
    'hr:announcements': 'manager:manager_announcements',
    'hr:attendance': 'manager:manager_attendance',
    'hr:branches': 'manager:branches',
    'hr:company': 'manager:company_info',
    'hr:dashboard': 'manager:dashboard',
    'hr:departments': 'manager:departments_management',
    'hr:employees': 'manager:manager_employees_list',
    'hr:employees/detail': 'manager:manager_employee_detail',
    'hr:employees/import': 'manager:import_tools',
    'hr:flex-shift': 'manager:flex_adjustments',
    'hr:geofence': 'manager:manager_geofence',
    'hr:job-titles': 'manager:job_titles',
    'hr:leave-recall': 'manager:leave_recall',
    'hr:leaves': 'manager:leave_policy',
    'hr:missions': 'manager:manager_missions',
    'hr:org-chart': 'manager:organization_tree',
    'hr:payroll': 'manager:payroll/payroll_hub',
    'hr:payroll-runs': 'manager:payroll/payroll_run',
    'hr:permissions': 'manager:permissions_management',
    'hr:permissions/assign': 'manager:permissions_assign',
    'hr:permissions/roles': 'manager:permissions_roles',
    'hr:permissions/exceptions': 'manager:permissions_overrides',
    'hr:permissions/export': 'manager:permissions_export',
    'hr:policies': 'manager:policies_hub',
    'hr:policies/leave': 'manager:leave_policy',
    'hr:policies/attendance': 'manager:attendance_policy',
    'hr:policies/work': 'manager:work_policy',
    'hr:regulations': 'manager:manager_charter',
    'hr:reports': 'manager:reports/reports_hub',
    'hr:reports/absence': 'manager:reports/absence_report',
    'hr:reports/daily-attendance': 'manager:reports/daily_attendance_report',
    'hr:reports/late': 'manager:reports/late_report',
    'hr:reports/leaves-basic': 'manager:reports/leaves_report',
    'hr:reports/leaves-enhanced': 'manager:reports/leaves_enhanced_report',
    'hr:reports/monthly-attendance': 'manager:reports/attendance_report',
    'hr:reports/payroll': 'manager:reports/payroll_report',
    'hr:reports/permissions': 'manager:reports/permissions_report',
    'hr:reports/requests': 'manager:reports/requests_report',
    'hr:reports/shifts': 'manager:reports/shifts_report',
    'hr:reports/work-hours': 'manager:reports/work_hours_report',
    'hr:reports/location-tracking': 'manager:location_report',
    'hr:requests': 'manager:manager_pending',
    'hr:settings': 'manager:reminder_settings',
    'hr:shifts': 'manager:shifts/shifts',
    'hr:shifts/exceptions': 'manager:shifts/shift_override',
    'hr:shifts/rotations': 'manager:shifts/shift_rotation',
    'hr:termination': 'manager:offboarding',
    'hr:work-locations': 'manager:work_locations_approval',
    'hr:manual-entries': 'manager:payroll/manual_entries',
    'hr:reminders': 'manager:reminder_settings',
    'hr:locations': 'manager:manager_live_locations',
    'hr:company-policies': 'manager:payroll/company_policies',
    'hr:policies/allowance': 'manager:payroll/allowance_rules',
    'hr:policies/bonus': 'manager:payroll/bonus_rules',
    'hr:policies/deduction': 'manager:payroll/penalty_rules',
    
    # Employee
    'employee:announcements': 'employee:announcements',
    'employee:attendance': 'employee:employee_summary',
    'employee:dashboard': 'employee:employee_summary',
    'employee:field-visits': 'employee:field_visits',
    'employee:leaves': 'employee:leaves',
    'employee:missions': 'employee:employee_missions',
    'employee:notifications': 'employee:notifications',
    'employee:org-chart': 'employee:organization_tree',
    'employee:payslip': 'employee:employee_payslip',
    'employee:permissions': 'employee:permissions',
    'employee:profile': 'employee:employee_profile',
    'employee:regulations': 'employee:charter',
    'employee:requests': 'employee:requests',
    
    # Manager (personal - my_*)
    'manager:dashboard': 'manager:dashboard',
    'manager:team': 'manager:manager_team',
    'manager:attendance': 'manager:manager_attendance',
    'manager:requests': 'manager:manager_pending',
    'manager:missions': 'manager:manager_missions',
    'manager:locations': 'manager:manager_live_locations',
    'manager:notifications': 'manager:notifications',
    'manager:reports': 'manager:reports/reports_hub',
    'manager:announcements': 'manager:manager_announcements',
    'manager:regulations': 'manager:manager_charter',
    'manager:org-chart': 'manager:organization_tree',
    'manager:my-attendance': 'manager:my_attendance',
    'manager:my-field-visits': 'manager:my_field_visits',
    'manager:my-leaves': 'manager:my_leaves',
    'manager:my-missions': 'manager:my_missions',
    'manager:my-payslip': 'manager:my_payslip',
    'manager:my-permissions': 'manager:my_permissions',
    'manager:my-profile': 'manager:my_profile',
    'manager:my-requests': 'manager:my_requests',
}

# ============================================
# قارن
# ============================================
print("[COMPARE] Analyzing features...")

matched_features = []
missing_in_mobile = []
missing_in_web = []
extra_in_mobile = set(mobile_features)

for web_feat in sorted(web_features):
    expected_mobile = FEATURE_MAPPING.get(web_feat)
    if expected_mobile and expected_mobile in mobile_features:
        matched_features.append((web_feat, expected_mobile))
        extra_in_mobile.discard(expected_mobile)
    else:
        # جرب لو موجود بنفس الاسم في الموبايل
        if web_feat in mobile_features:
            matched_features.append((web_feat, web_feat))
            extra_in_mobile.discard(web_feat)
        else:
            missing_in_mobile.append({
                'web_feature': web_feat,
                'web_route': web_feature_map.get(web_feat, ''),
                'expected_mobile': expected_mobile or 'unknown',
            })

# ============================================
# بناء التقرير
# ============================================
print("[BUILD] Building report...")

md = []
md.append("# 📊 MotionHR - Feature-Level Comparison Report\n")

md.append("## 📈 Summary\n")
md.append("| Metric | Count |")
md.append("|--------|-------|")
md.append(f"| Web Pages | {len(web['pages'])} |")
md.append(f"| Mobile Screens | {len(mobile['screens'])} |")
md.append(f"| Web Features | {len(web_features)} |")
md.append(f"| Mobile Features | {len(mobile_features)} |")
md.append(f"| ✅ Matched Features | {len(matched_features)} |")
md.append(f"| ❌ Missing in Mobile | {len(missing_in_mobile)} |")
md.append(f"| 📱 Extra in Mobile (not in Web) | {len(extra_in_mobile)} |")
md.append("")

md.append("## ❌ Web Features Missing in Mobile\n")
if missing_in_mobile:
    md.append(f"**Total: {len(missing_in_mobile)}**\n")
    md.append("| Web Feature | Web Route | Expected Mobile |")
    md.append("|-------------|-----------|-----------------|")
    for item in sorted(missing_in_mobile, key=lambda x: x['web_feature']):
        md.append(f"| `{item['web_feature']}` | `{item['web_route']}` | `{item['expected_mobile']}` |")
else:
    md.append("*None ✅*")

md.append("\n## 📱 Mobile Features Not in Web\n")
if extra_in_mobile:
    md.append(f"**Total: {len(extra_in_mobile)}**\n")
    for feat in sorted(extra_in_mobile):
        screen = mobile_feature_map.get(feat, '')
        md.append(f"- `{feat}` → `{screen}`")
else:
    md.append("*None ✅*")

md.append("\n## ✅ Matched Features\n")
md.append(f"**Total: {len(matched_features)}**\n")
md.append("| Web Feature | Mobile Feature |")
md.append("|-------------|----------------|")
for web_feat, mobile_feat in sorted(matched_features):
    md.append(f"| `{web_feat}` | `{mobile_feat}` |")

OUTPUT_MD.write_text("\n".join(md), encoding="utf-8")

print("\n" + "="*60)
print("FEATURE COMPARISON RESULTS")
print("="*60)
print(f"Web Features:     {len(web_features)}")
print(f"Mobile Features:  {len(mobile_features)}")
print(f"Matched:          {len(matched_features)} ✅")
print(f"Missing Mobile:   {len(missing_in_mobile)} ⚠️")
print(f"Extra in Mobile:  {len(extra_in_mobile)} 📱")
print("="*60)
print(f"\n[OK] Report: {OUTPUT_MD}")
