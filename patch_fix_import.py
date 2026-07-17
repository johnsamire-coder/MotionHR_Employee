from pathlib import Path
import shutil, datetime

main = Path(r'lib\main.dart')
text = main.read_text(encoding='utf-8-sig')

# اطبع كل imports اللي فيها item_detail
lines = [(i+1, l) for i, l in enumerate(text.splitlines()) if 'item_detail' in l]
print("=== item_detail imports ===")
for num, line in lines:
    print(f"  Line {num}: {line.strip()}")