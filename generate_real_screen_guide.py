"""
MotionHR - REAL Detailed Screen Guide
======================================
دليل حقيقي مبني على كود الشاشات الفعلي
"""
import re
from pathlib import Path
from datetime import datetime
from collections import defaultdict

MOBILE_DIR = Path("lib")
OUTPUT = Path("دليل_الشاشات_الحقيقي.md")

# ============================================
# Patterns
# ============================================
CLASS_PATTERN = re.compile(r"class\s+(\w+(?:Screen|Page|Shell|Dashboard|Hub|Router))\s+extends")

# AppBar titles
APPBAR_STR = re.compile(r"AppBar\s*\((?:[^{}]|\{[^{}]*\})*?title:\s*(?:const\s+)?Text\s*\(\s*['\"]([^'\"]+)['\"]", re.DOTALL)
APPBAR_TERNARY = re.compile(r"AppBar\s*\((?:[^{}]|\{[^{}]*\})*?title:\s*Text\s*\(\s*isAr\s*\?\s*['\"]([^'\"]+)['\"]\s*:\s*['\"]([^'\"]+)['\"]", re.DOTALL)

# All buttons
BUTTON_ANY = re.compile(
    r"(ElevatedButton|TextButton|OutlinedButton|FilledButton)"
    r"(?:\.icon)?"
    r"\s*\((?:[^()]|\([^()]*\))*?"
    r"(?:child|label):\s*(?:const\s+)?"
    r"(?:Text\s*\(\s*['\"]([^'\"]+)['\"]|"
    r"Row\s*\([^)]*?Text\s*\(\s*['\"]([^'\"]+)['\"])",
    re.DOTALL
)

# Icon Button with tooltip
ICON_BTN = re.compile(
    r"IconButton\s*\((?:[^()]|\([^()]*\))*?tooltip:\s*['\"]([^'\"]+)['\"]",
    re.DOTALL
)

# FAB
FAB = re.compile(
    r"FloatingActionButton(?:\.\w+)?\s*\((?:[^()]|\([^()]*\))*?tooltip:\s*['\"]([^'\"]+)['\"]",
    re.DOTALL
)

# Tabs
TAB_TEXT = re.compile(r"Tab\s*\(\s*(?:icon:[^,]+,\s*)?text:\s*['\"]([^'\"]+)['\"]")

# Bottom Nav
BOTTOM_NAV = re.compile(
    r"BottomNavigationBarItem\s*\((?:[^()]|\([^()]*\))*?"
    r"label:\s*(?:['\"]([^'\"]+)['\"]|isAr\s*\?\s*['\"]([^'\"]+)['\"]\s*:\s*['\"]([^'\"]+)['\"])",
    re.DOTALL
)

# Grid Cards (specific to this app)
GRID_CARD = re.compile(
    r"_gridCard\s*\(\s*"
    r"(?:isAr\s*\?\s*['\"]([^'\"]+)['\"][^,)]*?['\"]([^'\"]+)['\"]"
    r"|['\"]([^'\"]+)['\"])"
)

# Form Fields
FORM_LABEL = re.compile(r"(?:labelText|hintText):\s*['\"]([^'\"]+)['\"]")

# Dropdown
DROPDOWN = re.compile(
    r"DropdownButton(?:FormField)?[^(]*\((?:[^()]|\([^()]*\))*?"
    r"hint:\s*(?:const\s+)?Text\s*\(\s*['\"]([^'\"]+)['\"]",
    re.DOTALL
)

# ListTile
LIST_TILE = re.compile(
    r"ListTile\s*\((?:[^()]|\([^()]*\))*?"
    r"title:\s*(?:const\s+)?Text\s*\(\s*['\"]([^'\"]+)['\"]",
    re.DOTALL
)

# SwitchListTile
SWITCH_TILE = re.compile(
    r"SwitchListTile\s*\((?:[^()]|\([^()]*\))*?"
    r"title:\s*(?:const\s+)?Text\s*\(\s*['\"]([^'\"]+)['\"]",
    re.DOTALL
)

# Dialog
DIALOG_TITLE = re.compile(
    r"AlertDialog\s*\((?:[^()]|\([^()]*\))*?"
    r"title:\s*(?:const\s+)?Text\s*\(\s*['\"]([^'\"]+)['\"]",
    re.DOTALL
)

