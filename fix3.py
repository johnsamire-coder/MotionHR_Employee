import re

# إصلاح employee_missions_screen.dart
f1 = r'C:\MotionHR\motionhr_employee\motionhr_employee\lib\screens\employee_missions_screen.dart'
with open(f1, 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace(
    "{'key': 'active', 'label': context.l10n.inProgress}",
    "{'key': 'active', 'label': 'جارية'}"
)
c = c.replace(
    "{'key': 'today', 'label': context.l10n.today}",
    "{'key': 'today', 'label': 'اليوم'}"
)

with open(f1, 'w', encoding='utf-8') as f:
    f.write(c)
print("✅ employee_missions_screen.dart")

# إصلاح create_mission_screen.dart
f2 = r'C:\MotionHR\motionhr_employee\motionhr_employee\lib\screens\manager\create_mission_screen.dart'
with open(f2, 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace("'normal': context.l10n.normal,", "'normal': 'عادي',")
c = c.replace("'high': context.l10n.high,", "'high': 'عالي',")
c = c.replace("'urgent': context.l10n.urgent,", "'urgent': 'عاجل',")

with open(f2, 'w', encoding='utf-8') as f:
    f.write(c)
print("✅ create_mission_screen.dart")

# إصلاح manager_missions_screen.dart
f3 = r'C:\MotionHR\motionhr_employee\motionhr_employee\lib\screens\manager\manager_missions_screen.dart'
with open(f3, 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace("'in_progress': context.l10n.inProgress,", "'in_progress': 'جارية',")
c = c.replace("'completed': context.l10n.completed,", "'completed': 'مكتملة',")

with open(f3, 'w', encoding='utf-8') as f:
    f.write(c)
print("✅ manager_missions_screen.dart")

print("\nتم! شغّل: flutter analyze 2>&1 | findstr error | find /c error")