"""
MotionHR - Discover GPS Company Data
=====================================
"""
import requests
import json
from pathlib import Path

BASE_URL = "https://jssolutions-eg.com"
token = Path("_token.txt").read_text(encoding="utf-8").strip()
headers = {"Authorization": f"Token {token}"}

def show(name, url):
    print(f"\n{'='*60}")
    print(f"📊 {name}")
    print(f"{'='*60}")
    try:
        r = requests.get(f"{BASE_URL}{url}", headers=headers, timeout=10)
        if r.status_code == 200:
            data = r.json()
            print(f"✅ Status: 200")
            # Save
            filename = url.replace('/', '_').strip('_') + '.json'
            Path(f"_data_{filename}").write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
            print(f"💾 Saved to: _data_{filename}")
            
            # Show summary
            if isinstance(data, dict):
                if 'results' in data:
                    print(f"   Count: {len(data['results'])}")
                    for item in data['results'][:3]:
                        print(f"   • {json.dumps(item, ensure_ascii=False)[:200]}")
                elif 'employees' in data:
                    print(f"   Count: {len(data['employees'])}")
                    for emp in data['employees'][:5]:
                        print(f"   • {emp.get('full_name', emp.get('name', 'unknown'))} ({emp.get('username', '?')})")
                elif isinstance(data.get('data'), list):
                    print(f"   Count: {len(data['data'])}")
                elif isinstance(data, list):
                    print(f"   Count: {len(data)}")
                else:
                    # Just show first level
                    for k, v in list(data.items())[:10]:
                        v_str = json.dumps(v, ensure_ascii=False)[:100] if not isinstance(v, str) else v[:100]
                        print(f"   {k}: {v_str}")
        else:
            print(f"❌ Status: {r.status_code}")
            print(f"   {r.text[:200]}")
    except Exception as e:
        print(f"❌ Error: {e}")

# Explore
show("Current Employees on GPS", "/attendance/api/mobile/manager/employees/")
show("Departments on GPS", "/attendance/api/mobile/manager/departments/list/")
show("Shifts on GPS", "/attendance/api/mobile/manager/shifts/")
show("Leave Types on GPS", "/attendance/api/mobile/leave-types/")
show("Geofence Settings", "/attendance/api/mobile/geofence/")
show("Company Info", "/attendance/api/mobile/manager/company-info/")
show("Attendance Policy", "/attendance/api/mobile/manager/attendance-policy/")
show("Leave Policy", "/attendance/api/mobile/manager/leave-policy/")
