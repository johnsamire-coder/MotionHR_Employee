"""
MotionHR - Ultimate Report v2 (Better UI Detection)
====================================================
"""
import re
import json
from pathlib import Path
from collections import defaultdict
from datetime import datetime

MOBILE_DIR = Path("lib")
OUTPUT = Path("SCREEN_DETAILS_REPORT.md")

# ============================================
# PATTERNS - محسّنة أكثر
# ============================================

CLASS_PATTERN = re.compile(r"class\s+(\w+(?:Screen|Page|Shell|Dashboard|Widget|View|Hub|Router|Dialog))\s+extends")

# AppBar titles - كل الأشكال
APPBAR_ANY = re.compile(
    r"AppBar\s*\((?:[^{}]|\{[^{}]*\})*?title:\s*(?:const\s+)?Text\s*\(\s*(['\"])((?:(?!\1).)+)\1",
    re.DOTALL
)
APPBAR_TERNARY = re.compile(
    r"AppBar\s*\((?:[^{}]|\{[^{}]*\})*?title:\s*Text\s*\(\s*isAr\s*\?\s*['\"]([^'\"]+)['\"]\s*:\s*['\"]([^'\"]+)['\"]",
    re.DOTALL
)
APPBAR_L10N = re.compile(
    r"AppBar\s*\((?:[^{}]|\{[^{}]*\})*?title:\s*(?:const\s+)?Text\s*\(\s*context\.l10n\.(\w+)",
    re.DOTALL
)

# All button-like widgets (ElevatedButton, TextButton, OutlinedButton, FilledButton)
ANY_BUTTON = re.compile(
    r"(ElevatedButton|TextButton|OutlinedButton|FilledButton|CupertinoButton)"
    r"(?:\.\w+)?"
    r"\s*\((?:[^()]|\([^()]*\))*?"
    r"(?:child|label):\s*(?:const\s+)?"
    r"(?:Text\s*\(\s*['\"]([^'\"]+)['\"]|"
    r"Row\s*\([^)]*?Text\s*\(\s*['\"]([^'\"]+)['\"])",
    re.DOTALL
)

# Icon + label pattern (زي ElevatedButton.icon)
ICON_BUTTON_LABEL = re.compile(
    r"(?:ElevatedButton|TextButton|OutlinedButton|FilledButton)\.icon"
    r"\s*\((?:[^()]|\([^()]*\))*?"
    r"label:\s*(?:const\s+)?Text\s*\(\s*['\"]([^'\"]+)['\"]",
    re.DOTALL
)

# IconButton with tooltip
ICON_BUTTON_TOOLTIP = re.compile(
    r"IconButton\s*\((?:[^()]|\([^()]*\))*?tooltip:\s*['\"]([^'\"]+)['\"]",
    re.DOTALL
)

# FloatingActionButton
FAB_TOOLTIP = re.compile(
    r"FloatingActionButton(?:\.\w+)?\s*\((?:[^()]|\([^()]*\))*?tooltip:\s*['\"]([^'\"]+)['\"]",
    re.DOTALL
)

# Form fields - all types
FORM_FIELD = re.compile(
    r"(?:TextField|TextFormField)\s*\((?:[^()]|\([^()]*\))*?"
    r"(?:labelText|hintText|helperText):\s*['\"]([^'\"]+)['\"]",
    re.DOTALL
)

# InputDecoration
INPUT_DEC = re.compile(
    r"InputDecoration\s*\((?:[^()]|\([^()]*\))*?"
    r"(?:labelText|hintText):\s*['\"]([^'\"]+)['\"]",
    re.DOTALL
)

# Dropdowns
DROPDOWN = re.compile(
    r"DropdownButton(?:FormField)?[^(]*\((?:[^()]|\([^()]*\))*?"
    r"hint:\s*(?:const\s+)?Text\s*\(\s*['\"]([^'\"]+)['\"]",
    re.DOTALL
)

