from pathlib import Path
import shutil
import datetime
import re

main_path = Path(r'lib\main.dart')
text = main_path.read_text(encoding='utf-8-sig')

backup_path = main_path.with_name(
    f"main.dart.bak_{datetime.datetime.now():%Y%m%d_%H%M%S}"
)
shutil.copy2(main_path, backup_path)

changed = False

import_line = "import 'screens/employee/item_detail_screen.dart';"

if import_line not in text:
    imports = list(re.finditer(r"^import .+?;\s*$", text, re.MULTILINE))
    if not imports:
        raise SystemExit("ERROR: import section not found")
    pos = imports[-1].end()
    text = text[:pos] + "\n" + import_line + text[pos:]
    print("Added import")
    changed = True
else:
    print("Import already exists")

old_line = "itemType: isLeaveTab ? 'leave' : 'request',"
new_line = "itemType: isLeaveTab ? 'leave_request' : 'request',"

if old_line in text:
    text = text.replace(old_line, new_line, 1)
    print("Fixed itemType")
    changed = True
elif new_line in text:
    print("itemType already fixed")
else:
    print("WARNING: itemType line not found")

if changed:
    main_path.write_text(text, encoding='utf-8')
    print("DONE")
else:
    print("NO CHANGES")

print("Backup:", backup_path)