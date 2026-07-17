import os

print('=' * 60)
print('  Phase 6 (6.7 + 6.8) - Final Verification')
print('=' * 60)

all_ok = True

# 1) الملفات
files = [
    'lib/screens/employee/employee_profile_screen.dart',
    'lib/screens/employee/employee_documents_screen.dart',
    'lib/screens/employee/employee_movements_screen.dart',
    'lib/screens/employee/employee_summary_screen.dart',
    'lib/screens/manager/manager_employees_list_screen.dart',
    'lib/screens/manager/manager_employee_detail_screen.dart',
]

print('\n[1] Files exist:')
for f in files:
    exists = os.path.exists(f)
    size = os.path.getsize(f) if exists else 0
    status = 'OK' if exists and size > 1000 else 'FAIL'
    print(f'   [{status}] {os.path.basename(f)} ({size} bytes)')
    if not exists or size < 1000:
        all_ok = False

# 2) main.dart
print('\n[2] main.dart:')
c = open('lib/main.dart', encoding='utf-8-sig').read()
checks = [
    ('Import profile', "employee_profile_screen.dart"),
    ('Import manager list', "manager_employees_list_screen.dart"),
    ('Screen ref profile', "EmployeeProfileScreen()"),
    ('Screen ref manager list', "ManagerEmployeesListScreen()"),
    ('Button الملف الشخصي', "الملف الشخصي"),
    ('Button الموظفين', "'الموظفين'"),
]
for name, key in checks:
    status = 'OK' if key in c else 'FAIL'
    print(f'   [{status}] {name}')
    if key not in c: all_ok = False

# 3) employee_profile_screen.dart
print('\n[3] employee_profile_screen.dart:')
pc = open('lib/screens/employee/employee_profile_screen.dart', encoding='utf-8').read()
checks_p = [
    ('Import documents', "employee_documents_screen.dart"),
    ('Import movements', "employee_movements_screen.dart"),
    ('Import summary', "employee_summary_screen.dart"),
    ('Summary button', "EmployeeSummaryScreen()"),
    ('Documents button', "EmployeeDocumentsScreen()"),
    ('Movements button', "EmployeeMovementsScreen()"),
]
for name, key in checks_p:
    status = 'OK' if key in pc else 'FAIL'
    print(f'   [{status}] {name}')
    if key not in pc: all_ok = False

# 4) manager_employees_list_screen.dart
print('\n[4] manager_employees_list_screen.dart:')
mlc = open('lib/screens/manager/manager_employees_list_screen.dart', encoding='utf-8').read()
checks_m = [
    ('Import detail', "manager_employee_detail_screen.dart"),
    ('Detail screen ref', "ManagerEmployeeDetailScreen("),
    ('API endpoint', "/attendance/api/mobile/manager/employees/"),
]
for name, key in checks_m:
    status = 'OK' if key in mlc else 'FAIL'
    print(f'   [{status}] {name}')
    if key not in mlc: all_ok = False

# 5) manager_employee_detail_screen.dart
print('\n[5] manager_employee_detail_screen.dart:')
mdc = open('lib/screens/manager/manager_employee_detail_screen.dart', encoding='utf-8').read()
checks_d = [
    ('Import summary', "employee_summary_screen.dart"),
    ('Summary screen ref', "EmployeeSummaryScreen("),
    ('API profile', "/profile/"),
    ('API documents', "/documents/"),
    ('API movements', "/movements/"),
]
for name, key in checks_d:
    status = 'OK' if key in mdc else 'FAIL'
    print(f'   [{status}] {name}')
    if key not in mdc: all_ok = False

# 6) employee_summary_screen.dart
print('\n[6] employee_summary_screen.dart:')
sc = open('lib/screens/employee/employee_summary_screen.dart', encoding='utf-8').read()
checks_s = [
    ('Employee API', "/employee/summary/"),
    ('Manager API', "/manager/employees/"),
    ('employeeId param', "widget.employeeId"),
]
for name, key in checks_s:
    status = 'OK' if key in sc else 'FAIL'
    print(f'   [{status}] {name}')
    if key not in sc: all_ok = False

# 7) Bracket balance
print('\n[7] Bracket balance:')
for f in files + ['lib/main.dart']:
    text = open(f, encoding='utf-8-sig' if 'main' in f else 'utf-8').read()
    oc = text.count('{'); cc = text.count('}')
    op = text.count('('); cp = text.count(')')
    balanced = (oc == cc) and (op == cp)
    status = 'OK' if balanced else 'FAIL'
    print(f'   [{status}] {os.path.basename(f)}   ({{ }}: {oc}/{cc})   (( ): {op}/{cp})')
    if not balanced: all_ok = False

print('\n' + '=' * 60)
if all_ok:
    print('  ALL CHECKS PASSED - Ready for flutter analyze')
else:
    print('  SOME CHECKS FAILED')
print('=' * 60)