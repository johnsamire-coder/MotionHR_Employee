import os

print('=' * 50)
print('  Phase 6 - Final Verification')
print('=' * 50)

# 1) الملفات
files = [
    'lib/screens/employee/employee_profile_screen.dart',
    'lib/screens/employee/employee_documents_screen.dart',
    'lib/screens/employee/employee_movements_screen.dart',
]

print('\n[1] Files exist:')
all_ok = True
for f in files:
    exists = os.path.exists(f)
    size = os.path.getsize(f) if exists else 0
    status = 'OK' if exists and size > 1000 else 'FAIL'
    print(f'   [{status}] {f} ({size} bytes)')
    if not exists or size < 1000:
        all_ok = False

# 2) main.dart
print('\n[2] main.dart checks:')
c = open('lib/main.dart', encoding='utf-8-sig').read()

checks_main = [
    ('Import profile', "employee_profile_screen.dart"),
    ('Import documents', "employee_documents_screen.dart"),
    ('Import movements', "employee_movements_screen.dart"),
    ('Button tooltip', "الملف الشخصي"),
    ('Screen ref', "EmployeeProfileScreen()"),
]
for name, key in checks_main:
    status = 'OK' if key in c else 'FAIL'
    print(f'   [{status}] {name}')
    if key not in c:
        all_ok = False

# 3) profile screen
print('\n[3] employee_profile_screen.dart checks:')
pc = open('lib/screens/employee/employee_profile_screen.dart', encoding='utf-8').read()

checks_profile = [
    ('Import documents', "employee_documents_screen.dart"),
    ('Import movements', "employee_movements_screen.dart"),
    ('Documents button', "EmployeeDocumentsScreen()"),
    ('Movements button', "EmployeeMovementsScreen()"),
    ('API URL', "/attendance/api/mobile/employee/profile/"),
]
for name, key in checks_profile:
    status = 'OK' if key in pc else 'FAIL'
    print(f'   [{status}] {name}')
    if key not in pc:
        all_ok = False

# 4) syntax check - عدد الأقواس متطابق
print('\n[4] Bracket balance:')
for f in files + ['lib/main.dart']:
    text = open(f, encoding='utf-8-sig' if 'main' in f else 'utf-8').read()
    open_curly = text.count('{')
    close_curly = text.count('}')
    open_paren = text.count('(')
    close_paren = text.count(')')
    balanced = (open_curly == close_curly) and (open_paren == close_paren)
    status = 'OK' if balanced else 'FAIL'
    print(f'   [{status}] {f}')
    print(f'          {{ }} : {open_curly} / {close_curly}')
    print(f'          ( ) : {open_paren} / {close_paren}')
    if not balanced:
        all_ok = False

# 5) API endpoints في الملفات
print('\n[5] API endpoints:')
apis = [
    ('/attendance/api/mobile/employee/profile/', 'employee_profile_screen.dart'),
    ('/attendance/api/mobile/employee/documents/', 'employee_documents_screen.dart'),
    ('/attendance/api/mobile/employee/movements/', 'employee_movements_screen.dart'),
]
for api, fname in apis:
    fpath = f'lib/screens/employee/{fname}'
    ftext = open(fpath, encoding='utf-8').read()
    status = 'OK' if api in ftext else 'FAIL'
    print(f'   [{status}] {api}')
    if api not in ftext:
        all_ok = False

print('\n' + '=' * 50)
if all_ok:
    print('  ALL CHECKS PASSED - READY TO RUN')
else:
    print('  SOME CHECKS FAILED - REVIEW ABOVE')
print('=' * 50)