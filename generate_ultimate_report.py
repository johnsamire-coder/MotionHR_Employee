"""
MotionHR - Ultimate Screen Details Report
==========================================
يستخرج كل تفاصيل كل شاشة بأدق شكل ممكن
"""
import re
import json
from pathlib import Path
from collections import defaultdict
from datetime import datetime

MOBILE_DIR = Path("lib")
OUTPUT = Path("SCREEN_DETAILS_REPORT.md")

# ============================================
# All possible UI elements to detect
# ============================================
PATTERNS = {
    # Class definitions
    'class': re.compile(r"class\s+(\w+(?:Screen|Page|Shell|Dashboard|Widget|View|Hub|Router|Dialog|BottomSheet))\s+extends"),
    
    # AppBar
    'appbar_title_str': re.compile(r"""AppBar\s*\([^{]*?title:\s*(?:const\s+)?Text\s*\(\s*['"]([^'"]{2,120})['"]""", re.DOTALL),
    'appbar_title_ternary': re.compile(r"""AppBar\s*\([^{]*?title:\s*Text\s*\(\s*isAr\s*\?\s*['"]([^'"]+)['"]\s*:\s*['"]([^'"]+)['"]""", re.DOTALL),
    'appbar_title_l10n': re.compile(r"""AppBar\s*\([^{]*?title:\s*(?:const\s+)?Text\s*\(\s*context\.l10n\.(\w+)""", re.DOTALL),
    
    # Buttons
    'elevated_button': re.compile(r"""ElevatedButton[^(]*\([^)]*?(?:child|label):\s*(?:const\s+)?Text\s*\(\s*['"]([^'"]{2,120})['"]""", re.DOTALL),
    'text_button': re.compile(r"""TextButton[^(]*\([^)]*?child:\s*(?:const\s+)?Text\s*\(\s*['"]([^'"]{2,120})['"]""", re.DOTALL),
    'outlined_button': re.compile(r"""OutlinedButton[^(]*\([^)]*?child:\s*(?:const\s+)?Text\s*\(\s*['"]([^'"]{2,120})['"]""", re.DOTALL),
    'icon_button_tooltip': re.compile(r"""IconButton\s*\([^)]*?tooltip:\s*['"]([^'"]{2,80})['"]""", re.DOTALL),
    'floating_button_tooltip': re.compile(r"""FloatingActionButton\s*\([^)]*?tooltip:\s*['"]([^'"]{2,80})['"]""", re.DOTALL),
    
    # Icons that suggest actions
    'print_icon': re.compile(r"Icons\.(print|printer)"),
    'download_icon': re.compile(r"Icons\.(download|file_download|cloud_download)"),
    'export_icon': re.compile(r"Icons\.(export|share|upload|file_upload)"),
    'edit_icon': re.compile(r"Icons\.(edit|edit_outlined|create)"),
    'delete_icon': re.compile(r"Icons\.(delete|delete_outline|remove)"),
    'add_icon': re.compile(r"Icons\.(add|add_circle|plus)"),
    'save_icon': re.compile(r"Icons\.(save|check|done)"),
    'search_icon': re.compile(r"Icons\.(search|search_outlined)"),
    'filter_icon': re.compile(r"Icons\.(filter|filter_list|tune)"),
    'refresh_icon': re.compile(r"Icons\.refresh"),
    
    # Form fields
    'text_field': re.compile(r"""(?:TextField|TextFormField)\s*\([^)]*?(?:label|labelText|hint|hintText):\s*['"]([^'"]{2,80})['"]""", re.DOTALL),
    'text_field_l10n': re.compile(r"""(?:TextField|TextFormField)\s*\([^)]*?(?:label|labelText|hint|hintText):\s*context\.l10n\.(\w+)""", re.DOTALL),
    
    # Dropdowns
    'dropdown': re.compile(r"""DropdownButton[^(]*\([^)]*?hint:\s*(?:const\s+)?Text\s*\(\s*['"]([^'"]{2,80})['"]""", re.DOTALL),
    
    # Tabs
    'tab_text': re.compile(r"""Tab\s*\(\s*text:\s*['"]([^'"]{2,80})['"]"""),
    'tab_l10n': re.compile(r"""Tab\s*\(\s*text:\s*context\.l10n\.(\w+)"""),
    
    # ListTiles
    'listtile_str': re.compile(r"""ListTile\s*\([^)]*?title:\s*(?:const\s+)?Text\s*\(\s*['"]([^'"]{2,120})['"]""", re.DOTALL),
    
    # Bottom Nav
    'bottom_nav_str': re.compile(r"""BottomNavigationBarItem\s*\([^)]*?label:\s*['"]([^'"]{2,60})['"]""", re.DOTALL),
    'bottom_nav_l10n': re.compile(r"""BottomNavigationBarItem\s*\([^)]*?label:\s*context\.l10n\.(\w+)""", re.DOTALL),
    
    # Dialogs
    'alert_dialog_title': re.compile(r"""AlertDialog\s*\([^)]*?title:\s*(?:const\s+)?Text\s*\(\s*['"]([^'"]{2,120})['"]""", re.DOTALL),
    'snackbar_content': re.compile(r"""SnackBar\s*\([^)]*?content:\s*(?:const\s+)?Text\s*\(\s*['"]([^'"]{2,120})['"]""", re.DOTALL),
    
    # PopupMenu
    'popup_menu_item': re.compile(r"""PopupMenuItem[^(]*\([^)]*?child:\s*(?:const\s+)?Text\s*\(\s*['"]([^'"]{2,80})['"]""", re.DOTALL),
    
    # SwitchListTile
    'switch_tile': re.compile(r"""SwitchListTile\s*\([^)]*?title:\s*(?:const\s+)?Text\s*\(\s*['"]([^'"]{2,80})['"]""", re.DOTALL),
    
    # Chips
    'chip_label': re.compile(r"""Chip\s*\([^)]*?label:\s*(?:const\s+)?Text\s*\(\s*['"]([^'"]{2,60})['"]""", re.DOTALL),
    
    # APIs
    'api': re.compile(r"""(/(?:attendance|leaves|employee|hr|api|accounts|companies|subscriptions|requests|notifications)/[a-zA-Z0-9_\-/${{}}.]+)"""),
    
    # Navigation
    'navigate': re.compile(r"""MaterialPageRoute\s*\(\s*builder:\s*\([^)]*\)\s*=>\s*(?:const\s+)?(\w+)"""),
    
    # Grid cards (specific to this app)
    'grid_card': re.compile(r"""_gridCard\s*\(\s*(?:isAr\s*\?\s*['"]([^'"]{2,80})['"][^,)]*?['"]([^'"]{2,80})['"]|context\.l10n\.(\w+)|['"]([^'"]{2,80})['"])"""),
}

