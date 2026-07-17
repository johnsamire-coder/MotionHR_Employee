from pathlib import Path

p = Path(r'lib\screens\employee\item_detail_screen.dart')
t = p.read_text(encoding='utf-8')

idx = t.find('AttachmentsWidget')
if idx == -1:
    print("NOT FOUND")
else:
    print("=== AttachmentsWidget usage ===")
    print(t[idx:idx+300])