# SnackBar messages
SNACKBAR = re.compile(
    r"SnackBar\s*\((?:[^()]|\([^()]*\))*?"
    r"content:\s*(?:const\s+)?Text\s*\(\s*['\"]([^'\"]+)['\"]",
    re.DOTALL
)

# PopupMenuItem
POPUP = re.compile(
    r"PopupMenuItem[^(]*\((?:[^()]|\([^()]*\))*?"
    r"child:\s*(?:const\s+)?Text\s*\(\s*['\"]([^'\"]+)['\"]",
    re.DOTALL
)

# APIs
API_PATTERN = re.compile(r"['\"](/(?:attendance|leaves|employee|hr|api|accounts|companies|subscriptions)/[^'\"?\s]+)['\"]?")

# Navigation
NAVIGATE = re.compile(r"MaterialPageRoute\s*\(\s*builder:\s*\([^)]*\)\s*=>\s*(?:const\s+)?(\w+)")

# Icons for feature detection
ICON_PATTERN = re.compile(r"Icons\.(\w+)")

# Chips
CHIP = re.compile(
    r"(?:Chip|ActionChip|FilterChip|InputChip|Choice Chip)\s*\((?:[^()]|\([^()]*\))*?"
    r"label:\s*(?:const\s+)?Text\s*\(\s*['\"]([^'\"]+)['\"]",
    re.DOTALL
)


def clean(s):
    return re.sub(r'\s+', ' ', s).strip() if s else ''


def split_by_class(text):
    positions = [(m.start(), m.group(1)) for m in CLASS_PATTERN.finditer(text)]
    positions.sort()
    parts = {}
    for i, (start, name) in enumerate(positions):
        end = positions[i + 1][0] if i + 1 < len(positions) else len(text)
        parts[name] = text[start:end]
    return parts


def extract_all(text):
    result = {
        'appbar_titles': set(),
        'bottom_nav': set(),
        'tabs': set(),
        'grid_cards': set(),
        'buttons': set(),
        'icon_buttons': set(),
        'form_fields': set(),
        'dropdowns': set(),
        'list_tiles': set(),
        'switch_tiles': set(),
        'popup_menus': set(),
        'chips': set(),
        'dialogs': set(),
        'snackbars': set(),
        'apis': set(),
        'navigates_to': set(),
        'has_print': False,
        'has_export': False,
        'has_download': False,
        'has_search': False,
        'has_filter': False,
        'has_edit': False,
        'has_delete': False,
        'has_add': False,
        'has_save': False,
        'has_refresh': False,
    }
    
    # AppBar
    for t in APPBAR_STR.findall(text):
        result['appbar_titles'].add(clean(t))
    for ar, en in APPBAR_TERNARY.findall(text):
        result['appbar_titles'].add(f"{clean(ar)} / {clean(en)}")
    
    # Bottom Nav
    for match in BOTTOM_NAV.finditer(text):
        for g in match.groups():
            if g and clean(g) and len(g) < 40:
                result['bottom_nav'].add(clean(g))
                break
    
    # Tabs
    for t in TAB_TEXT.findall(text):
        result['tabs'].add(clean(t))
    
    # Grid Cards
    for match in GRID_CARD.findall(text):
        for item in match:
            if item and clean(item):
                result['grid_cards'].add(clean(item))
    
    # Buttons
    for match in BUTTON_ANY.finditer(text):
        btn_type = match.group(1)
        label = match.group(2) or match.group(3)
        if label:
            result['buttons'].add(f"{clean(label)} ({btn_type})")
    
    # Icon Buttons
    for t in ICON_BTN.findall(text):
        result['icon_buttons'].add(clean(t))
    for t in FAB.findall(text):
        result['icon_buttons'].add(f"[+] {clean(t)}")
    
    # Form Fields
    for t in FORM_LABEL.findall(text):
        result['form_fields'].add(clean(t))
    
    # Dropdowns
    for t in DROPDOWN.findall(text):
        result['dropdowns'].add(clean(t))
    
    # ListTiles
    for t in LIST_TILE.findall(text):
        result['list_tiles'].add(clean(t))
    
    # Switch tiles
    for t in SWITCH_TILE.findall(text):
        result['switch_tiles'].add(clean(t))
    
    # Popup Menu
    for t in POPUP.findall(text):
        result['popup_menus'].add(clean(t))
    
    # Chips
    for t in CHIP.findall(text):
        result['chips'].add(clean(t))
    
    # Dialogs
    for t in DIALOG_TITLE.findall(text):
        result['dialogs'].add(clean(t))
    
    # SnackBars
    for t in SNACKBAR.findall(text):
        result['snackbars'].add(clean(t))
    
    # APIs
    for m in API_PATTERN.findall(text):
        url = m.split('?')[0].split("'")[0].split('"')[0]
        url = re.sub(r'\$\{[^}]+\}', '{id}', url)
        url = re.sub(r'\$\w+', '{id}', url)
        if len(url) > 4 and '.dart' not in url:
            result['apis'].add(url.rstrip('/'))
    
    # Navigation
    for m in NAVIGATE.findall(text):
        result['navigates_to'].add(m)
    
    # Features by icons
    icons_lower = ' '.join(ICON_PATTERN.findall(text)).lower()
    result['has_print'] = 'print' in icons_lower
    result['has_export'] = any(x in icons_lower for x in ['upload', 'share', 'file_upload'])
    result['has_download'] = any(x in icons_lower for x in ['download', 'file_download', 'cloud_download'])
    result['has_search'] = 'search' in icons_lower
    result['has_filter'] = any(x in icons_lower for x in ['filter', 'tune'])
    result['has_edit'] = 'edit' in icons_lower
    result['has_delete'] = 'delete' in icons_lower
    result['has_add'] = 'add' in icons_lower
    result['has_save'] = 'save' in icons_lower or 'done' in icons_lower
    result['has_refresh'] = 'refresh' in icons_lower
    
    # Convert to sorted lists
    for key in ['appbar_titles', 'bottom_nav', 'tabs', 'grid_cards', 'buttons',
                'icon_buttons', 'form_fields', 'dropdowns', 'list_tiles',
                'switch_tiles', 'popup_menus', 'chips', 'dialogs', 'snackbars',
                'apis', 'navigates_to']:
        result[key] = sorted(list(result[key]))
    
    return result


