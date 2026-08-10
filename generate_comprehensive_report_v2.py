"""
MotionHR - Comprehensive Feature Report Generator v2
=====================================================
النسخة المحسّنة: كل class ياخد المحتوى الخاص بيه فقط
"""
import json
import re
from pathlib import Path
from collections import defaultdict

MOBILE_DIR = Path("lib")
OUTPUT = Path("COMPREHENSIVE_REPORT.md")

# ============================================
# Patterns
# ============================================
CLASS_START_PATTERN = re.compile(
    r"class\s+(\w+(?:Screen|Page|Shell|Dashboard|Widget|View|Hub|Router))\s+extends\s+(?:Stateful|Stateless)Widget"
)

# For extracting details WITHIN a class body
APPBAR_TITLE_PATTERN = re.compile(r"""AppBar\s*\([^{]*?title:\s*(?:const\s+)?Text\s*\(\s*['"]([^'"]{2,120})['"]""", re.DOTALL)
APPBAR_TITLE_TERNARY = re.compile(r"""AppBar\s*\([^{]*?title:\s*Text\s*\(\s*isAr\s*\?\s*['"]([^'"]+)['"]\s*:\s*['"]([^'"]+)['"]""", re.DOTALL)
APPBAR_TITLE_L10N = re.compile(r"""AppBar\s*\([^{]*?title:\s*(?:const\s+)?Text\s*\(\s*context\.l10n\.(\w+)""", re.DOTALL)

ELEVATED_BUTTON_PATTERN = re.compile(r"""ElevatedButton[^(]*\([^)]*?(?:child|label):\s*(?:const\s+)?Text\s*\(\s*['"]([^'"]{2,120})['"]""", re.DOTALL)
TEXT_BUTTON_PATTERN = re.compile(r"""TextButton[^(]*\([^)]*?child:\s*(?:const\s+)?Text\s*\(\s*['"]([^'"]{2,120})['"]""", re.DOTALL)
ICON_BUTTON_TOOLTIP = re.compile(r"""IconButton\s*\([^)]*?tooltip:\s*['"]([^'"]{2,80})['"]""", re.DOTALL)

LIST_TILE_PATTERN = re.compile(r"""ListTile\s*\([^)]*?title:\s*(?:const\s+)?Text\s*\(\s*['"]([^'"]{2,120})['"]""", re.DOTALL)

TAB_PATTERN = re.compile(r"""Tab\s*\(\s*text:\s*['"]([^'"]{2,80})['"]""")

BOTTOM_NAV_LABEL_L10N = re.compile(r"""BottomNavigationBarItem\s*\([^)]*?label:\s*context\.l10n\.(\w+)""", re.DOTALL)
BOTTOM_NAV_LABEL_STR = re.compile(r"""BottomNavigationBarItem\s*\([^)]*?label:\s*['"]([^'"]{2,60})['"]""", re.DOTALL)
BOTTOM_NAV_LABEL_TERNARY = re.compile(r"""BottomNavigationBarItem\s*\([^)]*?label:\s*isAr\s*\?\s*['"]([^'"]+)['"]\s*:\s*['"]([^'"]+)['"]""", re.DOTALL)

GRID_CARD_PATTERN = re.compile(r"""_gridCard\s*\(\s*(?:isAr\s*\?\s*['"]([^'"]{2,80})['"][^,)]*?['"]([^'"]{2,80})['"]|context\.l10n\.(\w+)|['"]([^'"]{2,80})['"])""")

URL_PATTERN = re.compile(r"""(/(?:attendance|leaves|employee|hr|api|accounts|companies|subscriptions|requests|notifications)/[a-zA-Z0-9_\-/${{}}.]+)""")

NAVIGATE_PATTERN = re.compile(r"""MaterialPageRoute\s*\(\s*builder:\s*\([^)]*\)\s*=>\s*(?:const\s+)?(\w+)""")

# ============================================
# تقسيم main.dart لأجزاء (كل class لوحده)
# ============================================
def split_main_dart_by_class(text):
    """يقسّم main.dart لأجزاء حسب كل class"""
    # لاقي كل الـ classes مع مواقعها
    positions = []
    for m in CLASS_START_PATTERN.finditer(text):
        positions.append((m.start(), m.group(1)))
    
    positions.sort()
    parts = {}
    
    for i, (start, name) in enumerate(positions):
        end = positions[i + 1][0] if i + 1 < len(positions) else len(text)
        parts[name] = text[start:end]
    
    return parts

