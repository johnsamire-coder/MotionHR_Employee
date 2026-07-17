# -*- coding: utf-8 -*-
"""
سكريبت يضيف paths المرفقات في urls.py
"""

FILE = "/var/www/motionhr/attendance/urls.py"

# قراءة الملف
with open(FILE, "r", encoding="utf-8") as f:
    content = f.read()

# الـ paths الجديدة
new_paths = '''    path("api/mobile/attachments/upload/", api_attachments.upload_attachment),
    path("api/mobile/attachments/list/", api_attachments.list_attachments),
    path("api/mobile/attachments/<int:attachment_id>/delete/", api_attachments.delete_attachment),
    path("api/mobile/attachments/<int:attachment_id>/download/", api_attachments.download_attachment),
'''

# نضيف الـ paths بعد آخر path موجود للـ manager employees
marker = "path('api/mobile/manager/employees/<int:emp_id>/movements/'"

if marker in content:
    # نلاقي السطر ونضيف بعده
    idx = content.find(marker)
    # نلاقي نهاية السطر
    line_end = content.find("\n", idx) + 1
    # نضيف الـ paths الجديدة
    new_content = content[:line_end] + new_paths + content[line_end:]
    
    with open(FILE, "w", encoding="utf-8") as f:
        f.write(new_content)
    
    print("SUCCESS - Added 4 paths after movements/")
else:
    print("ERROR - Marker not found. Contents preview:")
    print(content[-500:])