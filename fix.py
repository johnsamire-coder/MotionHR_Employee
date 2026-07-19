import os
import shutil

BASE = r"C:\MotionHR\motionhr_employee\motionhr_employee\lib"

# ملفات الـ backup اللي لازم نحذفها أو نخليها مش dart
BACKUP_FILES = [
    'main_backup.dart',
    'main_backup_before_batches.dart', 
    'main_before_permissions_patch.dart',
]

# الـ import اللي لازم يكون في كل ملف فيه context.l10n
L10N_IMPORT = "import 'package:motionhr_employee/l10n/l10n.dart';\n"

SKIP_FILES = [
    'app_localizations.dart', 'app_localizations_ar.dart',
    'app_localizations_en.dart', 'l10n.dart', 'app_strings.dart',
    'language_service.dart', 'branding_service.dart',
]

SKIP_EXTENSIONS = ['.bak', '.backup', '.phase9', '.bak_push_foreground',
                   '.bak_before_reports_button', '.bak_translate_']

def should_skip(filepath):
    filename = os.path.basename(filepath)
    for ext in SKIP_EXTENSIONS:
        if ext in filepath:
            return True
    for skip in SKIP_FILES:
        if filename == skip:
            return True
    return False

def get_dart_files(base):
    dart_files = []
    for root, dirs, files in os.walk(base):
        for f in files:
            if f.endswith('.dart'):
                full = os.path.join(root, f)
                if not should_skip(full):
                    dart_files.append(full)
    return dart_files

def fix_backup_files():
    print("\n🗑 حذف ملفات الـ backup القديمة...")
    for fname in BACKUP_FILES:
        fpath = os.path.join(BASE, fname)
        if os.path.exists(fpath):
            renamed = fpath.replace('.dart', '.dart.old')
            os.rename(fpath, renamed)
            print(f"  ✅ تمت إعادة تسمية: {fname} → {fname}.old")

def fix_imports(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # لو مفيش context.l10n في الملف، متعملش حاجة
    if 'context.l10n' not in content:
        return False
    
    # لو الـ import موجود بالفعل، متعملش حاجة
    if "l10n/l10n.dart" in content or "l10n/generated/app_localizations.dart" in content:
        return False
    
    # أضف الـ import بعد أول import في الملف
    lines = content.split('\n')
    insert_pos = 0
    for i, line in enumerate(lines):
        if line.startswith('import '):
            insert_pos = i + 1
    
    lines.insert(insert_pos, L10N_IMPORT.strip())
    new_content = '\n'.join(lines)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    return True

def fix_const_issues(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if 'context.l10n' not in content:
        return False
    
    original = content
    
    # إصلاح const Text( → Text(
    import re
    # const Text(context.l10n → Text(context.l10n
    content = re.sub(r'\bconst\s+(Text\(context\.l10n)', r'\1', content)
    # const SizedBox مش هنلمسها
    # إصلاح const Icon بها context.l10n
    content = re.sub(r'\bconst\s+(Icon\(context\.l10n)', r'\1', content)
    # إصلاح const Tab بها context.l10n  
    content = re.sub(r'\bconst\s+(Tab\()', r'\1', content)
    # إصلاح BottomNavigationBarItem const
    content = re.sub(r'\bconst\s+(BottomNavigationBarItem\()', r'\1', content)
    # إصلاح قوائم const فيها context.l10n
    # [const Tab(...context.l10n...), ...] → remove const from the list
    content = re.sub(r'const\s+\[([^\]]*context\.l10n[^\]]*)\]', r'[\1]', content, flags=re.DOTALL)
    
    if content == original:
        return False
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    return True

def fix_initializer_issues(filepath):
    """إصلاح مشكلة context.l10n في initializers"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if 'context.l10n' not in content:
        return False
    
    original = content
    import re
    
    # إصلاح: final x = context.l10n.something → late final x;
    # نغير الـ tabs كـ strings ثابتة بدل l10n
    # مثال: final List<String> _tabs = [context.l10n.today, ...]
    # الحل: نحول لـ getter داخل build
    
    # إصلاح محدد لـ _tabs و _filters في initializers
    # نبحث عن patterns مثل:
    # final _something = context.l10n.xxx;
    content = re.sub(
        r'(final\s+\w+\s*=\s*)context\.l10n\.(\w+)([,;])',
        r'\1AppLocalizations.of(context)!.\2\3',
        content
    )
    
    if content == original:
        return False
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    return True

def main():
    print("=" * 60)
    print("🔧 MotionHR — سكريبت إصلاح الأخطاء")
    print("=" * 60)
    
    # خطوة 1: حذف ملفات backup
    fix_backup_files()
    
    # خطوة 2: إضافة imports
    print("\n📦 إضافة imports مفقودة...")
    dart_files = get_dart_files(BASE)
    import_count = 0
    for f in dart_files:
        if fix_imports(f):
            print(f"  ✅ import أضيف: {os.path.relpath(f, BASE)}")
            import_count += 1
    
    # خطوة 3: إصلاح const
    print(f"\n🔧 إصلاح const issues...")
    const_count = 0
    for f in dart_files:
        if fix_const_issues(f):
            print(f"  ✅ const أصلح: {os.path.relpath(f, BASE)}")
            const_count += 1
    
    print("\n" + "=" * 60)
    print(f"✅ انتهى!")
    print(f"  - Backup files renamed: {len(BACKUP_FILES)}")
    print(f"  - Imports added: {import_count}")
    print(f"  - Const fixes: {const_count}")
    print("=" * 60)

if __name__ == '__main__':
    main()