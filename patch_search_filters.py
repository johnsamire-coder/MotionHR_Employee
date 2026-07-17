from pathlib import Path
import subprocess
import sys

HOST = "root@194.164.77.164"
REMOTE = "/var/www/motionhr/attendance/api_mobile_requests.py"

result = subprocess.run(
    ["ssh", HOST, f"cat {REMOTE}"],
    capture_output=True,
    text=True,
    encoding="utf-8",
)
if result.returncode != 0:
    print("❌ فشل قراءة الملف من السيرفر")
    print(result.stderr)
    sys.exit(1)

content = result.stdout

# ─────────────────────────────────────────────
# 1) Add Q import
# ─────────────────────────────────────────────
if "from django.db.models import Q" not in content:
    if "from django.utils import timezone" in content:
        content = content.replace(
            "from django.utils import timezone",
            "from django.utils import timezone\nfrom django.db.models import Q",
            1
        )
        print("✅ تم إضافة import Q")
    else:
        print("❌ لم يتم العثور على مكان مناسب لإضافة Q")
        sys.exit(1)
else:
    print("⚠️ import Q موجود بالفعل")

# ─────────────────────────────────────────────
# 2) Patch mobile_my_leaves: search + status
# ─────────────────────────────────────────────
old_leaves = """    leaves = LeaveRequest._base_manager.filter(
        employee=employee
    ).select_related('leave_type').order_by('-created_at')[:30]
"""

new_leaves = """    search = request.query_params.get('search', '').strip()
    status_filter = request.query_params.get('status', '').strip().lower()

    leaves = LeaveRequest._base_manager.filter(
        employee=employee
    ).select_related('leave_type')

    if status_filter:
        leaves = leaves.filter(status=status_filter)

    if search:
        leaves = leaves.filter(
            Q(reason__icontains=search) |
            Q(leave_type__name__icontains=search)
        )

    leaves = leaves.order_by('-created_at')[:30]
"""

if "status_filter = request.query_params.get('status'" not in content:
    if old_leaves in content:
        content = content.replace(old_leaves, new_leaves, 1)
        print("✅ تم إضافة search/status في mobile_my_leaves")
    else:
        print("❌ لم يتم العثور على بلوك mobile_my_leaves")
        sys.exit(1)
else:
    print("⚠️ mobile_my_leaves patched بالفعل")

# ─────────────────────────────────────────────
# 3) Patch mobile_my_requests: search + status
# ─────────────────────────────────────────────
old_requests = """    requests_list = EmployeeRequest._base_manager.filter(
        employee=employee
    ).select_related('request_type', 'request_type__category').order_by('-created_at')[:30]
"""

new_requests = """    search = request.query_params.get('search', '').strip()
    status_filter = request.query_params.get('status', '').strip().lower()

    requests_list = EmployeeRequest._base_manager.filter(
        employee=employee
    ).select_related('request_type', 'request_type__category')

    if status_filter:
        requests_list = requests_list.filter(status=status_filter)

    if search:
        requests_list = requests_list.filter(
            Q(subject__icontains=search) |
            Q(details__icontains=search) |
            Q(request_type__name__icontains=search) |
            Q(request_type__category__name__icontains=search)
        )

    requests_list = requests_list.order_by('-created_at')[:30]
"""

if "requests_list = requests_list.filter(status=status_filter)" not in content:
    if old_requests in content:
        content = content.replace(old_requests, new_requests, 1)
        print("✅ تم إضافة search/status في mobile_my_requests")
    else:
        print("❌ لم يتم العثور على بلوك mobile_my_requests")
        sys.exit(1)
else:
    print("⚠️ mobile_my_requests patched بالفعل")

# ─────────────────────────────────────────────
# 4) Patch manager pending: search
# ─────────────────────────────────────────────
old_company = """    company = getattr(user, 'company', None)

    pending_leaves = LeaveRequest._base_manager.filter(
"""

