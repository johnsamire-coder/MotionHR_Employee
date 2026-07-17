# 1) أضف الـ imports في main.dart
p = 'lib/main.dart'
c = open(p, encoding='utf-8-sig').read()

imports_to_add = [
    "import 'screens/employee/employee_documents_screen.dart';",
    "import 'screens/employee/employee_movements_screen.dart';",
]

for imp in imports_to_add:
    if imp not in c:
        c = c.replace(
            "import 'screens/employee/employee_profile_screen.dart';",
            "import 'screens/employee/employee_profile_screen.dart';\n" + imp,
            1
        )
        print(f'Added: {imp}')
    else:
        print(f'Already exists: {imp}')

open(p, 'w', encoding='utf-8-sig').write(c)

# 2) أضف الـ imports في employee_profile_screen.dart
profile_path = 'lib/screens/employee/employee_profile_screen.dart'
pc = open(profile_path, encoding='utf-8').read()

profile_imports = [
    "import 'employee_documents_screen.dart';",
    "import 'employee_movements_screen.dart';",
]

for imp in profile_imports:
    if imp not in pc:
        pc = pc.replace(
            "import 'package:shared_preferences/shared_preferences.dart';",
            "import 'package:shared_preferences/shared_preferences.dart';\n" + imp,
            1
        )
        print(f'Added to profile: {imp}')

# 3) أضف زرارين في نهاية شاشة الملف الشخصي (قبل const SizedBox(height: 20))
old_end = "]),\n                      ),\n                      const SizedBox(height: 20),\n                    ]),"

new_end = """]),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EmployeeDocumentsScreen()),
                              ),
                              icon: const Icon(Icons.folder_open, color: Colors.white),
                              label: const Text('المستندات', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF388E3C),
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
                                MaterialPageRoute(builder: (_) => const EmployeeMovementsScreen()),
                              ),
                              icon: const Icon(Icons.history, color: Colors.white),
                              label: const Text('تاريخ الموظف', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE65100),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 20),
                    ]),"""

if old_end in pc:
    pc = pc.replace(old_end, new_end, 1)
    print('SUCCESS: Buttons added to profile screen')
else:
    print('WARNING: Could not find insertion point in profile screen')

open(profile_path, 'w', encoding='utf-8').write(pc)

# 4) التحقق
print('\n=== Verification ===')
c_new = open(p, encoding='utf-8-sig').read()
pc_new = open(profile_path, encoding='utf-8').read()
print('main.dart has documents import:', 'employee_documents_screen.dart' in c_new)
print('main.dart has movements import:', 'employee_movements_screen.dart' in c_new)
print('profile has documents button:', 'EmployeeDocumentsScreen()' in pc_new)
print('profile has movements button:', 'EmployeeMovementsScreen()' in pc_new)