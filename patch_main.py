import os

path = 'lib/main.dart'
content = open(path, 'r', encoding='utf-8').read()

# 1. إضافة الـ Import في بداية الملف
if 'reminder_settings_screen.dart' not in content:
    import_line = "import 'package:motionhr_employee/screens/manager/reminders/reminder_settings_screen.dart';"
    # بنضيفها بعد أول import موجود
    first_import_idx = content.find('import ')
    next_line_idx = content.find('\n', first_import_idx) + 1
    content = content[:next_line_idx] + import_line + '\n' + content[next_line_idx:]
    print("✅ Import added")

# 2. إضافة الزرار في الـ Dashboard
old_code = """_card('الرواتب', 'عرض', Icons.account_balance_wallet, Colors.green,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PayrollHubScreen())))]));"""

new_code = """_card('الرواتب', 'عرض', Icons.account_balance_wallet, Colors.green,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PayrollHubScreen()))),
      const SizedBox(height: 12),
      _card('التذكيرات', 'تلقائي', Icons.notifications_active, Colors.purple,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderSettingsScreen())))]));"""

if old_code in content:
    content = content.replace(old_code, new_code)
    print("✅ Button added to Dashboard")
else:
    # محاولة مطابقة بمسافات أقل لو فشل البحث الدقيق
    print("⚠️  Exact match failed, trying fuzzy match...")
    target = "PayrollHubScreen())))]));"
    replacement = "PayrollHubScreen()))),\n      const SizedBox(height: 12),\n      _card('التذكيرات', 'تلقائي', Icons.notifications_active, Colors.purple,\n          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderSettingsScreen())))]));"
    if target in content:
        content = content.replace(target, replacement)
        print("✅ Fuzzy match button added")
    else:
        print("❌ Could not find location to add button")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("🚀 Done! main.dart updated.")