# ============================================
# استخراج المعلومات من كود (class أو ملف)
# ============================================
def extract_details(text, class_name=None):
    # AppBar titles
    titles = []
    titles.extend(APPBAR_TITLE_PATTERN.findall(text))
    for ar, en in APPBAR_TITLE_TERNARY.findall(text):
        titles.append(f"{ar} / {en}")
    for key in APPBAR_TITLE_L10N.findall(text):
        titles.append(f"l10n.{key}")
    
    # Buttons
    buttons = list(set(ELEVATED_BUTTON_PATTERN.findall(text)))
    buttons += list(set(TEXT_BUTTON_PATTERN.findall(text)))
    tooltips = list(set(ICON_BUTTON_TOOLTIP.findall(text)))
    
    # ListTiles
    list_tiles = list(set(LIST_TILE_PATTERN.findall(text)))
    
    # Tabs
    tabs = list(set(TAB_PATTERN.findall(text)))
    
    # Grid Cards
    grid_cards = set()
    for match in GRID_CARD_PATTERN.findall(text):
        for item in match:
            if item and item.strip():
                grid_cards.add(item.strip())
    
    # Bottom Nav
    bottom_nav = []
    for key in BOTTOM_NAV_LABEL_L10N.findall(text):
        bottom_nav.append(f"l10n.{key}")
    bottom_nav.extend(BOTTOM_NAV_LABEL_STR.findall(text))
    for ar, en in BOTTOM_NAV_LABEL_TERNARY.findall(text):
        bottom_nav.append(f"{ar} / {en}")
    bottom_nav = list(set(bottom_nav))
    
    # APIs
    apis = set()
    for match in URL_PATTERN.findall(text):
        clean = match.split('?')[0].split("'")[0].split('"')[0].split('`')[0]
        clean = re.sub(r'\$\{[^}]+\}', '{var}', clean)
        clean = re.sub(r'\$\w+', '{var}', clean)
        if len(clean) > 4 and '.dart' not in clean and not clean.endswith('${'):
            apis.add(clean.rstrip('/'))
    
    # Navigation
    navigates = list(set(NAVIGATE_PATTERN.findall(text)))
    
    return {
        'titles': list(set(titles))[:5],
        'buttons': buttons[:20],
        'tooltips': tooltips[:15],
        'list_tiles': list_tiles[:20],
        'tabs': tabs[:15],
        'grid_cards': sorted(grid_cards)[:30],
        'bottom_nav': bottom_nav[:8],
        'apis': sorted(apis)[:30],
        'navigates': navigates[:20],
    }

# ============================================
# تصنيف class بناءً على اسمه
# ============================================
def classify_class(name):
    n = name.lower()
    if 'employee' in n and 'manager' not in n:
        return 'employee'
    if any(k in n for k in ['login', 'splash', 'changepassword', 'activate']):
        return 'auth'
    if any(k in n for k in ['leaves', 'leave', 'charter', 'history', 'myitems', 'notifications']):
        return 'employee'
    if 'manager' in n:
        return 'manager'
    return 'shared'

# ============================================
# تصنيف ملف الشاشة
# ============================================
def classify_file(fp):
    path = str(fp).lower().replace('\\', '/')
    if '/auth/' in path:
        return 'auth'
    if '/common/' in path:
        return 'common'
    if '/employee/' in path or fp.parent.name == 'screens' and 'employee' in fp.stem.lower():
        return 'employee'
    if '/manager/payroll/' in path:
        return 'payroll'
    if '/manager/shifts/' in path:
        return 'shifts'
    if '/manager/reports/' in path:
        return 'reports'
    if '/manager/' in path:
        return 'manager'
    if fp.stem == 'settings_screen':
        return 'shared'
    return 'shared'

