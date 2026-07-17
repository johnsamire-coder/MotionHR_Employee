import os

path = 'lib/main.dart'
content = open(path, 'r', encoding='utf-8').read()
print(f"File size: {len(content)} chars")

# 1) اضافة الـ import
import_line = "import 'package:motionhr_employee/screens/manager/reminders/reminder_settings_screen.dart';"

if 'reminder_settings_screen' in content:
    print("Import already exists - skipping")
else:
    # نلاقي اول import
    first_import = content.find("import '")
    if first_import == -1:
        print("ERROR: No imports found")
    else:
        end_of_line = content.find('\n', first_import) + 1
        content = content[:end_of_line] + import_line + '\n' + content[end_of_line:]
        print("Import added")

# 2) اضافة الزرار
target = "PayrollHubScreen())))]));"
if 'ReminderSettingsScreen' in content:
    print("Button already exists - skipping")
elif target not in content:
    print(f"ERROR: Target not found: {target}")
    print("Searching for PayrollHubScreen...")
    idx = content.find('PayrollHubScreen')
    if idx >= 0:
        print(f"Found at {idx}, context:")
        print(content[idx:idx+200])
else:
    replacement = "PayrollHubScreen()))),\n      const SizedBox(height: 12),\n      _card('التذكيرات', 'تلقائي', Icons.notifications_active, Colors.purple,\n          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderSettingsScreen())))]));"
    content = content.replace(target, replacement)
    print("Button added successfully")

# حفظ
with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done! Verifying...")
new_content = open(path, 'r', encoding='utf-8').read()
print(f"Import present: {'reminder_settings_screen' in new_content}")
print(f"Screen ref present: {'ReminderSettingsScreen' in new_content}")
