"""
MotionHR - Server Explorer
==========================
يفحص السيرفر ويكتشف الـ APIs المتاحة
"""
import requests
import json
from pathlib import Path

BASE_URL = "https://jssolutions-eg.com"
USERNAME = "john"
PASSWORD = "12345678"

print("="*60)
print("STEP 1: Login as john")
print("="*60)

try:
    login_response = requests.post(
        f"{BASE_URL}/attendance/api/mobile/login/",
        json={"username": USERNAME, "password": PASSWORD},
        timeout=15
    )
    
    print(f"Status: {login_response.status_code}")
    print(f"Response: {login_response.text[:500]}")
    
    if login_response.status_code == 200:
        data = login_response.json()
        token = data.get('token') or data.get('access') or data.get('key')
        role = data.get('role') or data.get('user', {}).get('role', 'unknown')
        company = data.get('company_name') or data.get('company', {}).get('name', 'unknown')
        
        print(f"\n✅ Login Success!")
        print(f"   Token: {token[:30]}..." if token else "   Token: NOT FOUND")
        print(f"   Role: {role}")
        print(f"   Company: {company}")
        
        # Save token for next steps
        Path("_token.txt").write_text(token or "", encoding="utf-8")
        Path("_login_response.json").write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        
        # Test some key APIs
        print("\n" + "="*60)
        print("STEP 2: Test Key Endpoints")
        print("="*60)
        
        headers = {"Authorization": f"Token {token}"} if token else {}
        
        test_endpoints = [
            ("GET", "/attendance/api/mobile/manager/employees/", "List Employees"),
            ("GET", "/attendance/api/mobile/manager/departments/list/", "List Departments"),
            ("GET", "/attendance/api/mobile/branches/", "List Branches"),
            ("GET", "/attendance/api/mobile/job-titles/", "List Job Titles"),
            ("GET", "/attendance/api/mobile/manager/shifts/", "List Shifts"),
            ("GET", "/attendance/api/mobile/leave-types/", "List Leave Types"),
            ("GET", "/attendance/api/mobile/geofence/", "Get Geofence"),
        ]
        
        for method, endpoint, name in test_endpoints:
            try:
                r = requests.request(method, f"{BASE_URL}{endpoint}", headers=headers, timeout=10)
                status = "✅" if r.status_code == 200 else "⚠️"
                print(f"{status} {name}: {r.status_code}")
                if r.status_code == 200:
                    try:
                        data = r.json()
                        if isinstance(data, dict):
                            count = len(data.get('results', data.get('data', data.get('items', [1]))))
                            print(f"   Items: {count}")
                    except:
                        pass
            except Exception as e:
                print(f"❌ {name}: ERROR - {e}")
        
    else:
        print(f"❌ Login failed!")
        try:
            print(f"Error: {login_response.json()}")
        except:
            pass

except Exception as e:
    print(f"❌ Connection Error: {e}")
    print(f"\nMake sure server is up: {BASE_URL}")
