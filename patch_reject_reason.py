from pathlib import Path
import subprocess
import sys

HOST = "root@194.164.77.164"
REMOTE = "/var/www/motionhr/attendance/api_mobile_requests.py"

# اقرأ الملف من السيرفر
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

# نضيف شرط mandatory reason after action validation
target = """    if action not in ['approve', 'reject']:
        return Response({
            'success': False,
            'message': 'الإجراء لازم يكون approve أو reject'
        }, status=400)

    try:
"""

replacement = """    if action not in ['approve', 'reject']:
        return Response({
            'success': False,
            'message': 'الإجراء لازم يكون approve أو reject'
        }, status=400)

    if action == 'reject' and not notes:
        return Response({
            'success': False,
            'message': 'سبب الرفض مطلوب'
        }, status=400)

    try:
"""

if "سبب الرفض مطلوب" in content:
    print("⚠️ الباتش متطبق بالفعل")
else:
    if target not in content:
        print("❌ لم يتم العثور على المكان المطلوب")
        sys.exit(1)
    content = content.replace(target, replacement, 1)
    print("✅ تم إضافة شرط سبب الرفض الإجباري")

# احفظ محلياً
out = Path("api_mobile_requests_reject_reason.py")
out.write_text(content, encoding="utf-8")
print(f"✅ تم الحفظ: {out} ({len(content)} bytes)")

# verify
checks = [
    "if action == 'reject' and not notes:" in content,
    "'message': 'سبب الرفض مطلوب'" in content,
]
print("Verification:")
for i, ok in enumerate(checks, 1):
    print(f"{'✅' if ok else '❌'} check {i}")