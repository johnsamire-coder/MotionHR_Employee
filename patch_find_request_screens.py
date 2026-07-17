with open(r'lib\main.dart', 'r', encoding='utf-8-sig') as f:
    content = f.read()

for name in ['class LeaveRequestScreen', 'class RequestsScreen']:
    idx = content.find(name)
    print('=' * 80)
    print(name)
    print('=' * 80)
    if idx == -1:
        print('NOT FOUND')
    else:
        print(content[idx:idx+5000])
        print('\n')