# Tabs
TAB_TEXT = re.compile(r"Tab\s*\(\s*(?:icon:[^,]+,\s*)?text:\s*(?:const\s+)?['\"]([^'\"]+)['\"]")
TAB_L10N = re.compile(r"Tab\s*\(\s*text:\s*context\.l10n\.(\w+)")

# ListTile
LIST_TILE = re.compile(
    r"ListTile\s*\((?:[^()]|\([^()]*\))*?"
    r"title:\s*(?:const\s+)?Text\s*\(\s*['\"]([^'\"]+)['\"]",
    re.DOTALL
)

# Bottom Nav
BOTTOM_NAV = re.compile(
    r"BottomNavigationBarItem\s*\((?:[^()]|\([^()]*\))*?"
    r"label:\s*(?:['\"]([^'\"]+)['\"]|context\.l10n\.(\w+)|isAr\s*\?\s*['\"]([^'\"]+)['\"]\s*:\s*['\"]([^'\"]+)['\"])",
    re.DOTALL
)

# Dialogs
DIALOG_TITLE = re.compile(
    r"AlertDialog\s*\((?:[^()]|\([^()]*\))*?"
    r"title:\s*(?:const\s+)?Text\s*\(\s*['\"]([^'\"]+)['\"]",
    re.DOTALL
)

# SnackBar
SNACKBAR = re.compile(
    r"SnackBar\s*\((?:[^()]|\([^()]*\))*?"
    r"content:\s*(?:const\s+)?Text\s*\(\s*['\"]([^'\"]+)['\"]",
    re.DOTALL
)

# PopupMenuItem
POPUP_MENU = re.compile(
    r"PopupMenuItem[^(]*\((?:[^()]|\([^()]*\))*?"
    r"child:\s*(?:const\s+)?Text\s*\(\s*['\"]([^'\"]+)['\"]",
    re.DOTALL
)

# SwitchListTile
SWITCH_TILE = re.compile(
    r"SwitchListTile\s*\((?:[^()]|\([^()]*\))*?"
    r"title:\s*(?:const\s+)?Text\s*\(\s*['\"]([^'\"]+)['\"]",
    re.DOTALL
)

# Chip
CHIP_LABEL = re.compile(
    r"(?:Chip|ActionChip|FilterChip|InputChip)\s*\((?:[^()]|\([^()]*\))*?"
    r"label:\s*(?:const\s+)?Text\s*\(\s*['\"]([^'\"]+)['\"]",
    re.DOTALL
)

# Grid card (specific)
GRID_CARD = re.compile(
    r"_gridCard\s*\(\s*"
    r"(?:isAr\s*\?\s*['\"]([^'\"]+)['\"][^,)]*?['\"]([^'\"]+)['\"]"
    r"|context\.l10n\.(\w+)"
    r"|['\"]([^'\"]+)['\"])"
)

# Icons - detect features
ICON_PATTERN = re.compile(r"Icons\.(\w+)")

# APIs
API_PATTERN = re.compile(
    r"['\"](/(?:attendance|leaves|employee|hr|api|accounts|companies|subscriptions|requests|notifications)/[^'\"?\s]+)"
)

# Navigation
NAV_PATTERN = re.compile(r"MaterialPageRoute\s*\(\s*builder:\s*\([^)]*\)\s*=>\s*(?:const\s+)?(\w+)")

# ============================================

def clean_text(s):
    return re.sub(r'\s+', ' ', s).strip() if s else ''

def clean_url(url):
    url = url.split('?')[0].split("'")[0].split('"')[0]
    url = re.sub(r'\$\{[^}]+\}', '{id}', url)
    url = re.sub(r'\$\w+', '{id}', url)
    return url.rstrip('/')

def split_by_class(text):
    positions = [(m.start(), m.group(1)) for m in CLASS_PATTERN.finditer(text)]
    positions.sort()
    parts = {}
    for i, (start, name) in enumerate(positions):
        end = positions[i + 1][0] if i + 1 < len(positions) else len(text)
        parts[name] = text[start:end]
    return parts

