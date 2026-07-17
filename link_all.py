# 1) في main.dart: import + زر للمدير
p = 'lib/main.dart'
c = open(p, encoding='utf-8-sig').read()
original = c

# أضف الـ import للـ ManagerEmployeesListScreen
new_import = "import 'screens/manager/manager_employees_list_screen.dart';"
if new_import not in c:
    anchor = "import 'screens/employee/employee_profile_screen.dart';"
    if anchor in c:
        c = c.replace(anchor, anchor + "\n" + new_import, 1)
        print('Added import: manager_employees_list_screen.dart')

# أضف زر "الموظفين" في ManagerDashboard (قبل زر الرواتب)
old_row = "_card('الرواتب', 'عرض', Icons.account_balance_wallet, Colors.green,"
new_row = """_card('الموظفين', 'عرض', Icons.people, Color(0xFF6A1B9A),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerEmployeesListScreen()))),
      const SizedBox(height: 12),
      _card('الرواتب', 'عرض', Icons.account_balance_wallet, Colors.green,"""

if 'ManagerEmployeesListScreen()' not in c:
    if old_row in c:
        c = c.replace(old_row, new_row, 1)
        print('Added Employees button in ManagerDashboard')
    else:
        print('Anchor for manager button NOT found')

open(p, 'w', encoding='utf-8-sig').write(c)

# 2) في employee_profile_screen.dart: import + زر للملخص
p2 = 'lib/screens/employee/employee_profile_screen.dart'
c2 = open(p2, encoding='utf-8').read()

new_import2 = "import 'employee_summary_screen.dart';"
if new_import2 not in c2:
    c2 = c2.replace(
        "import 'employee_documents_screen.dart';",
        "import 'employee_documents_screen.dart';\nimport 'employee_summary_screen.dart';",
        1
    )
    print('Added import: employee_summary_screen.dart in profile')

# أضف زر "الملخص" قبل زر المستندات
old_docs = """SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EmployeeDocumentsScreen()),
                              ),
                              icon: const Icon(Icons.folder_open, color: Colors.white),
                              label: const Text('المستندات',"""

new_docs = """SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EmployeeSummaryScreen()),
                              ),
                              icon: const Icon(Icons.analytics, color: Colors.white),
                              label: const Text('الملخص', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6A1B9A),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EmployeeDocumentsScreen()),
                              ),
                              icon: const Icon(Icons.folder_open, color: Colors.white),
                              label: const Text('المستندات',"""

if 'EmployeeSummaryScreen()' not in c2:
    if old_docs in c2:
        c2 = c2.replace(old_docs, new_docs, 1)
        print('Added Summary button in profile')
    else:
        print('Anchor for summary button NOT found')

open(p2, 'w', encoding='utf-8').write(c2)

# 3) التحقق
print('\n=== Verification ===')
c_new = open(p, encoding='utf-8-sig').read()
c2_new = open(p2, encoding='utf-8').read()
print('main.dart:')
print('  - manager_employees_list import:', 'manager_employees_list_screen.dart' in c_new)
print('  - ManagerEmployeesListScreen ref:', 'ManagerEmployeesListScreen()' in c_new)
print('  - الموظفين label:', "'الموظفين'" in c_new)
print('profile screen:')
print('  - employee_summary import:', 'employee_summary_screen.dart' in c2_new)
print('  - EmployeeSummaryScreen ref:', 'EmployeeSummaryScreen()' in c2_new)