def clean_text(s):
    return re.sub(r'\s+', ' ', s).strip() if s else ''

def clean_url(url):
    url = url.split('?')[0].split("'")[0].split('"')[0]
    url = re.sub(r'\$\{[^}]+\}', '{id}', url)
    url = re.sub(r'\$\w+', '{id}', url)
    return url.rstrip('/')

def split_by_class(text):
    """Split file by class boundaries"""
    positions = []
    for m in PATTERNS['class'].finditer(text):
        positions.append((m.start(), m.group(1)))
    positions.sort()
    parts = {}
    for i, (start, name) in enumerate(positions):
        end = positions[i + 1][0] if i + 1 < len(positions) else len(text)
        parts[name] = text[start:end]
    return parts

def analyze_class_text(text):
    """Extract ALL possible details from a class body"""
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
        # Special features
        'has_print': False,
        'has_export': False,
        'has_download': False,
        'has_search': False,
        'has_filter': False,
        'has_refresh': False,
        'has_edit': False,
        'has_delete': False,
        'has_add': False,
        'has_save': False,
    }
    
    # AppBar titles
    for m in PATTERNS['appbar_title_str'].findall(text):
        result['appbar_titles'].append(clean_text(m))
    for ar, en in PATTERNS['appbar_title_ternary'].findall(text):
        result['appbar_titles'].append(f"{clean_text(ar)} / {clean_text(en)}")
    for m in PATTERNS['appbar_title_l10n'].findall(text):
        result['appbar_titles'].append(f"l10n.{m}")
    result['appbar_titles'] = list(set(result['appbar_titles']))
    
    # Buttons
    for m in PATTERNS['elevated_button'].findall(text):
        result['buttons'].add(f"[Elevated] {clean_text(m)}")
    for m in PATTERNS['text_button'].findall(text):
        result['buttons'].add(f"[Text] {clean_text(m)}")
    for m in PATTERNS['outlined_button'].findall(text):
        result['buttons'].add(f"[Outlined] {clean_text(m)}")
    
    # Icon buttons
    for m in PATTERNS['icon_button_tooltip'].findall(text):
        result['icon_buttons'].add(clean_text(m))
    for m in PATTERNS['floating_button_tooltip'].findall(text):
        result['icon_buttons'].add(f"[FAB] {clean_text(m)}")
    
    # Form fields
    for m in PATTERNS['text_field'].findall(text):
        result['form_fields'].add(clean_text(m))
    for m in PATTERNS['text_field_l10n'].findall(text):
        result['form_fields'].add(f"l10n.{m}")
    
    # Dropdowns
    for m in PATTERNS['dropdown'].findall(text):
        result['dropdowns'].add(clean_text(m))
    
    # Tabs
    for m in PATTERNS['tab_text'].findall(text):
        result['tabs'].add(clean_text(m))
    for m in PATTERNS['tab_l10n'].findall(text):
        result['tabs'].add(f"l10n.{m}")
    
    # ListTiles
    for m in PATTERNS['listtile_str'].findall(text):
        result['list_tiles'].add(clean_text(m))
    
    # Bottom Nav
    for m in PATTERNS['bottom_nav_str'].findall(text):
        result['bottom_nav'].add(clean_text(m))
    for m in PATTERNS['bottom_nav_l10n'].findall(text):
        result['bottom_nav'].add(f"l10n.{m}")
    
    # Dialogs
    for m in PATTERNS['alert_dialog_title'].findall(text):
        result['alert_dialogs'].add(clean_text(m))
    for m in PATTERNS['snackbar_content'].findall(text):
        result['snackbars'].add(clean_text(m))
    
    # Popup menus
    for m in PATTERNS['popup_menu_item'].findall(text):
        result['popup_menus'].add(clean_text(m))
    
    # Switch tiles
    for m in PATTERNS['switch_tile'].findall(text):
        result['switch_tiles'].add(clean_text(m))
    
    # Chips
    for m in PATTERNS['chip_label'].findall(text):
        result['chips'].add(clean_text(m))
    
    # Grid cards
    for match in PATTERNS['grid_card'].findall(text):
        for item in match:
            if item and item.strip():
                result['grid_cards'].add(clean_text(item))
    
    # APIs
    for m in PATTERNS['api'].findall(text):
        cleaned = clean_url(m)
        if len(cleaned) > 4 and '.dart' not in cleaned:
            result['apis'].add(cleaned)
    
    # Navigation
    for m in PATTERNS['navigate'].findall(text):
        result['navigates_to'].add(m)
    
    # Special features (by icon detection)
    result['has_print'] = bool(PATTERNS['print_icon'].search(text))
    result['has_export'] = bool(PATTERNS['export_icon'].search(text))
    result['has_download'] = bool(PATTERNS['download_icon'].search(text))
    result['has_search'] = bool(PATTERNS['search_icon'].search(text))
    result['has_filter'] = bool(PATTERNS['filter_icon'].search(text))
    result['has_refresh'] = bool(PATTERNS['refresh_icon'].search(text))
    result['has_edit'] = bool(PATTERNS['edit_icon'].search(text))
    result['has_delete'] = bool(PATTERNS['delete_icon'].search(text))
    result['has_add'] = bool(PATTERNS['add_icon'].search(text))
    result['has_save'] = bool(PATTERNS['save_icon'].search(text))
    
    # Convert sets to sorted lists
    for key in ['buttons', 'icon_buttons', 'form_fields', 'dropdowns', 'tabs', 
                'list_tiles', 'bottom_nav', 'alert_dialogs', 'snackbars',
                'popup_menus', 'switch_tiles', 'chips', 'grid_cards', 
                'apis', 'navigates_to']:
        result[key] = sorted(list(result[key]))
    
    return result

