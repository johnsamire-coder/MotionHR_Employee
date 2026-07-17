# -*- coding: utf-8 -*-
import os
import shutil
from datetime import datetime

main_file = r"C:\MotionHR\motionhr_employee\motionhr_employee\lib\main.dart"

if not os.path.exists(main_file):
    print("ERROR: main.dart not found!")
    exit(1)

backup_file = main_file + ".bak_" + datetime.now().strftime("%Y%m%d_%H%M%S")
shutil.copy2(main_file, backup_file)
print(f"[BACKUP] Created: {backup_file}")

with open(main_file, "r", encoding="utf-8") as f:
    content = f.read()

# 1) Add import
import_line = "import 'screens/manager/reports/reports_hub_screen.dart';"

if import_line in content:
    print("[1/2] Import already exists - skipped")
else:
    old_import = "import 'package:flutter/material.dart';"
    new_import = old_import + "\n" + import_line
    content = content.replace(old_import, new_import, 1)
    print("[1/2] Import added successfully")

# 2) Add reports card
alt_old = "() => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerGeofenceScreen())))]));"
alt_new = """() => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerGeofenceScreen()))),
      const SizedBox(height: 12),
      _card('التقارير', 'عرض', Icons.analytics, Colors.indigo,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsHubScreen())))]));"""

if "ReportsHubScreen()" in content:
    print("[2/2] Reports card already exists - skipped")
elif alt_old in content:
    content = content.replace(alt_old, alt_new)
    print("[2/2] Reports card added successfully")
else:
    print("[2/2] FAILED - Pattern not found")

with open(main_file, "w", encoding="utf-8") as f:
    f.write(content)

print("")
print("=" * 50)
print("DONE!")
print("=" * 50)
print("Now run: flutter run")