from pathlib import Path

file_path = Path("lib/main.dart")
content = file_path.read_text(encoding="utf-8-sig")

# ─────────────────────────────────────────────
# Patch 1: إضافة زر الإعلانات في ManagerDashboard
# ─────────────────────────────────────────────
old_manager = """      _card('التذكيرات', 'إرسال', Icons.notifications_active, Colors.blueGrey,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderSettingsScreen())))]));"""

new_manager = """      _card('التذكيرات', 'إرسال', Icons.notifications_active, Colors.blueGrey,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderSettingsScreen()))),
      const SizedBox(height: 12),
      _card('الإعلانات', 'نشر', Icons.campaign, Colors.deepPurple,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateAnnouncementScreen())))]));"""

if "CreateAnnouncementScreen" not in content:
    content = content.replace(old_manager, new_manager)
    print("✅ تم إضافة زر الإعلانات في ManagerDashboard")
else:
    print("⚠️ زر الإعلانات في ManagerDashboard موجود بالفعل")

# ─────────────────────────────────────────────
# Patch 2: إضافة زر الإعلانات في EmployeeShell AppBar
# ─────────────────────────────────────────────
old_employee_shell = """      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        title: const Text('MotionHR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeProfileScreen())),
          ),"""

new_employee_shell = """      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        title: const Text('MotionHR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign),
            tooltip: 'الإعلانات',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeProfileScreen())),
          ),"""

if "AnnouncementsScreen" not in content:
    if old_employee_shell in content:
        content = content.replace(old_employee_shell, new_employee_shell)
        print("✅ تم إضافة زر الإعلانات في EmployeeShell AppBar")
    else:
        print("⚠️ لم يتم العثور على AppBar pattern في EmployeeShell — هنبحث بطريقة تانية")
        # بحث بسيط عن actions في EmployeeShell
        emp_shell_idx = content.find("class _EmployeeShellState")
        profile_btn_idx = content.find("EmployeeProfileScreen()", emp_shell_idx)
        icon_btn_start = content.rfind("IconButton", emp_shell_idx, profile_btn_idx)
        if icon_btn_start > 0:
            insert_before = content.rfind("          IconButton", emp_shell_idx, profile_btn_idx)
            announcement_btn = """          IconButton(
            icon: const Icon(Icons.campaign),
            tooltip: 'الإعلانات',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsScreen())),
          ),\n"""
            content = content[:insert_before] + announcement_btn + content[insert_before:]
            print("✅ تم إضافة زر الإعلانات بالطريقة البديلة")
        else:
            print("❌ لم يتم العثور على المكان المناسب في EmployeeShell")
else:
    print("⚠️ زر الإعلانات في EmployeeShell موجود بالفعل")

# ─────────────────────────────────────────────
# حفظ الملف
# ─────────────────────────────────────────────
file_path.write_text(content, encoding="utf-8-sig")
print("\n✅ تم حفظ main.dart")

# Verification
checks = [
    ("AnnouncementsScreen في EmployeeShell", "AnnouncementsScreen()" in content),
    ("CreateAnnouncementScreen في ManagerDashboard", "CreateAnnouncementScreen()" in content),
    ("import announcements_screen", "announcements_screen.dart" in content),
    ("import create_announcement_screen", "create_announcement_screen.dart" in content),
]

print("\nVerification:")
for label, ok in checks:
    print(("✅" if ok else "❌"), label)