# ============================================
# Main analysis
# ============================================
print("[SCAN] Analyzing all files...")

all_screens = {}

# main.dart
main_file = MOBILE_DIR / "main.dart"
if main_file.exists():
    text = main_file.read_text(encoding="utf-8", errors="ignore")
    for class_name, class_text in split_by_class(text).items():
        data = analyze_class_text(class_text)
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
            classes = PATTERNS['class'].findall(text)
            if classes:
                name = classes[0]
                data = analyze_class_text(text)
                data['name'] = name
                data['file'] = str(fp).replace('\\', '/')
                all_screens[name] = data
        except Exception as e:
            print(f"  [WARN] Failed: {fp}: {e}")

print(f"[OK] Analyzed {len(all_screens)} screens")

# ============================================
# Build detailed report
# ============================================
print("[BUILD] Building detailed report...")

md = []
md.append("# 🔬 MotionHR - التقرير التفصيلي الفائق (Ultimate Screen Details)")
md.append("")
md.append(f"**التاريخ:** {datetime.now().strftime('%Y-%m-%d %H:%M')}")
md.append(f"**عدد الشاشات:** {len(all_screens)}")
md.append("**النطاق:** كل تفصيلة في كل شاشة (buttons, icons, forms, dialogs, ...)")
md.append("")
md.append("---")
md.append("")

