from pathlib import Path
import re

# ═══════════════════════════════════════
# 1) إضافة import لـ main.dart
# ═══════════════════════════════════════
main_path = Path(r'C:\MotionHR\motionhr_employee\motionhr_employee\lib\main.dart')
content = main_path.read_text(encoding='utf-8')

L10N_IMPORT = "import 'package:motionhr_employee/l10n/l10n.dart';"

if L10N_IMPORT not in content:
    # أضفه بعد أول import
    lines = content.split('\n')
    for i, line in enumerate(lines):
        if line.startswith('import '):
            lines.insert(i + 1, L10N_IMPORT)
            break
    content = '\n'.join(lines)
    main_path.write_text(content, encoding='utf-8')
    print("✅ import أضيف لـ main.dart")
else:
    print("⏭ import موجود بالفعل في main.dart")

# ═══════════════════════════════════════
# 2) إصلاح const مع context.l10n في كل الملفات
# ═══════════════════════════════════════
BASE = Path(r'C:\MotionHR\motionhr_employee\motionhr_employee\lib')

SKIP = ['app_localizations.dart', 'app_localizations_ar.dart',
        'app_localizations_en.dart', 'l10n.dart', 'app_strings.dart']

def get_files():
    files = []
    for f in BASE.rglob('*.dart'):
        if any(s in str(f) for s in ['.bak', '.backup', '.old', '.phase9']):
            continue
        if f.name in SKIP:
            continue
        files.append(f)
    return files

fixed = 0
for fpath in get_files():
    c = fpath.read_text(encoding='utf-8')
    if 'context.l10n' not in c:
        continue
    original = c
    
    # إزالة const قبل أي widget يحتوي على context.l10n
    # Pattern: const SomeWidget(...context.l10n...) 
    c = re.sub(r'\bconst\s+(Text\(context\.l10n)', r'\1', c)
    c = re.sub(r'\bconst\s+(Tab\(\s*(?:text|child)\s*:\s*(?:Text\()?context\.l10n)', r'\1', c)
    c = re.sub(r'\bconst\s+(BottomNavigationBarItem\()', r'\1', c)
    c = re.sub(r'\bconst\s+(NavigationDestination\()', r'\1', c)
    c = re.sub(r'\bconst\s+(ListTile\()', r'\1', c)
    c = re.sub(r'\bconst\s+(ElevatedButton\()', r'\1', c)
    c = re.sub(r'\bconst\s+(TextButton\()', r'\1', c)
    c = re.sub(r'\bconst\s+(OutlinedButton\()', r'\1', c)
    c = re.sub(r'\bconst\s+(IconButton\()', r'\1', c)
    c = re.sub(r'\bconst\s+(Chip\()', r'\1', c)
    c = re.sub(r'\bconst\s+(AppBar\()', r'\1', c)
    c = re.sub(r'\bconst\s+(Scaffold\()', r'\1', c)
    c = re.sub(r'\bconst\s+(Card\()', r'\1', c)
    c = re.sub(r'\bconst\s+(Container\()', r'\1', c)
    c = re.sub(r'\bconst\s+(Row\()', r'\1', c)
    c = re.sub(r'\bconst\s+(Column\()', r'\1', c)
    c = re.sub(r'\bconst\s+(Padding\()', r'\1', c)
    c = re.sub(r'\bconst\s+(Center\()', r'\1', c)
    c = re.sub(r'\bconst\s+(Expanded\()', r'\1', c)
    c = re.sub(r'\bconst\s+(SizedBox\()', r'\1', c)
    c = re.sub(r'\bconst\s+(Icon\()', r'\1', c)
    c = re.sub(r'\bconst\s+(Divider\()', r'\1', c)
    c = re.sub(r'\bconst\s+(InputDecoration\()', r'\1', c)
    c = re.sub(r'\bconst\s+(TextFormField\()', r'\1', c)
    c = re.sub(r'\bconst\s+(DropdownButton\()', r'\1', c)
    c = re.sub(r'\bconst\s+(PopupMenuItem\()', r'\1', c)
    c = re.sub(r'\bconst\s+(AlertDialog\()', r'\1', c)
    c = re.sub(r'\bconst\s+(SnackBar\()', r'\1', c)
    c = re.sub(r'\bconst\s+(FloatingActionButton\()', r'\1', c)
    
    # إزالة const من lists تحتوي على context.l10n
    # const [... context.l10n ...] → [... context.l10n ...]
    def remove_const_from_list(match):
        inner = match.group(1)
        if 'context.l10n' in inner:
            return '[' + inner + ']'
        return 'const [' + inner + ']'
    
    c = re.sub(r'const\s+\[([^\[\]]*)\]', remove_const_from_list, c)
    
    if c != original:
        fpath.write_text(c, encoding='utf-8')
        print(f"✅ إصلاح const: {fpath.name}")
        fixed += 1

print(f"\n✅ انتهى! {fixed} ملف اتصلح")