import re

with open(r'lib\main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# ابحث عن MyItemsScreen
idx = content.find('class MyItemsScreen')
if idx == -1:
    print("NOT FOUND: MyItemsScreen")
else:
    print("FOUND at index:", idx)
    print("---SNIPPET---")
    print(content[idx:idx+3000])
    print("---END---")