def analyze(text):
    result = {
        'appbar_titles': [],
        'buttons': set(),
        'icon_buttons': set(),
        'form_fields': set(),
        'dropdowns': set(),
        'tabs': set(),
        'list_tiles': set(),
        'bottom_nav': set(),
        'alert_dialogs': set(),
        'snackbars': set(),
        'popup_menus': set(),
        'switch_tiles': set(),
        'chips': set(),
        'grid_cards': set(),
        'apis': set(),
        'navigates_to': set(),
        'icons_used': set(),
    }
    
    # AppBar
    for match in APPBAR_ANY.finditer(text):
        result['appbar_titles'].append(clean_text(match.group(2)))
    for ar, en in APPBAR_TERNARY.findall(text):
        result['appbar_titles'].append(f"{clean_text(ar)} / {clean_text(en)}")
    for m in APPBAR_L10N.findall(text):
        result['appbar_titles'].append(f"l10n.{m}")
    result['appbar_titles'] = list(set(result['appbar_titles']))
    
    # Buttons - كل الأنواع
    for match in ANY_BUTTON.finditer(text):
        btn_type = match.group(1)
        label = match.group(2) or match.group(3)
        if label:
            result['buttons'].add(f"[{btn_type}] {clean_text(label)}")
    
    for label in ICON_BUTTON_LABEL.findall(text):
        result['buttons'].add(f"[IconLabel] {clean_text(label)}")
    
    # Icon buttons
    for m in ICON_BUTTON_TOOLTIP.findall(text):
        result['icon_buttons'].add(clean_text(m))
    for m in FAB_TOOLTIP.findall(text):
        result['icon_buttons'].add(f"[FAB] {clean_text(m)}")
    
    # Forms
    for m in FORM_FIELD.findall(text):
        result['form_fields'].add(clean_text(m))
    for m in INPUT_DEC.findall(text):
        result['form_fields'].add(clean_text(m))
    
    # Dropdowns
    for m in DROPDOWN.findall(text):
        result['dropdowns'].add(clean_text(m))
    
    # Tabs
    for m in TAB_TEXT.findall(text):
        result['tabs'].add(clean_text(m))
    for m in TAB_L10N.findall(text):
        result['tabs'].add(f"l10n.{m}")
    
    # ListTile
    for m in LIST_TILE.findall(text):
        result['list_tiles'].add(clean_text(m))
    
    # Bottom Nav
    for match in BOTTOM_NAV.finditer(text):
        for g in match.groups():
            if g:
                if len(g) < 30 and not g.startswith('l10n'):
                    result['bottom_nav'].add(clean_text(g))
                else:
                    result['bottom_nav'].add(f"l10n.{g}" if not g.startswith('l10n') else g)
                break
    
    # Dialogs
    for m in DIALOG_TITLE.findall(text):
        result['alert_dialogs'].add(clean_text(m))
    for m in SNACKBAR.findall(text):
        result['snackbars'].add(clean_text(m))
    
    # Popup
    for m in POPUP_MENU.findall(text):
        result['popup_menus'].add(clean_text(m))
    
    # Switch
    for m in SWITCH_TILE.findall(text):
        result['switch_tiles'].add(clean_text(m))
    
    # Chips
    for m in CHIP_LABEL.findall(text):
        result['chips'].add(clean_text(m))
    
    # Grid cards
    for match in GRID_CARD.findall(text):
        for item in match:
            if item and item.strip():
                result['grid_cards'].add(clean_text(item))
    
    # APIs
    for m in API_PATTERN.findall(text):
        cleaned = clean_url(m)
        if len(cleaned) > 4:
            result['apis'].add(cleaned)
    
    # Navigation
    for m in NAV_PATTERN.findall(text):
        result['navigates_to'].add(m)
    
    # Icons
    for m in ICON_PATTERN.findall(text):
        result['icons_used'].add(m)
    
    # Convert to sorted lists
    for key in ['buttons', 'icon_buttons', 'form_fields', 'dropdowns', 'tabs',
                'list_tiles', 'bottom_nav', 'alert_dialogs', 'snackbars',
                'popup_menus', 'switch_tiles', 'chips', 'grid_cards',
                'apis', 'navigates_to', 'icons_used']:
        result[key] = sorted(list(result[key]))
    
    return result

