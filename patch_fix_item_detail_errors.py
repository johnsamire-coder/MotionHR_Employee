from pathlib import Path
import shutil
import datetime

def backup(path_str):
    p = Path(path_str)
    b = p.with_name(f"{p.name}.bak_{datetime.datetime.now():%Y%m%d_%H%M%S}")
    shutil.copy2(p, b)
    print("Backup:", b)
    return p

# 1) main.dart
main_path = backup(r'lib\main.dart')
main_text = main_path.read_text(encoding='utf-8-sig')

old_import = "import 'screens/item_detail_screen.dart';\n"
if old_import in main_text:
    main_text = main_text.replace(old_import, '', 1)
    print("Removed old import from main.dart")
else:
    print("Old import not found in main.dart")

main_path.write_text(main_text, encoding='utf-8')

# 2) item_detail_screen.dart
item_path = backup(r'lib\screens\employee\item_detail_screen.dart')
item_text = item_path.read_text(encoding='utf-8')

old_block = """                AttachmentsWidget(
                  modelType: itemType,
                  objectId: id,
                  canUpload: status == 'pending',
                  canDelete: status == 'pending',
                ),"""

new_block = """                AttachmentsWidget(
                  model: itemType,
                  objectId: id,
                  canEdit: status == 'pending',
                ),"""

if old_block in item_text:
    item_text = item_text.replace(old_block, new_block, 1)
    print("Fixed AttachmentsWidget params")
else:
    print("AttachmentsWidget block not found exactly")

item_path.write_text(item_text, encoding='utf-8')

print("DONE")