# جدول ملخص
md.append("## 📊 جدول ملخص")
md.append("")
md.append("| # | اسم الشاشة | Buttons | Icons | Forms | Tabs | APIs | مزايا |")
md.append("|---|-----------|---------|-------|-------|------|------|-------|")

for i, (name, data) in enumerate(sorted(all_screens.items()), 1):
    btn_count = len(data['buttons']) + len(data['icon_buttons'])
    form_count = len(data['form_fields']) + len(data['dropdowns'])
    features = []
    if data['has_print']: features.append("🖨️")
    if data['has_export']: features.append("📤")
    if data['has_download']: features.append("⬇️")
    if data['has_search']: features.append("🔍")
    if data['has_filter']: features.append("🔽")
    if data['has_refresh']: features.append("🔄")
    if data['has_edit']: features.append("✏️")
    if data['has_delete']: features.append("🗑️")
    if data['has_add']: features.append("➕")
    if data['has_save']: features.append("💾")
    features_str = " ".join(features) if features else "-"
    
    md.append(f"| {i} | `{name}` | {btn_count} | {len(data['icon_buttons'])} | {form_count} | {len(data['tabs'])} | {len(data['apis'])} | {features_str} |")

md.append("")
md.append("**رموز المزايا:** 🖨️=طباعة، 📤=تصدير، ⬇️=تحميل، 🔍=بحث، 🔽=فلترة، 🔄=تحديث، ✏️=تعديل، 🗑️=حذف، ➕=إضافة، 💾=حفظ")
md.append("")
md.append("---")
md.append("")

# التفاصيل الكاملة
md.append("## 🔍 التفاصيل الكاملة لكل شاشة")
md.append("")