# ============================================
print("[SCAN] Analyzing files...")
all_screens = {}

main_file = MOBILE_DIR / "main.dart"
if main_file.exists():
    text = main_file.read_text(encoding="utf-8", errors="ignore")
    for class_name, class_text in split_by_class(text).items():
        data = analyze(class_text)
        data['name'] = class_name
        data['file'] = 'lib/main.dart'
        all_screens[class_name] = data

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
                data = analyze(text)
                data['name'] = name
                data['file'] = str(fp).replace('\\', '/')
                all_screens[name] = data
        except:
            pass

print(f"[OK] Analyzed {len(all_screens)} screens")

# Feature detection based on icons
FEATURE_ICONS = {
    'print': ['print', 'printer', 'local_printshop'],
    'export': ['upload', 'share', 'file_upload', 'ios_share'],
    'download': ['download', 'file_download', 'cloud_download', 'save_alt'],
    'search': ['search', 'search_outlined', 'find_in_page'],
    'filter': ['filter_list', 'filter_alt', 'tune', 'sort'],
    'refresh': ['refresh', 'sync', 'update'],
    'edit': ['edit', 'edit_outlined', 'create', 'mode_edit'],
    'delete': ['delete', 'delete_outline', 'remove_circle'],
    'add': ['add', 'add_circle', 'add_box'],
    'save': ['save', 'save_alt', 'check', 'done'],
    'pdf': ['picture_as_pdf'],
    'excel': ['table_chart', 'grid_on'],
    'notification': ['notifications', 'notifications_active'],
    'settings': ['settings', 'settings_outlined'],
    'lock': ['lock', 'lock_outline'],
}

def detect_features(icons):
    features = {}
    for feature, icon_names in FEATURE_ICONS.items():
        features[feature] = any(icon in icons for icon in icon_names)
    return features

# Build report
print("[BUILD] Building report...")
md = []
md.append("# 🔬 MotionHR - التقرير التفصيلي الفائق (v2)")
md.append("")
md.append(f"**التاريخ:** {datetime.now().strftime('%Y-%m-%d %H:%M')}")
md.append(f"**عدد الشاشات:** {len(all_screens)}")
md.append("")
md.append("---")
md.append("")

# جدول ملخص محسّن
md.append("## 📊 جدول ملخص شامل")
md.append("")
md.append("| # | الشاشة | Buttons | Icons | Forms | Tabs | Dialogs | APIs | Nav | مزايا |")
md.append("|---|--------|---------|-------|-------|------|---------|------|-----|-------|")

for i, (name, data) in enumerate(sorted(all_screens.items()), 1):
    features = detect_features(data['icons_used'])
    feat_str = ""
    if features['print']: feat_str += "🖨️"
    if features['export']: feat_str += "📤"
    if features['download']: feat_str += "⬇️"
    if features['search']: feat_str += "🔍"
    if features['filter']: feat_str += "🔽"
    if features['refresh']: feat_str += "🔄"
    if features['edit']: feat_str += "✏️"
    if features['delete']: feat_str += "🗑️"
    if features['add']: feat_str += "➕"
    if features['save']: feat_str += "💾"
    if features['pdf']: feat_str += "📄"
    
    md.append(
        f"| {i} | `{name}` | {len(data['buttons'])} | {len(data['icon_buttons'])} | "
        f"{len(data['form_fields']) + len(data['dropdowns'])} | {len(data['tabs'])} | "
        f"{len(data['alert_dialogs'])} | {len(data['apis'])} | {len(data['navigates_to'])} | "
        f"{feat_str or '-'} |"
    )

md.append("")
md.append("**رموز المزايا:** 🖨️=طباعة، 📤=تصدير، ⬇️=تحميل، 🔍=بحث، 🔽=فلترة، 🔄=تحديث، ✏️=تعديل، 🗑️=حذف، ➕=إضافة، 💾=حفظ، 📄=PDF")
md.append("")
md.append("---")
md.append("")