# ============================================
# Scan all files
# ============================================
print("[SCAN] Analyzing all screens...")
all_screens = {}

# main.dart
main_file = MOBILE_DIR / "main.dart"
if main_file.exists():
    text = main_file.read_text(encoding="utf-8", errors="ignore")
    for class_name, class_text in split_by_class(text).items():
        data = extract_all(class_text)
        data['name'] = class_name
        data['file'] = 'lib/main.dart'
        all_screens[class_name] = data

# screens folder
screens_root = MOBILE_DIR / "screens"
if screens_root.exists():
    for fp in screens_root.rglob("*.dart"):
        if "_backup" in str(fp) or ".bak" in str(fp):
            continue
        try:
            text = fp.read_text(encoding="utf-8", errors="ignore")
            classes = CLASS_PATTERN.findall(text)
            if classes:
                name = classes[0]
                data = extract_all(text)
                data['name'] = name
                data['file'] = str(fp).replace('\\', '/')
                all_screens[name] = data
        except:
            pass

print(f"[OK] Analyzed {len(all_screens)} screens")

# ============================================
# Build detailed guide
# ============================================
print("[BUILD] Building detailed guide...")

# تصنيف الشاشات
def classify(name, file):
    path = file.lower()
    if any(x in name.lower() for x in ['login', 'splash', 'changepassword', 'activateaccount']):
        return ('auth', '🔐 المصادقة')
    if '/employee/' in path or name.startswith('Employee') or name in ['LeavesScreen', 'RequestsScreen', 'HistoryScreen', 'MyItemsScreen', 'NotificationsScreen', 'CharterScreen', 'FieldVisitsScreen', 'MyShiftScreen', 'MyWorkLocationsScreen']:
        return ('employee', '👤 شاشات الموظف')
    if '/manager/payroll/' in path:
        return ('payroll', '💰 شاشات الرواتب')
    if '/manager/shifts/' in path:
        return ('shifts', '⏰ شاشات الشيفتات')
    if '/manager/reports/' in path:
        return ('reports', '📊 شاشات التقارير')
    if '/manager/' in path or name.startswith('Manager'):
        return ('manager', '👨‍💼 شاشات المدير/صاحب الشركة')
    return ('other', '🔧 شاشات أخرى')

