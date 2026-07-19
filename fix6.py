from pathlib import Path
import re

files_lines = {
    r'C:\MotionHR\motionhr_employee\motionhr_employee\lib\main.dart': [1084, 1291, 2062],
    r'C:\MotionHR\motionhr_employee\motionhr_employee\lib\screens\employee_missions_screen.dart': [84],
    r'C:\MotionHR\motionhr_employee\motionhr_employee\lib\screens\first_launch_language_screen.dart': [57],
    r'C:\MotionHR\motionhr_employee\motionhr_employee\lib\screens\manager\mission_detail_screen.dart': [706],
}

for fpath, line_nums in files_lines.items():
    p = Path(fpath)
    lines = p.read_text(encoding='utf-8').split('\n')
    for ln in line_nums:
        idx = ln - 1
        if idx < len(lines):
            print(f"{p.name}:{ln}: {lines[idx].strip()}")