# تفاصيل كاملة
md.append("## 🔍 التفاصيل الكاملة")
md.append("")

for i, (name, data) in enumerate(sorted(all_screens.items()), 1):
    features = detect_features(data['icons_used'])
    active_features = [k for k, v in features.items() if v]
    
    md.append(f"### {i}. `{name}`")
    md.append("")
    md.append(f"**📁 الملف:** `{data['file']}`")
    
    if data['appbar_titles']:
        md.append(f"**🏷️ العنوان:** {' | '.join(data['appbar_titles'])}")
    
    if active_features:
        feat_labels = {
            'print': '🖨️ طباعة',
            'export': '📤 تصدير',
            'download': '⬇️ تحميل',
            'search': '🔍 بحث',
            'filter': '🔽 فلترة',
            'refresh': '🔄 تحديث',
            'edit': '✏️ تعديل',
            'delete': '🗑️ حذف',
            'add': '➕ إضافة',
            'save': '💾 حفظ',
            'pdf': '📄 PDF',
            'excel': '📊 Excel',
            'notification': '🔔 إشعارات',
            'settings': '⚙️ إعدادات',
            'lock': '🔒 قفل',
        }
        md.append(f"**✨ المزايا:** {' • '.join(feat_labels.get(f, f) for f in active_features)}")
    
    md.append("")
    
    sections_to_show = [
        ('bottom_nav', '🧭 التبويبات السفلية'),
        ('tabs', '📑 التبويبات'),
        ('buttons', '🔘 الأزرار'),
        ('icon_buttons', '🎯 أزرار الأيقونات'),
        ('grid_cards', '🎴 كارتات الميزات'),
        ('form_fields', '📝 حقول الإدخال'),
        ('dropdowns', '🔽 القوائم المنسدلة'),
        ('list_tiles', '📋 عناصر القائمة'),
        ('switch_tiles', '🔧 مفاتيح التبديل'),
        ('popup_menus', '⋮ قوائم Popup'),
        ('chips', '🏷️ Chips'),
        ('alert_dialogs', '💬 Dialogs'),
        ('snackbars', '📢 رسائل SnackBar'),
        ('apis', '🌐 APIs'),
        ('navigates_to', '➡️ ينتقل إلى'),
    ]
    
    for key, label in sections_to_show:
        items = data[key]
        if items:
            md.append(f"**{label} ({len(items)}):**")
            display_items = items[:15]
            for item in display_items:
                if key == 'apis' or key == 'navigates_to':
                    md.append(f"- `{item}`")
                else:
                    md.append(f"- {item}")
            if len(items) > 15:
                md.append(f"- ... و {len(items) - 15} عنصر آخر")
            md.append("")
    
    md.append("---")
    md.append("")

OUTPUT.write_text("\n".join(md), encoding="utf-8")

# Statistics
total_buttons = sum(len(s['buttons']) for s in all_screens.values())
total_icons = sum(len(s['icon_buttons']) for s in all_screens.values())
total_forms = sum(len(s['form_fields']) + len(s['dropdowns']) for s in all_screens.values())
total_dialogs = sum(len(s['alert_dialogs']) for s in all_screens.values())
total_apis = len(set(api for s in all_screens.values() for api in s['apis']))

print(f"\n[OK] Report: {OUTPUT.absolute()}")
print(f"[OK] Size: {OUTPUT.stat().st_size / 1024:.1f} KB")
print(f"[OK] Screens: {len(all_screens)}")
print(f"[OK] Total Buttons: {total_buttons}")
print(f"[OK] Total Icon Buttons: {total_icons}")
print(f"[OK] Total Form Fields: {total_forms}")
print(f"[OK] Total Dialogs: {total_dialogs}")
print(f"[OK] Total Unique APIs: {total_apis}")

# Features
print(f"\n[FEATURES]")
for feature in ['print', 'export', 'download', 'search', 'filter', 'edit', 'delete', 'add', 'save']:
    count = sum(1 for s in all_screens.values() if any(icon in s['icons_used'] for icon in FEATURE_ICONS[feature]))
    print(f"  {feature}: {count} screens")