# Group screens
grouped = defaultdict(list)
for name, data in all_screens.items():
    category, category_name = classify(name, data['file'])
    grouped[(category, category_name)].append((name, data))

# Sort categories in specific order
category_order = ['auth', 'employee', 'manager', 'payroll', 'shifts', 'reports', 'other']

# Build markdown
md = []
md.append("# 📚 دليل الشاشات التفصيلي - MotionHR")
md.append("")
md.append(f"**تاريخ الإصدار:** {datetime.now().strftime('%Y-%m-%d %H:%M')}")
md.append(f"**عدد الشاشات:** {len(all_screens)}")
md.append("**المصدر:** استخراج مباشر من كود الشاشات الفعلي")
md.append("")
md.append("---")
md.append("")

# Summary Table
md.append("## 📊 ملخص الشاشات")
md.append("")
md.append("| القسم | عدد الشاشات |")
md.append("|-------|-------------|")
for cat_key in category_order:
    matching = [k for k in grouped.keys() if k[0] == cat_key]
    for key in matching:
        md.append(f"| {key[1]} | {len(grouped[key])} |")
md.append(f"| **الإجمالي** | **{len(all_screens)}** |")
md.append("")
md.append("---")
md.append("")

# Table of Contents
md.append("## 📑 جدول المحتويات")
md.append("")
for cat_key in category_order:
    matching = [k for k in grouped.keys() if k[0] == cat_key]
    for key in matching:
        md.append(f"- [{key[1]}](#{cat_key})")
        for name, data in sorted(grouped[key], key=lambda x: x[0]):
            md.append(f"  - [{name}](#{name.lower()})")
md.append("")
md.append("---")
md.append("")

