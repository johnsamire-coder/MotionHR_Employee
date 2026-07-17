# -*- coding: utf-8 -*-
"""
سكريبت يعدل main.dart:
1. يضيف import لـ ItemDetailScreen
2. يضيف onTap للـ ListTile في _MyList
"""

FILE = "lib/main.dart"

# قراءة الملف
with open(FILE, "r", encoding="utf-8") as f:
    content = f.read()

# ═══════════════════════════════════════════════════════════
# 1) إضافة الـ import
# ═══════════════════════════════════════════════════════════

import_line = "import 'screens/item_detail_screen.dart';\n"

if "screens/item_detail_screen.dart" in content:
    print("[SKIP] Import already exists")
else:
    # نلاقي أول import ونضيف بعده
    marker = "import 'screens/employee/employee_profile_screen.dart';"
    if marker in content:
        content = content.replace(marker, marker + "\n" + import_line.rstrip())
        print("[OK] Import added")
    else:
        # Fallback: نضيفه بعد أول import
        idx = content.find("\nimport ")
        if idx != -1:
            line_end = content.find(";\n", idx) + 2
            content = content[:line_end] + import_line + content[line_end:]
            print("[OK] Import added (fallback)")
        else:
            print("[ERROR] Cannot find import location")

# ═══════════════════════════════════════════════════════════
# 2) إضافة onTap للـ ListTile في _MyList
# ═══════════════════════════════════════════════════════════

# نلاقي الـ ListTile في _MyList (بحث دقيق)
old_tile = """      return Card(margin: const EdgeInsets.all(8), child: ListTile(
        title: Text(item['title'] ?? item['leave_type'] ?? item['type'] ?? '-'),
        subtitle: Text(item['date'] ?? item['created_at'] ?? ''),
        trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
            child: Text(status, style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold))),
      ));"""

new_tile = """      final isLeaveTab = widget.keyName == 'leaves';
      return Card(margin: const EdgeInsets.all(8), child: ListTile(
        title: Text(item['title'] ?? item['leave_type'] ?? item['type'] ?? '-'),
        subtitle: Text(item['date'] ?? item['created_at'] ?? ''),
        trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
            child: Text(status, style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold))),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => ItemDetailScreen(
              item: Map<String, dynamic>.from(item),
              itemType: isLeaveTab ? 'leave' : 'request',
            ),
          ));
          _load();
        },
      ));"""

if old_tile in content:
    content = content.replace(old_tile, new_tile)
    print("[OK] onTap added to ListTile")
else:
    print("[WARN] ListTile not found exactly - manual check needed")

# ═══════════════════════════════════════════════════════════
# حفظ الملف
# ═══════════════════════════════════════════════════════════

with open(FILE, "w", encoding="utf-8") as f:
    f.write(content)

print("[DONE] File saved")