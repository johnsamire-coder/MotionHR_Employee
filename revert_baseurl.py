"""
Revert kBaseUrl back to working server
"""
from pathlib import Path
path = Path("lib/main.dart")
text = path.read_text(encoding="utf-8")

old_url = "const String kBaseUrl = 'https://app.jssolutions-eg.com';"
new_url = "const String kBaseUrl = 'https://jssolutions-eg.com';"

if old_url in text:
    text = text.replace(old_url, new_url, 1)
    path.write_text(text, encoding="utf-8")
    print("[OK] Reverted to: https://jssolutions-eg.com")
else:
    print("[SKIP] Already using jssolutions-eg.com or unknown state")

# تأكيد
import re
match = re.search(r"const\s+String\s+kBaseUrl\s*=\s*['\"]([^'\"]+)['\"]", text)
if match:
    print(f"[CURRENT] kBaseUrl = {match.group(1)}")
