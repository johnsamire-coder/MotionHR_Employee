import os 
 
path = r'lib\screens\manager\reminders' 
os.makedirs(path, exist_ok=True) 
print('Created:', path) 
 
content = open('lib/main.dart', encoding='utf-8').read() 
print('main.dart size:', len(content), 'chars') 
print('OK') 
