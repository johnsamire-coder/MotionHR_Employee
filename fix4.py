from pathlib import Path

files = [
    r'C:\MotionHR\motionhr_employee\motionhr_employee\lib\screens\employee\item_detail_screen.dart',
    r'C:\MotionHR\motionhr_employee\motionhr_employee\lib\services\branding_service.dart',
]

for fp in files:
    print('\n' + '='*60)
    print(fp.split('\\')[-1])
    lines = Path(fp).read_text(encoding='utf-8').splitlines()
    for i, l in enumerate(lines, 1):
        if 'item_detail_screen' in fp and i <= 50:
            print(f'{i}: {l}')
        if 'branding_service' in fp and 145 <= i <= 180:
            print(f'{i}: {l}')