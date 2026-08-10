"""
MotionHR - Web vs Mobile Comparison Report
-------------------------------------------
يقارن بين inventory_web.json و inventory_mobile.json
ويطلع تقرير كامل بالنواقص
"""
import json
import re
from pathlib import Path
from collections import defaultdict

WEB_FILE = Path("C:/MotionHR/web/inventory_web.json")
MOBILE_FILE = Path("C:/MotionHR/MotionHR_Clean/inventory_mobile.json")
OUTPUT_MD = Path("C:/MotionHR/MotionHR_Clean/comparison_report.md")
OUTPUT_JSON = Path("C:/MotionHR/MotionHR_Clean/comparison_report.json")

if not WEB_FILE.exists():
    print(f"[ERROR] Cannot find {WEB_FILE}")
    raise SystemExit(1)
if not MOBILE_FILE.exists():
    print(f"[ERROR] Cannot find {MOBILE_FILE}")
    raise SystemExit(1)

print("[LOAD] Loading inventories...")
web = json.loads(WEB_FILE.read_text(encoding="utf-8"))
mobile = json.loads(MOBILE_FILE.read_text(encoding="utf-8"))

# ============================================
# 1) نظف URLs من كل الاتنين
# ============================================
def clean_url(url):
    """يحول أي URL لشكل موحد للمقارنة"""
    if not url:
        return None
    # شيل trailing slash
    url = url.rstrip('/')
    # طبع template variables
    url = re.sub(r'\{[^}]*\}', '{id}', url)
    url = re.sub(r'\[[^\]]*\]', '{id}', url)
    # لو فيه $ يبقى URL مقطوع - تجاهله
    if '$' in url:
        return None
    # لو مش بيبدأ بـ / تجاهله
    if not url.startswith('/'):
        return None
    return url

def normalize_web_api(api_route):
    """يحول web api route لصيغة قابلة للمقارنة"""
    if not api_route.startswith('/api/'):
        return None
    # شيل /api prefix
    return clean_url(api_route[4:])  # /employee/leaves بدل /api/employee/leaves

def normalize_mobile_api(api):
    """يحول mobile api لصيغة قابلة للمقارنة"""
    cleaned = clean_url(api)
    if not cleaned:
        return None
    # شيل .dart files
    if '.dart' in cleaned:
        return None
    # حول /attendance/api/mobile/xxx لـ /xxx للمقارنة
    for prefix in ['/attendance/api/mobile', '/accounts/api/mobile', '/api/mobile']:
        if cleaned.startswith(prefix):
            return cleaned[len(prefix):]
    return cleaned

# ============================================
# 2) استخرج APIs من الويب
# ============================================
print("[EXTRACT] Web APIs...")
web_apis = set()
web_apis_raw = set()
for route in web['api_routes']:
    raw = route['route']
    web_apis_raw.add(raw)
    normalized = normalize_web_api(raw)
    if normalized:
        web_apis.add(normalized)

# ============================================
# 3) استخرج APIs من الموبايل
# ============================================
print("[EXTRACT] Mobile APIs...")
mobile_apis = set()
mobile_apis_raw = set()
for api in mobile['api_endpoints']:
    mobile_apis_raw.add(api)
    normalized = normalize_mobile_api(api)
    if normalized:
        mobile_apis.add(normalized)

# ============================================
# 4) المقارنة
# ============================================
print("[COMPARE] Analyzing differences...")
in_both = web_apis & mobile_apis
only_web = web_apis - mobile_apis
only_mobile = mobile_apis - web_apis

# ============================================
# 5) استخرج pages/screens
# ============================================
print("[EXTRACT] Web pages...")
web_routes = sorted(set(p['route'] for p in web['pages']))

print("[EXTRACT] Mobile screens...")
mobile_screens = sorted(set(s.get('screen_path', 'unknown') for s in mobile['screens']))

# ============================================
# 6) صنّف الـ APIs بالـ module
# ============================================
def get_module(api):
    """يستخرج الـ module من الـ API"""
    parts = api.strip('/').split('/')
    if not parts:
        return 'unknown'
    # لو أول جزء employee/manager/hr - رجّع اللي بعده
    if parts[0] in ('employee', 'manager', 'hr') and len(parts) > 1:
        return f"{parts[0]}/{parts[1]}"
    return parts[0]