# ============================================
# البناء
# ============================================
def build():
    print("[SCAN] Reading main.dart...")
    main_file = MOBILE_DIR / "main.dart"
    main_text = main_file.read_text(encoding="utf-8", errors="ignore") if main_file.exists() else ""
    
    print("[SPLIT] Splitting main.dart by class...")
    main_parts = split_main_dart_by_class(main_text)
    print(f"       Found {len(main_parts)} classes in main.dart")
    
    # جمع البيانات
    all_screens = defaultdict(list)
    
    # من main.dart
    for cls_name, cls_text in main_parts.items():
        details = extract_details(cls_text, cls_name)
        details['name'] = cls_name
        details['file'] = 'lib/main.dart'
        details['source'] = 'main.dart'
        role = classify_class(cls_name)
        all_screens[role].append(details)
    
    # من screens folder
    print("[SCAN] Reading screens folder...")
    screens_root = MOBILE_DIR / "screens"
    if screens_root.exists():
        for fp in screens_root.rglob("*.dart"):
            if "_backup" in str(fp) or ".bak" in str(fp):
                continue
            try:
                text = fp.read_text(encoding="utf-8", errors="ignore")
                details = extract_details(text)
                
                # امسك اسم الـ class الأساسي في الملف
                classes = CLASS_START_PATTERN.findall(text)
                details['name'] = classes[0] if classes else fp.stem
                details['file'] = str(fp).replace('\\', '/')
                details['source'] = 'screen_file'
                role = classify_file(fp)
                all_screens[role].append(details)
            except Exception as e:
                print(f"  [WARN] Failed: {fp} - {e}")
    
    # بناء التقرير
    print("[BUILD] Building report...")
    md = []
    md.append("# 📋 MotionHR - التقرير الشامل والمفصّل (v2)")
    md.append("")
    md.append("**النطاق:** كل الشاشات، التبويبات، الأزرار، الـ APIs، والانتقالات")
    md.append("**المصدر:** فحص Flutter code — كل class بمحتواه الخاص")
    md.append("")
    md.append("---")
    md.append("")
    
    # Summary
    md.append("## 📊 الملخص التنفيذي")
    md.append("")
    md.append("| القسم | العدد |")
    md.append("|-------|-------|")
    sections_order = [
        ('employee', '👤 شاشات الموظف'),
        ('manager', '👨‍💼 شاشات المدير/صاحب الشركة'),
        ('payroll', '💰 شاشات الرواتب'),
        ('shifts', '⏰ شاشات الشيفتات'),
        ('reports', '📊 شاشات التقارير'),
        ('auth', '🔐 شاشات المصادقة'),
        ('common', '🔧 المشتركة'),
        ('shared', '🌐 المشتركة العامة'),
    ]
    total = 0
    for key, title in sections_order:
        count = len(all_screens.get(key, []))
        if count > 0:
            md.append(f"| {title} | {count} |")
            total += count
    md.append(f"| **الإجمالي** | **{total}** |")
    md.append("")
    md.append("---")
    md.append("")
    
    # كل قسم
    for role_key, section_title in sections_order:
        screens = all_screens.get(role_key, [])
        if not screens:
            continue
        
        md.append(f"## {section_title}")
        md.append(f"### عدد الشاشات: {len(screens)}")
        md.append("")
        
        screens_sorted = sorted(screens, key=lambda x: x.get('name', ''))
        
        for i, screen in enumerate(screens_sorted, 1):
            name = screen.get('name', 'Unknown')
            file = screen.get('file', '')
            
            md.append(f"### {i}. `{name}`")
            md.append("")
            md.append(f"**📁 الملف:** `{file}`")
            
            if screen.get('titles'):
                md.append("")
                md.append("**🏷️ عنوان الشاشة:**")
                for t in screen['titles']:
                    md.append(f"- {t}")
            
            if screen.get('bottom_nav'):
                md.append("")
                md.append("**🧭 التبويبات السفلية:**")
                for tab in screen['bottom_nav']:
                    md.append(f"- {tab}")
            
            if screen.get('tabs'):
                md.append("")
                md.append("**📑 التبويبات (Tabs):**")
                for tab in screen['tabs']:
                    md.append(f"- {tab}")
            
            if screen.get('grid_cards'):
                md.append("")
                md.append("**🎴 الكارتات الرئيسية (Grid Cards):**")
                for card in screen['grid_cards']:
                    md.append(f"- {card}")
            
            if screen.get('list_tiles'):
                md.append("")
                md.append("**📋 عناصر القائمة (List Tiles):**")
                for tile in screen['list_tiles']:
                    md.append(f"- {tile}")
            
            if screen.get('buttons'):
                md.append("")
                md.append("**🔘 الأزرار:**")
                for btn in screen['buttons']:
                    md.append(f"- {btn}")
            
            if screen.get('tooltips'):
                md.append("")
                md.append("**💡 أيقونات AppBar:**")
                for tip in screen['tooltips']:
                    md.append(f"- {tip}")
            
            if screen.get('apis'):
                md.append("")
                md.append("**🌐 الـ APIs المستخدمة:**")
                for api in screen['apis']:
                    md.append(f"- `{api}`")
            
            if screen.get('navigates'):
                md.append("")
                md.append("**➡️ تنتقل إلى:**")
                for nav in screen['navigates']:
                    md.append(f"- `{nav}`")
            
            md.append("")
            md.append("---")
            md.append("")
    
    OUTPUT.write_text("\n".join(md), encoding="utf-8")
    
    print(f"\n[OK] Report: {OUTPUT.absolute()}")
    print(f"[OK] Size: {OUTPUT.stat().st_size / 1024:.1f} KB")
    print(f"[OK] Total: {total} screens")
    print("\n[BREAKDOWN]")
    for key, title in sections_order:
        count = len(all_screens.get(key, []))
        if count > 0:
            print(f"  {title}: {count}")

if __name__ == "__main__":
    build()
