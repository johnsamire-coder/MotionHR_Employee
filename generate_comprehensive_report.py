"""
MotionHR - Comprehensive Feature Report Generator
==================================================
يعمل تقرير مفصل بكل شاشة، زر، تبويب، API، وارتباط
"""
import json
import re
from pathlib import Path
from collections import defaultdict

MOBILE_DIR = Path("lib")
OUTPUT = Path("COMPREHENSIVE_REPORT.md")

# ============================================
# قواعد التصنيف
# ============================================
ROLE_MAPPING = {
    'employee': '👤 الموظف',
    'manager': '👨‍💼 المدير / صاحب الشركة',
    'auth': '🔐 المصادقة',
    'common': '🔧 مشترك',
}

# ============================================
# استخراج معلومات الشاشة
# ============================================

# Class definition
CLASS_PATTERN = re.compile(r"class\s+(\w+(?:Screen|Page|Shell|Dashboard|Widget|View|Hub|Router))\s+extends\s+(?:Stateful|Stateless)Widget")

# AppBar title
APPBAR_TITLE_PATTERN = re.compile(r"""AppBar\s*\([^{]*?title:\s*(?:const\s+)?Text\s*\(\s*['"]([^'"]{2,120})['"]""", re.DOTALL)
APPBAR_TITLE_L10N_PATTERN = re.compile(r"""AppBar\s*\([^{]*?title:\s*(?:const\s+)?Text\s*\(\s*context\.l10n\.(\w+)""", re.DOTALL)
APPBAR_TITLE_TERNARY = re.compile(r"""AppBar\s*\([^{]*?title:\s*Text\s*\(\s*isAr\s*\?\s*['"]([^'"]+)['"]\s*:\s*['"]([^'"]+)['"]""", re.DOTALL)

# Buttons with labels
ELEVATED_BUTTON_PATTERN = re.compile(r"""ElevatedButton[^(]*\([^)]*?(?:child|label):\s*(?:const\s+)?Text\s*\(\s*['"]([^'"]{2,120})['"]""", re.DOTALL)
ICON_BUTTON_TOOLTIP = re.compile(r"""IconButton\s*\([^)]*?tooltip:\s*['"]([^'"]{2,80})['"]""", re.DOTALL)
TEXT_BUTTON_PATTERN = re.compile(r"""TextButton[^(]*\([^)]*?child:\s*(?:const\s+)?Text\s*\(\s*['"]([^'"]{2,120})['"]""", re.DOTALL)

# ListTile titles
LIST_TILE_PATTERN = re.compile(r"""ListTile\s*\([^)]*?title:\s*(?:const\s+)?Text\s*\(\s*['"]([^'"]{2,120})['"]""", re.DOTALL)

# Tab labels
TAB_PATTERN = re.compile(r"""Tab\s*\(\s*(?:text|child):\s*(?:const\s+)?(?:Text\s*\(\s*)?['"]([^'"]{2,80})['"]""")

# Grid cards
GRID_CARD_PATTERN = re.compile(r"""_gridCard\s*\(\s*(?:isAr\s*\?\s*['"]([^'"]{2,80})['"][^'"]*['"]([^'"]{2,80})['"]|context\.l10n\.(\w+)|['"]([^'"]{2,80})['"])""")

# Bottom navigation
BOTTOM_NAV_PATTERN = re.compile(r"""BottomNavigationBarItem\s*\([^)]*?label:\s*(?:context\.l10n\.(\w+)|['"]([^'"]{2,60})['"])""", re.DOTALL)

# APIs
URL_PATTERN = re.compile(r"""(/(?:attendance|leaves|employee|hr|api|accounts|companies|subscriptions|requests|notifications)/[a-zA-Z0-9_\-/${{}}.]+)""")

# Navigation
NAVIGATE_PATTERN = re.compile(r"""MaterialPageRoute\s*\(\s*builder:\s*\([^)]*\)\s*=>\s*(?:const\s+)?(\w+)""")

# ============================================
# استخراج البيانات
# ============================================