for i, (name, data) in enumerate(sorted(all_screens.items()), 1):
    md.append(f"### {i}. `{name}`")
    md.append("")
    md.append(f"**📁 الملف:** `{data['file']}`")
    
    if data['appbar_titles']:
        md.append(f"**🏷️ العنوان:** {' | '.join(data['appbar_titles'])}")
    
    md.append("")
    
    # المزايا الخاصة
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
        md.append(f"**✨ المزايا:** {' • '.join(features)}")
        md.append("")
    
    # التبويبات
    if data['bottom_nav']:
        md.append(f"**🧭 التبويبات السفلية ({len(data['bottom_nav'])}):**")
        for item in data['bottom_nav']:
            md.append(f"- {item}")
        md.append("")
    
    if data['tabs']:
        md.append(f"**📑 التبويبات (Tabs) ({len(data['tabs'])}):**")
        for tab in data['tabs']:
            md.append(f"- {tab}")
        md.append("")
    
    # الأزرار
    if data['buttons']:
        md.append(f"**🔘 الأزرار ({len(data['buttons'])}):**")
        for btn in data['buttons']:
            md.append(f"- {btn}")
        md.append("")
    
    # Icon buttons
    if data['icon_buttons']:
        md.append(f"**🎯 أزرار الأيقونات - AppBar ({len(data['icon_buttons'])}):**")
        for icon in data['icon_buttons']:
            md.append(f"- {icon}")
        md.append("")
    
    # كارتات الشبكة
    if data['grid_cards']:
        md.append(f"**🎴 كارتات الميزات ({len(data['grid_cards'])}):**")
        for card in data['grid_cards']:
            md.append(f"- {card}")
        md.append("")
    
    # حقول الفورم
    if data['form_fields']:
        md.append(f"**📝 حقول الإدخال ({len(data['form_fields'])}):**")
        for field in data['form_fields']:
            md.append(f"- {field}")
        md.append("")
    
    if data['dropdowns']:
        md.append(f"**🔽 القوائم المنسدلة ({len(data['dropdowns'])}):**")
        for dd in data['dropdowns']:
            md.append(f"- {dd}")
        md.append("")
    
    # ListTiles
    if data['list_tiles']:
        md.append(f"**📋 عناصر القائمة ({len(data['list_tiles'])}):**")
        for tile in data['list_tiles'][:20]:
            md.append(f"- {tile}")
        if len(data['list_tiles']) > 20:
            md.append(f"- ... و {len(data['list_tiles']) - 20} عنصر آخر")
        md.append("")
    
    # Switch tiles
    if data['switch_tiles']:
        md.append(f"**🔧 مفاتيح التبديل ({len(data['switch_tiles'])}):**")
        for sw in data['switch_tiles']:
            md.append(f"- {sw}")
        md.append("")
    
    # Popup menus
    if data['popup_menus']:
        md.append(f"**⋮ قوائم Popup ({len(data['popup_menus'])}):**")
        for pop in data['popup_menus']:
            md.append(f"- {pop}")
        md.append("")
    
    # Chips
    if data['chips']:
        md.append(f"**🏷️ Chips ({len(data['chips'])}):**")
        for chip in data['chips']:
            md.append(f"- {chip}")
        md.append("")
    
    # Dialogs
    if data['alert_dialogs']:
        md.append(f"**💬 Dialogs ({len(data['alert_dialogs'])}):**")
        for dlg in data['alert_dialogs']:
            md.append(f"- {dlg}")
        md.append("")
    
    if data['snackbars']:
        md.append(f"**📢 رسائل SnackBar ({len(data['snackbars'])}):**")
        for sb in data['snackbars'][:10]:
            md.append(f"- {sb}")
        if len(data['snackbars']) > 10:
            md.append(f"- ... و {len(data['snackbars']) - 10} رسالة أخرى")
        md.append("")
    
    # APIs
    if data['apis']:
        md.append(f"**🌐 APIs ({len(data['apis'])}):**")
        for api in data['apis']:
            md.append(f"- `{api}`")
        md.append("")
    
    # الانتقالات
    if data['navigates_to']:
        md.append(f"**➡️ ينتقل إلى ({len(data['navigates_to'])}):**")
        for nav in data['navigates_to']:
            md.append(f"- `{nav}`")
        md.append("")
    
    md.append("---")
    md.append("")

OUTPUT.write_text("\n".join(md), encoding="utf-8")

# Summary
total_buttons = sum(len(s['buttons']) for s in all_screens.values())
total_icons = sum(len(s['icon_buttons']) for s in all_screens.values())
total_forms = sum(len(s['form_fields']) for s in all_screens.values())
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

# Feature summary
print(f"\n[FEATURE SUMMARY]")
print_screens = [s['name'] for s in all_screens.values() if s['has_print']]
export_screens = [s['name'] for s in all_screens.values() if s['has_export']]
print(f"  🖨️ Screens with Print: {len(print_screens)}")
print(f"  📤 Screens with Export: {len(export_screens)}")
