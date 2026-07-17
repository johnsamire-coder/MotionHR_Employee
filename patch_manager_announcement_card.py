from pathlib import Path

p = Path("lib/main.dart")
content = p.read_text(encoding="utf-8-sig")

target = "          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderSettingsScreen())))]));"

replacement = """          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderSettingsScreen()))),
      const SizedBox(height: 12),
      _card('الإعلانات', 'نشر', Icons.campaign, Colors.deepPurple,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateAnnouncementScreen())))]));"""

if "const CreateAnnouncementScreen()" in content:
    print("⚠️ كارت الإعلانات للمدير موجود بالفعل")
elif target in content:
    content = content.replace(target, replacement, 1)
    p.write_text(content, encoding="utf-8-sig")
    print("✅ تم إضافة كارت الإعلانات للمدير")
else:
    print("❌ لم يتم العثور على السطر الهدف")

print("VERIFY_CREATE_SCREEN =", "const CreateAnnouncementScreen()" in content)
print("VERIFY_MANAGER_CARD =", "_card('الإعلانات', 'نشر', Icons.campaign, Colors.deepPurple," in content)