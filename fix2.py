import re

files = [
    r'C:\MotionHR\motionhr_employee\motionhr_employee\lib\screens\employee_missions_screen.dart',
    r'C:\MotionHR\motionhr_employee\motionhr_employee\lib\screens\manager\create_mission_screen.dart',
    r'C:\MotionHR\motionhr_employee\motionhr_employee\lib\screens\manager\manager_missions_screen.dart',
]

for fpath in files:
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()
    lines = content.split('\n')
    for i, line in enumerate(lines[:60]):
        if 'context.l10n' in line:
            print(f'{fpath.split(chr(92))[-1]}:{i+1}: {line.strip()}')