def extract_screen_data(file_path, text=None):
    if text is None:
        try:
            text = Path(file_path).read_text(encoding="utf-8", errors="ignore")
        except:
            return None
    
    # Classes
    classes = list(set(CLASS_PATTERN.findall(text)))
    
    # AppBar titles
    appbar_titles = list(set(APPBAR_TITLE_PATTERN.findall(text)))
    l10n_titles = list(set(APPBAR_TITLE_L10N_PATTERN.findall(text)))
    ternary_titles = list(set(APPBAR_TITLE_TERNARY.findall(text)))
    
    # Buttons
    buttons = list(set(ELEVATED_BUTTON_PATTERN.findall(text)))
    buttons += list(set(TEXT_BUTTON_PATTERN.findall(text)))
    tooltips = list(set(ICON_BUTTON_TOOLTIP.findall(text)))
    
    # ListTiles
    list_tiles = list(set(LIST_TILE_PATTERN.findall(text)))
    
    # Tabs
    tabs = list(set(TAB_PATTERN.findall(text)))
    
    # Grid cards
    grid_cards_raw = GRID_CARD_PATTERN.findall(text)
    grid_cards = []
    for match in grid_cards_raw:
        if isinstance(match, tuple):
            for item in match:
                if item.strip():
                    grid_cards.append(item.strip())
        elif match.strip():
            grid_cards.append(match.strip())
    grid_cards = list(set(grid_cards))
    
    # Bottom nav
    bottom_nav_raw = BOTTOM_NAV_PATTERN.findall(text)
    bottom_nav = []
    for match in bottom_nav_raw:
        for item in (match if isinstance(match, tuple) else [match]):
            if item.strip():
                bottom_nav.append(item.strip())
    bottom_nav = list(set(bottom_nav))
    
    # APIs
    apis = set()
    for match in URL_PATTERN.findall(text):
        clean = match.split('?')[0].split("'")[0].split('"')[0].split('`')[0]
        clean = re.sub(r'\$\{[^}]+\}', '{var}', clean)
        clean = re.sub(r'\$\w+', '{var}', clean)
        if len(clean) > 4 and '.dart' not in clean and not clean.endswith('${'):
            apis.add(clean.rstrip('/'))
    
    # Navigation targets
    navigates_to = list(set(NAVIGATE_PATTERN.findall(text)))
    
    return {
        'file': str(file_path).replace('\\', '/'),
        'classes': classes,
        'appbar_titles': appbar_titles,
        'appbar_l10n': l10n_titles,
        'appbar_ternary': ternary_titles,
        'buttons': buttons[:30],
        'tooltips': tooltips[:20],
        'list_tiles': list_tiles[:30],
        'tabs': tabs[:20],
        'grid_cards': grid_cards[:30],
        'bottom_nav': bottom_nav,
        'apis': sorted(apis),
        'navigates_to': navigates_to[:30],
    }

# ============================================
# تصنيف الشاشات بالدور
# ============================================

def classify_screen(file_path):
    path_str = str(file_path).lower().replace('\\', '/')
    
    if 'main.dart' in path_str:
        return 'main'
    if '/auth/' in path_str:
        return 'auth'
    if '/common/' in path_str:
        return 'common'
    if '/employee/' in path_str or 'employee' in Path(file_path).name.lower():
        return 'employee'
    if '/manager/' in path_str:
        if '/payroll/' in path_str:
            return 'manager_payroll'
        if '/shifts/' in path_str:
            return 'manager_shifts'
        if '/reports/' in path_str:
            return 'manager_reports'
        return 'manager'
    if '_screen.dart' in path_str:
        return 'root_screen'
    return 'other'

# ============================================
# بناء التقرير
# ============================================

