"""
MotionHR Mobile Inventory Extractor v5 - SIMPLE & POWERFUL
-----------------------------------------------------------
الاستراتيجية:
1. اقرأ الملف
2. شيل $kBaseUrl من كل مكان
3. امسك أي URL يبدأ بـ /attendance أو /leaves أو غيره
"""
import json
import re
from pathlib import Path

ROOT = Path("lib")
OUTPUT = Path("inventory_mobile.json")

if not ROOT.exists():
    print(f"[ERROR] Cannot find {ROOT}")
    raise SystemExit(1)

inventory = {
    "project": "MotionHR Mobile",
    "screens": [],
    "api_endpoints": [],
    "services": [],
    "navigation_items": [],
}

# قائمة الـ prefixes المعروفة
API_PREFIXES = r"(?:attendance|leaves|employee|hr|api|accounts|companies|subscriptions|requests|notifications)"

# نمط بسيط: امسك أي حاجة تبدأ بـ / وبعدها prefix معروف
SIMPLE_URL_PATTERN = re.compile(rf"/{API_PREFIXES}/[a-zA-Z0-9_\-/{{}}$.]+")

# نمط لمسك _basePath declarations
BASE_PATH_PATTERN = re.compile(rf"""_basePath\s*=\s*['"`](/{API_PREFIXES}/[^'"`\s]*?)['"`]""")

CLASS_PATTERN = re.compile(r"class\s+(\w+(?:Screen|Page|Shell|Dashboard|Widget|View|Hub|Router|Service))\s+(?:extends|implements)")
APPBAR_TITLE_PATTERN = re.compile(r"""AppBar\s*\([^)]*title:\s*(?:const\s+)?Text\s*\(\s*['"]([^'"]{2,80})['"]""")
BUTTON_LABEL_PATTERN = re.compile(r"""(?:ElevatedButton|TextButton|OutlinedButton|IconButton)[^(]*\([^)]*(?:child|label):\s*(?:const\s+)?Text\s*\(\s*['"]([^'"]{2,80})['"]""")
LIST_TILE_TITLE_PATTERN = re.compile(r"""ListTile\s*\([^)]*title:\s*(?:const\s+)?Text\s*\(\s*['"]([^'"]{2,80})['"]""")
NAV_ITEM_PATTERN = re.compile(r"""BottomNavigationBarItem\s*\([^)]*label:\s*['"]([^'"]{2,40})['"]""")
GRID_CARD_PATTERN = re.compile(r"""_gridCard\s*\(\s*(?:isAr\s*\?\s*)?['"]([^'"]{2,80})['"]""")
NAVIGATE_TO_PATTERN = re.compile(r"""MaterialPageRoute\s*\(\s*builder:\s*\([^)]*\)\s*=>\s*(?:const\s+)?(\w+)\s*\(""")
ARABIC_TEXT_PATTERN = re.compile(r"""['"]([^'"]*[\u0600-\u06FF]+[^'"]*)['"]""")

def rel(p): return str(p.as_posix())
def clean_text(s): return re.sub(r'\s+', ' ', s).strip()

def normalize_url(url):
    if not url:
        return None
    # شيل query strings
    url = url.split('?')[0].split('#')[0]
    url = url.split("'")[0].split('"')[0].split('`')[0]
    # طبع template variables
    url = re.sub(r'\$\{[^}]+\}', '{var}', url)
    url = re.sub(r'\$\w+', '{var}', url)
    url = re.sub(r'\{[^}]*\}', '{var}', url)
    # ضيف trailing slash لو مش موجود
    if not url.endswith('/'):
        url += '/'
    # طبع double vars
    url = re.sub(r'({var}/)+', '{var}/', url)
    return url

def extract_apis(text):
    apis = set()
    
    # 1) امسح $kBaseUrl عشان يتحول لـ / مباشرة
    cleaned = re.sub(r'\$kBaseUrl', '', text)
    
    # 2) لاقي كل الـ URLs
    for match in SIMPLE_URL_PATTERN.findall(cleaned):
        url = normalize_url(match)
        if url and len(url) > 4:
            apis.add(url)
    
    # 3) لاقي الـ _basePath declarations
    for match in BASE_PATH_PATTERN.findall(text):
        url = normalize_url(match)
        if url:
            apis.add(url)
    
    return sorted(apis)

def scan_file(fp):
    try:
        text = fp.read_text(encoding="utf-8", errors="ignore")
    except:
        return None

    return {
        "file": rel(fp),
        "classes": sorted(set(CLASS_PATTERN.findall(text))),
        "apis": extract_apis(text)[:200],
        "appbar_titles": sorted(set(clean_text(s) for s in APPBAR_TITLE_PATTERN.findall(text) if s.strip())),
        "button_labels": sorted(set(clean_text(s) for s in BUTTON_LABEL_PATTERN.findall(text) if s.strip()))[:100],
        "list_tile_titles": sorted(set(clean_text(s) for s in LIST_TILE_TITLE_PATTERN.findall(text) if s.strip()))[:100],
        "nav_items": sorted(set(clean_text(s) for s in NAV_ITEM_PATTERN.findall(text) if s.strip())),
        "grid_cards": sorted(set(clean_text(s) for s in GRID_CARD_PATTERN.findall(text) if s.strip()))[:100],
        "navigates_to": sorted(set(NAVIGATE_TO_PATTERN.findall(text))),
        "arabic_texts": sorted(set(clean_text(s) for s in ARABIC_TEXT_PATTERN.findall(text) if s.strip()))[:150],
    }

print("[SCAN] main.dart...")
main_file = ROOT / "main.dart"
if main_file.exists():
    entry = scan_file(main_file)
    if entry:
        entry["type"] = "main"
        entry["screen_path"] = "main.dart"
        inventory["screens"].append(entry)

print("[SCAN] Screens folder...")
screens_root = ROOT / "screens"
if screens_root.exists():
    for fp in screens_root.rglob("*.dart"):
        if "_backup" in str(fp) or ".bak" in str(fp):
            continue
        entry = scan_file(fp)
        if entry:
            entry["type"] = "screen"
            entry["screen_path"] = str(fp.relative_to(screens_root)).replace("\\", "/")
            inventory["screens"].append(entry)

print("[SCAN] Services folder...")
services_root = ROOT / "services"
if services_root.exists():
    for fp in services_root.rglob("*.dart"):
        try:
            text = fp.read_text(encoding="utf-8", errors="ignore")
            inventory["services"].append({
                "file": rel(fp),
                "apis": extract_apis(text),
            })
        except:
            pass

print("[SCAN] Aggregating APIs...")
all_apis = set()
for screen in inventory["screens"]:
    all_apis.update(screen.get("apis", []))
for service in inventory["services"]:
    all_apis.update(service.get("apis", []))
inventory["api_endpoints"] = sorted(all_apis)

main_entry = next((s for s in inventory["screens"] if s.get("type") == "main"), None)
if main_entry:
    inventory["navigation_items"] = main_entry.get("nav_items", [])

OUTPUT.write_text(json.dumps(inventory, ensure_ascii=False, indent=2), encoding="utf-8")

print(f"\n[OK] Screens: {len(inventory['screens'])}")
print(f"[OK] Services: {len(inventory['services'])}")
print(f"[OK] Unique APIs: {len(inventory['api_endpoints'])}")
print(f"[OK] Saved to: {OUTPUT.absolute()}")
