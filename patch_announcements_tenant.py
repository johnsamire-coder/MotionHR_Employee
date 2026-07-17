from pathlib import Path
import subprocess
import sys


HOST = "root@194.164.77.164"


def ssh_read(remote_path: str) -> str:
    result = subprocess.run(
        ["ssh", HOST, f"cat {remote_path}"],
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if result.returncode != 0:
        print(f"❌ Failed to read: {remote_path}")
        print(result.stderr)
        sys.exit(1)
    return result.stdout


def save(path: str, content: str):
    Path(path).write_text(content, encoding="utf-8")
    print(f"✅ Saved: {path} ({len(content)} bytes)")


api_path = "/var/www/motionhr/attendance/api_announcements.py"
model_path = "/var/www/motionhr/accounts/company_announcements.py"

api = ssh_read(api_path)
model = ssh_read(model_path)

# ─────────────────────────────────────────────
# Patch 1: get_employee + get_user_company
# ─────────────────────────────────────────────
old_get_employee = """def get_employee(user):
    try:
        from employees.models import Employee
        return Employee.objects.get(user=user)
    except Exception:
        return None
"""

new_get_employee = """def get_employee(user):
    try:
        from employees.models import Employee
        return Employee._base_manager.filter(user=user).first()
    except Exception:
        return None


def get_user_company(user):
    if getattr(user, 'company_id', None):
        return user.company
    emp = get_employee(user)
    return getattr(emp, 'company', None)
"""

if "Employee.objects.get(user=user)" in api:
    api = api.replace(old_get_employee, new_get_employee)
    print("✅ Patched get_employee() + added get_user_company()")
else:
    print("⚠️ get_employee pattern not found or already patched")

# ─────────────────────────────────────────────
# Patch 2: announcements_list
# ─────────────────────────────────────────────
old_block = """    user = request.user
    now = timezone.now()

    qs = CompanyAnnouncement.objects.filter(
        company=user.company,
"""

new_block = """    user = request.user
    now = timezone.now()
    company = get_user_company(user)

    if not company:
        return Response({
            'announcements': [],
            'unread_count': 0,
            'total': 0,
        })

    qs = CompanyAnnouncement.objects.filter(
        company=company,
"""

if "company=user.company" in api:
    api = api.replace(old_block, new_block, 1)
    print("✅ Patched announcements_list company resolution")
else:
    print("⚠️ announcements_list company pattern not found or already patched")

# ─────────────────────────────────────────────
# Patch 3: announcements_mark_read
# ─────────────────────────────────────────────
old_mark = """    user = request.user
    emp = get_employee(user)
    if not emp:
        return Response({'error': 'موظف غير موجود'}, status=400)
"""

new_mark = """    user = request.user
    company = get_user_company(user)
    emp = get_employee(user)
    if not emp:
        return Response({'error': 'موظف غير موجود'}, status=400)
    if not company:
        return Response({'error': 'شركة المستخدم غير موجودة'}, status=400)
"""

if "شركة المستخدم غير موجودة" not in api:
    api = api.replace(old_mark, new_mark, 1)
    print("✅ Patched mark-read company resolution")
else:
    print("⚠️ mark-read already patched")

api = api.replace(
    "ann = CompanyAnnouncement.objects.get(id=announcement_id, company=user.company)",
    "ann = CompanyAnnouncement.objects.get(id=announcement_id, company=company)"
)

# ─────────────────────────────────────────────
# Patch 4: manager_create_announcement
# ─────────────────────────────────────────────
old_create = """    data = request.data
    title = data.get('title', '').strip()
    message = data.get('message', '').strip()
"""

new_create = """    company = get_user_company(user)
    if not company:
        return Response({'error': 'شركة المستخدم غير موجودة'}, status=400)

    data = request.data
    title = data.get('title', '').strip()
    message = data.get('message', '').strip()
"""

if "company = get_user_company(user)" not in api:
    api = api.replace(old_create, new_create, 1)
    print("✅ Patched manager_create_announcement company resolution")
else:
    print("⚠️ manager_create_announcement already patched")

api = api.replace(
    "company=user.company,",
    "company=company,",
    1
)

# ─────────────────────────────────────────────
# Patch 5: delete + stats
# ─────────────────────────────────────────────
api = api.replace(
    """    try:
        ann = CompanyAnnouncement.objects.get(id=pk, company=user.company)
""",
    """    company = get_user_company(user)
    if not company:
        return Response({'error': 'شركة المستخدم غير موجودة'}, status=400)

    try:
        ann = CompanyAnnouncement.objects.get(id=pk, company=company)
""",
    1
)

api = api.replace(
    """    try:
        ann = CompanyAnnouncement.objects.get(id=pk, company=user.company)
""",
    """    company = get_user_company(user)
    if not company:
        return Response({'error': 'شركة المستخدم غير موجودة'}, status=400)

    try:
        ann = CompanyAnnouncement.objects.get(id=pk, company=company)
""",
    1
)

# ─────────────────────────────────────────────
# Patch 6: CompanyAnnouncement.get_target_employees
# ─────────────────────────────────────────────
if "qs = Employee.objects.filter(company=self.company)" in model:
    model = model.replace(
        "        qs = Employee.objects.filter(company=self.company)",
        "        qs = Employee._base_manager.filter(company=self.company)"
    )
    print("✅ Patched get_target_employees() to use _base_manager")
else:
    print("⚠️ get_target_employees already patched or pattern not found")

save("api_announcements_fixed.py", api)
save("company_announcements_fixed.py", model)

# Verification
checks = [
    ("api uses _base_manager", "Employee._base_manager.filter(user=user).first()" in api),
    ("api has get_user_company", "def get_user_company(user):" in api),
    ("model uses _base_manager", "Employee._base_manager.filter(company=self.company)" in model),
]

print("\nVerification:")
for label, ok in checks:
    print(("✅" if ok else "❌"), label)