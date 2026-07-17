from pathlib import Path

content = Path("urls_patch.py").read_text(encoding="utf-8") if Path("urls_patch.py").exists() else ""

# اقرأ urls.py من السيرفر
import subprocess
result = subprocess.run(
    ["ssh", "root@194.164.77.164", "cat /var/www/motionhr/attendance/urls.py"],
    capture_output=True, text=True, encoding="utf-8"
)
content = result.stdout

# تحقق إن api_announcements مش موجود
if "api_announcements" in content:
    print("⚠️ api_announcements موجود بالفعل!")
else:
    # أضف import
    content = content.replace(
        "from attendance import api_employee_profile",
        "from attendance import api_employee_profile\nfrom attendance import api_announcements"
    )

    # أضف URLs قبل آخر ]
    new_urls = """
    # ─── المرحلة 4.2: الإعلانات ───
    path('api/mobile/announcements/list/', api_announcements.announcements_list),
    path('api/mobile/announcements/mark-read/', api_announcements.announcements_mark_read),
    path('api/mobile/manager/announcements/create/', api_announcements.manager_create_announcement),
    path('api/mobile/manager/announcements/<int:pk>/delete/', api_announcements.manager_delete_announcement),
    path('api/mobile/manager/announcements/<int:pk>/stats/', api_announcements.manager_announcement_stats),

]"""
    content = content.replace("\n]", new_urls, 1)

    # احفظ محلياً
    Path("urls_patched.py").write_text(content, encoding="utf-8")
    print("✅ تم الحفظ في urls_patched.py")

    # تحقق
    checks = [
        "api_announcements",
        "announcements/list/",
        "announcements/mark-read/",
        "manager/announcements/create/",
        "manager/announcements/<int:pk>/delete/",
        "manager/announcements/<int:pk>/stats/",
    ]
    for c in checks:
        status = "✅" if c in content else "❌"
        print(f"{status} {c}")