modules_web = defaultdict(set)
modules_mobile = defaultdict(set)
for api in web_apis:
    modules_web[get_module(api)].add(api)
for api in mobile_apis:
    modules_mobile[get_module(api)].add(api)

all_modules = sorted(set(modules_web.keys()) | set(modules_mobile.keys()))

# ============================================
# 7) بناء التقرير
# ============================================
print("[BUILD] Building report...")

report = {
    "summary": {
        "web_total_apis": len(web_apis),
        "mobile_total_apis": len(mobile_apis),
        "in_both": len(in_both),
        "only_web": len(only_web),
        "only_mobile": len(only_mobile),
        "web_pages": len(web_routes),
        "mobile_screens": len(mobile_screens),
    },
    "in_both": sorted(in_both),
    "only_web": sorted(only_web),
    "only_mobile": sorted(only_mobile),
    "modules_comparison": {
        module: {
            "web": sorted(modules_web.get(module, set())),
            "mobile": sorted(modules_mobile.get(module, set())),
            "only_web": sorted(modules_web.get(module, set()) - modules_mobile.get(module, set())),
            "only_mobile": sorted(modules_mobile.get(module, set()) - modules_web.get(module, set())),
        }
        for module in all_modules
    },
    "web_pages": web_routes,
    "mobile_screens": mobile_screens,
}

OUTPUT_JSON.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")

# ============================================
# 8) بناء تقرير Markdown
# ============================================
md = []
md.append("# 📊 MotionHR - Web vs Mobile Comparison Report\n")
md.append(f"**Generated:** {Path.cwd()}\n")

md.append("## 📈 Summary\n")
md.append("| Metric | Count |")
md.append("|--------|-------|")
md.append(f"| Web APIs | {len(web_apis)} |")
md.append(f"| Mobile APIs | {len(mobile_apis)} |")
md.append(f"| ✅ In Both | {len(in_both)} |")
md.append(f"| 🌐 Only in Web | {len(only_web)} |")
md.append(f"| 📱 Only in Mobile | {len(only_mobile)} |")
md.append(f"| Web Pages | {len(web_routes)} |")
md.append(f"| Mobile Screens | {len(mobile_screens)} |")
md.append("")

md.append("## 🎯 Module-by-Module Comparison\n")
for module in all_modules:
    web_count = len(modules_web.get(module, set()))
    mobile_count = len(modules_mobile.get(module, set()))
    only_w = modules_web.get(module, set()) - modules_mobile.get(module, set())
    only_m = modules_mobile.get(module, set()) - modules_web.get(module, set())
    
    status = "✅" if not only_w and not only_m else "⚠️"
    md.append(f"### {status} `{module}` (Web: {web_count} / Mobile: {mobile_count})\n")
    
    if only_w:
        md.append(f"**❌ Missing in Mobile ({len(only_w)}):**")
        for api in sorted(only_w):
            md.append(f"- `{api}`")
        md.append("")
    
    if only_m:
        md.append(f"**❌ Missing in Web ({len(only_m)}):**")
        for api in sorted(only_m):
            md.append(f"- `{api}`")
        md.append("")
    
    if not only_w and not only_m:
        md.append("*All matched ✅*\n")

md.append("\n## 🌐 APIs Only in Web (Missing from Mobile)\n")
if only_web:
    md.append(f"Total: **{len(only_web)}**\n")
    for api in sorted(only_web):
        md.append(f"- `{api}`")
else:
    md.append("*None ✅*")

md.append("\n\n## 📱 APIs Only in Mobile (Missing from Web)\n")
if only_mobile:
    md.append(f"Total: **{len(only_mobile)}**\n")
    for api in sorted(only_mobile):
        md.append(f"- `{api}`")
else:
    md.append("*None ✅*")

OUTPUT_MD.write_text("\n".join(md), encoding="utf-8")

# ============================================
# 9) طبع summary
# ============================================
print("\n" + "="*60)
print("COMPARISON RESULTS")
print("="*60)
print(f"Web APIs:      {len(web_apis)}")
print(f"Mobile APIs:   {len(mobile_apis)}")
print(f"In Both:       {len(in_both)} ✅")
print(f"Only in Web:   {len(only_web)} ⚠️")
print(f"Only in Mobile:{len(only_mobile)} ⚠️")
print("="*60)
print(f"\n[OK] Markdown report: {OUTPUT_MD}")
print(f"[OK] JSON report:     {OUTPUT_JSON}")