new_company = """    company = getattr(user, 'company', None)
    search = request.query_params.get('search', '').strip()

    pending_leaves = LeaveRequest._base_manager.filter(
"""

if "search = request.query_params.get('search', '').strip()" not in content:
    if old_company in content:
        content = content.replace(old_company, new_company, 1)
        print("✅ تم إضافة search في mobile_manager_pending")
    else:
        print("❌ لم يتم العثور على مكان company/search في mobile_manager_pending")
        sys.exit(1)
else:
    print("⚠️ search في mobile_manager_pending موجود بالفعل")

old_pending_leaves_company = """    if company:
        pending_leaves = pending_leaves.filter(company=company)
"""

new_pending_leaves_company = """    if company:
        pending_leaves = pending_leaves.filter(company=company)

    if search:
        pending_leaves = pending_leaves.filter(
            Q(employee__first_name_ar__icontains=search) |
            Q(employee__last_name_ar__icontains=search) |
            Q(reason__icontains=search) |
            Q(leave_type__name__icontains=search)
        )
"""

if "pending_leaves = pending_leaves.filter(" in content and "employee__first_name_ar__icontains=search" not in content:
    content = content.replace(old_pending_leaves_company, new_pending_leaves_company, 1)
    print("✅ تم إضافة search على pending_leaves")
else:
    print("⚠️ pending_leaves search موجود بالفعل أو لم يُعثر على البلوك")

old_pending_requests_company = """    if company:
        pending_requests = pending_requests.filter(company=company)
"""

new_pending_requests_company = """    if company:
        pending_requests = pending_requests.filter(company=company)

    if search:
        pending_requests = pending_requests.filter(
            Q(employee__first_name_ar__icontains=search) |
            Q(employee__last_name_ar__icontains=search) |
            Q(subject__icontains=search) |
            Q(details__icontains=search) |
            Q(request_type__name__icontains=search)
        )
"""

if "pending_requests = pending_requests.filter(" in content and "request_type__name__icontains=search" not in content:
    content = content.replace(old_pending_requests_company, new_pending_requests_company, 1)
    print("✅ تم إضافة search على pending_requests")
else:
    print("⚠️ pending_requests search موجود بالفعل أو لم يُعثر على البلوك")

# ─────────────────────────────────────────────
# 5) Backward compatibility for Flutter
# mobile_my_leaves -> leaves
# mobile_my_requests -> requests
# ─────────────────────────────────────────────
response_pattern = "return Response({'success': True, 'items': items})"
count_before = content.count(response_pattern)

if count_before >= 1:
    content = content.replace(
        response_pattern,
        "return Response({'success': True, 'items': items, 'leaves': items})",
        1
    )
    print("✅ تم إضافة leaves key")
else:
    print("⚠️ لم يتم العثور على response leaves")

if response_pattern in content:
    content = content.replace(
        response_pattern,
        "return Response({'success': True, 'items': items, 'requests': items})",
        1
    )
    print("✅ تم إضافة requests key")
else:
    if "'requests': items" in content:
        print("⚠️ requests key موجود بالفعل")
    else:
        print("❌ لم يتم العثور على response requests")
        sys.exit(1)

# ─────────────────────────────────────────────
# Save
# ─────────────────────────────────────────────
out = Path("api_mobile_requests_search_filter.py")
out.write_text(content, encoding="utf-8")
print(f"✅ تم الحفظ: {out} ({len(content)} bytes)")

# ─────────────────────────────────────────────
# Verification
# ─────────────────────────────────────────────
checks = [
    ("import Q", "from django.db.models import Q" in content),
    ("leaves status filter", "leaves = leaves.filter(status=status_filter)" in content),
    ("requests status filter", "requests_list = requests_list.filter(status=status_filter)" in content),
    ("pending search", "search = request.query_params.get('search', '').strip()" in content),
    ("leaves response key", "'leaves': items" in content),
    ("requests response key", "'requests': items" in content),
]

print("\nVerification:")
for label, ok in checks:
    print(("✅" if ok else "❌"), label)