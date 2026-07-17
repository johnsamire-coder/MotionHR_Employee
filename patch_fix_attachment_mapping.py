from pathlib import Path
import shutil, datetime

def backup(p):
    b = p.with_name(f"{p.name}.bak_{datetime.datetime.now():%Y%m%d_%H%M%S}")
    shutil.copy2(p, b)
    print("Backup:", b)
    return p

# ====== 1) item_detail_screen.dart ======
p1 = backup(Path(r'lib\screens\employee\item_detail_screen.dart'))
t1 = p1.read_text(encoding='utf-8')

# صلح model name في AttachmentsWidget
old1 = "model: itemType,"
new1 = """model: itemType == 'leave_request'
                    ? 'leaves.LeaveRequest'
                    : 'requests_app.EmployeeRequest',"""

if old1 in t1:
    t1 = t1.replace(old1, new1, 1)
    print("Fixed model mapping in item_detail_screen.dart")
else:
    print("WARNING: old1 not found in item_detail_screen.dart")

p1.write_text(t1, encoding='utf-8')

# ====== 2) attachments_widget.dart ======
p2 = backup(Path(r'lib\widgets\attachments_widget.dart'))
t2 = p2.read_text(encoding='utf-8')

# اطبع الـ model parameter اللي بيتبعت في الـ API calls
lines = [(i+1, l) for i, l in enumerate(t2.splitlines()) if 'model' in l.lower() and ('widget.model' in l or "'model'" in l or '"model"' in l)]
print("\n=== model usage in attachments_widget.dart ===")
for num, line in lines:
    print(f"  Line {num}: {line.strip()}")

print("\nDONE")