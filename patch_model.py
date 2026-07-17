import re
from pathlib import Path

path = Path("C:/var/www/motionhr/accounts/company_announcements.py")

# اقرأ الملف من السيرفر محلياً
import subprocess
result = subprocess.run(
    ["ssh", "root@194.164.77.164", "cat /var/www/motionhr/accounts/company_announcements.py"],
    capture_output=True, text=True, encoding="utf-8"
)
content = result.stdout

# أضف import GenericRelation لو مش موجود
if "GenericRelation" not in content:
    content = content.replace(
        "from django.db import models",
        "from django.db import models\nfrom django.contrib.contenttypes.fields import GenericRelation"
    )

# أضف requires_confirmation قبل publish_at
if "requires_confirmation" not in content:
    content = content.replace(
        "    # التوقيت\n    publish_at",
        '    # تأكيد القراءة\n    requires_confirmation = models.BooleanField(\n        default=False,\n        verbose_name="يتطلب تأكيد القراءة"\n    )\n\n    # المرفقات\n    attachments = GenericRelation(\n        \'core.Attachment\',\n        content_type_field=\'content_type\',\n        object_id_field=\'object_id\',\n        related_query_name=\'announcement\'\n    )\n\n    # التوقيت\n    publish_at'
    )

# احفظ محلياً أولاً
local_path = Path("company_announcements_patched.py")
local_path.write_text(content, encoding="utf-8")
print(f"✅ تم الحفظ محلياً: {local_path}")
print(f"📏 الحجم: {len(content)} bytes")

# تحقق
if "requires_confirmation" in content:
    print("✅ requires_confirmation موجود")
if "GenericRelation" in content:
    print("✅ GenericRelation موجود")
if "attachments = GenericRelation" in content:
    print("✅ attachments relation موجود")