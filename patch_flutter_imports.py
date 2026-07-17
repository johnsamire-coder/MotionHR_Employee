from pathlib import Path

file_path = Path("lib/main.dart")
content = file_path.read_text(encoding="utf-8-sig")

imports_to_add = """import 'screens/employee/announcements_screen.dart';
import 'screens/manager/create_announcement_screen.dart';
"""

if "announcements_screen.dart" not in content:
    content = content.replace(
        "import 'screens/employee/employee_profile_screen.dart';",
        "import 'screens/employee/employee_profile_screen.dart';\n" + imports_to_add
    )
    file_path.write_text(content, encoding="utf-8-sig")
    print("✅ تم إضافة الـ Imports")
else:
    print("⚠️ الـ Imports موجودة بالفعل")