def build_report():
    print("[SCAN] Analyzing all files...")
    
    all_screens = defaultdict(list)
    
    # main.dart
    main_file = MOBILE_DIR / "main.dart"
    if main_file.exists():
        data = extract_screen_data(main_file)
        if data:
            # main.dart فيها classes كتير - نفصلها
            for cls in data['classes']:
                cls_data = dict(data)
                cls_data['screen_name'] = cls
                if 'employee' in cls.lower() or cls in ['LeavesScreen', 'HistoryScreen', 'LeaveRequestScreen', 'CharterScreen', 'MyItemsScreen']:
                    all_screens['employee'].append(cls_data)
                elif 'manager' in cls.lower():
                    all_screens['manager'].append(cls_data)
                elif cls in ['LoginScreen', 'ChangePasswordScreen', 'SplashScreen']:
                    all_screens['auth'].append(cls_data)
                else:
                    all_screens['shared'].append(cls_data)
    
    # screens folder
    screens_root = MOBILE_DIR / "screens"
    if screens_root.exists():
        for fp in screens_root.rglob("*.dart"):
            if "_backup" in str(fp) or ".bak" in str(fp):
                continue
            data = extract_screen_data(fp)
            if data:
                data['screen_name'] = fp.stem
                role = classify_screen(fp)
                all_screens[role].append(data)
    
    print(f"[BUILD] Building report...")
    
    md = []
    md.append("# 📋 MotionHR - التقرير الشامل والمفصّل")
    md.append("")
    md.append(f"**التاريخ:** تقرير آلي محدث")
    md.append(f"**النطاق:** كل الشاشات، التبويبات، الأزرار، والـ APIs")
    md.append(f"**المصدر:** فحص كود Flutter كامل")
    md.append("")
    md.append("---")
    md.append("")
    
    # جدول محتويات
    md.append("## 📑 جدول المحتويات")
    md.append("")
    md.append("1. [👤 دور الموظف (Employee)](#-دور-الموظف-employee)")
    md.append("2. [👨‍💼 دور المدير (Manager)](#-دور-المدير-manager)")
    md.append("3. [🏢 دور صاحب الشركة / HR (Company Admin)](#-دور-صاحب-الشركة--hr-company-admin)")
    md.append("   - [الشاشات الرئيسية](#الشاشات-الرئيسية)")
    md.append("   - [شاشات الشيفتات (Shifts)](#شاشات-الشيفتات-shifts)")
    md.append("   - [شاشات الرواتب (Payroll)](#شاشات-الرواتب-payroll)")
    md.append("   - [شاشات التقارير (Reports)](#شاشات-التقارير-reports)")
    md.append("4. [🔐 المصادقة (Authentication)](#-المصادقة-authentication)")
    md.append("5. [🔧 المشتركة (Common)](#-المشتركة-common)")
    md.append("")
    md.append("---")
    md.append("")
    
    # قسم لكل دور
    sections = [
        ('employee', '👤 دور الموظف (Employee)', 'شاشات الموظف العادي في التطبيق'),
        ('manager', '👨‍💼 دور المدير (Manager)', 'شاشات المدير وصاحب الشركة'),
        ('manager_payroll', '💰 شاشات الرواتب (Payroll)', 'كل ما يخص الرواتب والسياسات المالية'),
        ('manager_shifts', '⏰ شاشات الشيفتات (Shifts)', 'إدارة الشيفتات والمناوبات'),
        ('manager_reports', '📊 شاشات التقارير (Reports)', 'كل التقارير المتاحة'),
        ('auth', '🔐 المصادقة (Authentication)', 'شاشات تسجيل الدخول وإدارة الحساب'),
        ('common', '🔧 المشتركة (Common)', 'أدوات مشتركة بين الأدوار'),
        ('shared', '🌐 شاشات مشتركة', 'شاشات تستخدمها كل الأدوار'),
    ]
    
    for role_key, role_title, role_desc in sections:
        screens = all_screens.get(role_key, [])
        if not screens:
            continue
        
        md.append(f"## {role_title}")
        md.append("")
        md.append(f"> {role_desc}")
        md.append(f"> **عدد الشاشات:** {len(screens)}")
        md.append("")
        
        # ترتيب الشاشات
        screens_sorted = sorted(screens, key=lambda x: x.get('screen_name', ''))
        
        for i, screen in enumerate(screens_sorted, 1):
            name = screen.get('screen_name', 'Unknown')
            
            md.append(f"### {i}. `{name}`")
            md.append("")
            md.append(f"**📁 الملف:** `{screen['file']}`")
            md.append("")
            
            # AppBar titles
            titles = []
            if screen.get('appbar_titles'):
                titles.extend(screen['appbar_titles'])
            if screen.get('appbar_ternary'):
                titles.extend([f"{ar} / {en}" for ar, en in screen['appbar_ternary']])
            if screen.get('appbar_l10n'):
                titles.extend([f"l10n.{key}" for key in screen['appbar_l10n']])
            
            if titles:
                md.append("**🏷️ العنوان في الشاشة:**")
                for t in titles[:5]:
                    md.append(f"- `{t}`")
                md.append("")
            
            # Bottom Navigation
            if screen.get('bottom_nav'):
                md.append("**🧭 تبويبات الشاشة (Bottom Navigation):**")
                for tab in screen['bottom_nav']:
                    md.append(f"- {tab}")
                md.append("")
            
            # Tabs (TabBar)
            if screen.get('tabs'):
                md.append("**📑 التبويبات (Tabs):**")
                for tab in screen['tabs']:
                    md.append(f"- {tab}")
                md.append("")
            
            # Grid Cards
            if screen.get('grid_cards'):
                md.append("**🎴 الكارتات / الأزرار الرئيسية:**")
                for card in screen['grid_cards']:
                    md.append(f"- {card}")
                md.append("")
            
            # Buttons
            if screen.get('buttons'):
                md.append("**🔘 الأزرار (Buttons):**")
                for btn in screen['buttons']:
                    md.append(f"- {btn}")
                md.append("")
            
            # Tooltips
            if screen.get('tooltips'):
                md.append("**💡 أيقونات في الـ AppBar:**")
                for tip in screen['tooltips']:
                    md.append(f"- {tip}")
                md.append("")
            
            # List Tiles
            if screen.get('list_tiles'):
                md.append("**📋 عناصر القائمة (List Items):**")
                for tile in screen['list_tiles']:
                    md.append(f"- {tile}")
                md.append("")
            
            # APIs
            if screen.get('apis'):
                md.append("**🌐 الـ APIs المرتبطة:**")
                for api in screen['apis']:
                    md.append(f"- `{api}`")
                md.append("")
            
            # Navigates to
            if screen.get('navigates_to'):
                md.append("**➡️ تنتقل إلى الشاشات:**")
                for nav in screen['navigates_to']:
                    md.append(f"- `{nav}`")
                md.append("")
            
            md.append("---")
            md.append("")
    
    OUTPUT.write_text("\n".join(md), encoding="utf-8")
    
    # Summary
    total_screens = sum(len(s) for s in all_screens.values())
    print(f"\n[OK] Report generated!")
    print(f"[OK] File: {OUTPUT.absolute()}")
    print(f"[OK] Total screens documented: {total_screens}")
    print(f"[OK] File size: {OUTPUT.stat().st_size / 1024:.1f} KB")
    
    print("\n[SUMMARY]")
    for role_key, role_title, _ in sections:
        count = len(all_screens.get(role_key, []))
        if count > 0:
            print(f"  {role_title}: {count}")

if __name__ == "__main__":
    build_report()