# Details per category
for cat_key in category_order:
    matching = [k for k in grouped.keys() if k[0] == cat_key]
    if not matching:
        continue
    
    for key in matching:
        md.append(f"# <a id='{cat_key}'></a>{key[1]}")
        md.append("")
        md.append(f"**عدد الشاشات:** {len(grouped[key])}")
        md.append("")
        md.append("---")
        md.append("")
        
        for name, data in sorted(grouped[key], key=lambda x: x[0]):
            md.append(f"## <a id='{name.lower()}'></a>📱 {name}")
            md.append("")
            md.append(f"**📁 الملف:** `{data['file']}`")
            
            if data['appbar_titles']:
                md.append(f"**🏷️ عنوان الشاشة:**")
                for t in data['appbar_titles']:
                    md.append(f"- {t}")
            
            md.append("")
            
            # الميزات المتاحة
            features = []
            if data['has_print']: features.append("🖨️ طباعة")
            if data['has_export']: features.append("📤 تصدير")
            if data['has_download']: features.append("⬇️ تحميل")
            if data['has_search']: features.append("🔍 بحث")
            if data['has_filter']: features.append("🔽 فلترة")
            if data['has_refresh']: features.append("🔄 تحديث")
            if data['has_edit']: features.append("✏️ تعديل")
            if data['has_delete']: features.append("🗑️ حذف")
            if data['has_add']: features.append("➕ إضافة")
            if data['has_save']: features.append("💾 حفظ")
            
            if features:
                md.append("### ✨ الميزات المتاحة")
                md.append(" • ".join(features))
                md.append("")
            
            # Bottom Navigation
            if data['bottom_nav']:
                md.append(f"### 🧭 التبويبات السفلية ({len(data['bottom_nav'])})")
                for item in data['bottom_nav']:
                    md.append(f"- **{item}**")
                md.append("")
            
            # Tabs
            if data['tabs']:
                md.append(f"### 📑 التبويبات ({len(data['tabs'])})")
                for tab in data['tabs']:
                    md.append(f"- **{tab}**")
                md.append("")
            
            # Grid Cards (kartes)
            if data['grid_cards']:
                md.append(f"### 🎴 الكارتات الرئيسية ({len(data['grid_cards'])})")
                md.append("")
                for i, card in enumerate(data['grid_cards'], 1):
                    md.append(f"{i}. **{card}**")
                md.append("")
            
            # Buttons
            if data['buttons']:
                md.append(f"### 🔘 الأزرار ({len(data['buttons'])})")
                md.append("")
                for btn in data['buttons']:
                    md.append(f"- {btn}")
                md.append("")
            
            # Icon Buttons in AppBar
            if data['icon_buttons']:
                md.append(f"### 🎯 أيقونات AppBar ({len(data['icon_buttons'])})")
                for icon in data['icon_buttons']:
                    md.append(f"- **{icon}**")
                md.append("")
            
            # Form Fields
            if data['form_fields']:
                md.append(f"### 📝 حقول الإدخال ({len(data['form_fields'])})")
                md.append("")
                for field in data['form_fields']:
                    md.append(f"- **{field}**")
                md.append("")
            
            # Dropdowns
            if data['dropdowns']:
                md.append(f"### 🔽 القوائم المنسدلة ({len(data['dropdowns'])})")
                for dd in data['dropdowns']:
                    md.append(f"- **{dd}**")
                md.append("")
            
            # List Items
            if data['list_tiles']:
                md.append(f"### 📋 عناصر القائمة ({len(data['list_tiles'])})")
                md.append("")
                for i, tile in enumerate(data['list_tiles'][:20], 1):
                    md.append(f"{i}. {tile}")
                if len(data['list_tiles']) > 20:
                    md.append(f"... و {len(data['list_tiles']) - 20} عنصر آخر")
                md.append("")
            
            # Switch tiles
            if data['switch_tiles']:
                md.append(f"### 🔧 مفاتيح التبديل ({len(data['switch_tiles'])})")
                for sw in data['switch_tiles']:
                    md.append(f"- **{sw}**")
                md.append("")
            
            # Popup menus
            if data['popup_menus']:
                md.append(f"### ⋮ قوائم Popup ({len(data['popup_menus'])})")
                for pop in data['popup_menus']:
                    md.append(f"- {pop}")
                md.append("")
            
            # Chips
            if data['chips']:
                md.append(f"### 🏷️ Chips ({len(data['chips'])})")
                for chip in data['chips']:
                    md.append(f"- {chip}")
                md.append("")
            
            # Dialogs
            if data['dialogs']:
                md.append(f"### 💬 Dialogs ({len(data['dialogs'])})")
                for dlg in data['dialogs']:
                    md.append(f"- **{dlg}**")
                md.append("")
            
            # SnackBar Messages
            if data['snackbars']:
                md.append(f"### 📢 رسائل SnackBar ({len(data['snackbars'])})")
                for sb in data['snackbars'][:10]:
                    md.append(f"- {sb}")
                if len(data['snackbars']) > 10:
                    md.append(f"... و {len(data['snackbars']) - 10} رسالة أخرى")
                md.append("")
            
            # APIs Used
            if data['apis']:
                md.append(f"### 🌐 APIs المستخدمة ({len(data['apis'])})")
                md.append("")
                for api in data['apis']:
                    md.append(f"- `{api}`")
                md.append("")
            
            # Navigation
            if data['navigates_to']:
                md.append(f"### ➡️ تنتقل إلى الشاشات ({len(data['navigates_to'])})")
                md.append("")
                for nav in data['navigates_to']:
                    md.append(f"- `{nav}`")
                md.append("")
            
            md.append("---")
            md.append("")

# Save
OUTPUT.write_text("\n".join(md), encoding="utf-8")

# Statistics
total_buttons = sum(len(s['buttons']) for s in all_screens.values())
total_forms = sum(len(s['form_fields']) + len(s['dropdowns']) for s in all_screens.values())
total_grid = sum(len(s['grid_cards']) for s in all_screens.values())
total_apis = len(set(api for s in all_screens.values() for api in s['apis']))

print(f"\n[OK] Guide created!")
print(f"[OK] File: {OUTPUT.absolute()}")
print(f"[OK] Size: {OUTPUT.stat().st_size / 1024:.1f} KB")
print(f"[OK] Lines: {len(md)}")
print(f"\n📊 Statistics:")
print(f"  • Total Screens: {len(all_screens)}")
print(f"  • Total Buttons: {total_buttons}")
print(f"  • Total Form Fields: {total_forms}")
print(f"  • Total Grid Cards: {total_grid}")
print(f"  • Total Unique APIs: {total_apis}")
