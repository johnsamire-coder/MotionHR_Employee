"""
MotionHR - Test Creation APIs
==============================
نفحص APIs الإنشاء عشان نعرف الصيغة الصحيحة
"""
import requests
import json
from pathlib import Path

BASE_URL = "https://jssolutions-eg.com"
token = Path("_token.txt").read_text(encoding="utf-8").strip()
headers = {"Authorization": f"Token {token}", "Content-Type": "application/json"}

print("="*60)
print("TEST 1: Get one existing employee (to see structure)")
print("="*60)

# Get list to find ID
r = requests.get(f"{BASE_URL}/attendance/api/mobile/manager/employees/", headers=headers)
if r.status_code == 200:
    data = r.json()
    employees = data.get('employees', data.get('results', []))
    if employees:
        first_emp = employees[0]
        print(f"First employee structure:")
        print(json.dumps(first_emp, ensure_ascii=False, indent=2))
        
        emp_id = first_emp.get('id')
        if emp_id:
            print(f"\n{'='*60}")
            print(f"TEST 2: Get full details for employee {emp_id}")
            print(f"{'='*60}")
            r2 = requests.get(f"{BASE_URL}/attendance/api/mobile/manager/employees/{emp_id}/", headers=headers)
            if r2.status_code == 200:
                emp_details = r2.json()
                print(json.dumps(emp_details, ensure_ascii=False, indent=2)[:2000])
                Path("_sample_employee.json").write_text(json.dumps(emp_details, ensure_ascii=False, indent=2), encoding="utf-8")

print(f"\n{'='*60}")
print("TEST 3: Try creating a test employee")
print("="*60)

test_employee = {
    "first_name": "Test",
    "last_name": "Employee",
    "full_name": "Test Employee Simulation",
    "name": "Test Employee Simulation",
    "email": "test_sim_001@gps.com",
    "phone": "01000000001",
    "national_id": "12345678901234",
    "gender": "male",
    "job_title": "Software Developer",
    "department_id": 118,  # الحسابات
    "hiring_date": "2026-01-01",
    "salary": 5000,
    "basic_salary": 5000,
}

r = requests.post(
    f"{BASE_URL}/attendance/api/mobile/manager/employees/create/",
    headers=headers,
    json=test_employee
)
print(f"Status: {r.status_code}")
print(f"Response: {r.text[:1000]}")

print(f"\n{'='*60}")
print("TEST 4: Get shift structure")
print("="*60)
r = requests.get(f"{BASE_URL}/attendance/api/mobile/manager/shifts/", headers=headers)
if r.status_code == 200:
    data = r.json()
    shifts = data.get('shifts', [])
    if shifts:
        print(f"First shift:")
        print(json.dumps(shifts[0], ensure_ascii=False, indent=2))

print(f"\n{'='*60}")
print("TEST 5: Get department structure")
print("="*60)
r = requests.get(f"{BASE_URL}/attendance/api/mobile/manager/departments/list/", headers=headers)
if r.status_code == 200:
    data = r.json()
    depts = data.get('departments', [])
    if depts:
        print(f"First department:")
        print(json.dumps(depts[0], ensure_ascii=False, indent=2))

print(f"\n{'='*60}")
print("TEST 6: Get leave types")
print("="*60)
r = requests.get(f"{BASE_URL}/attendance/api/mobile/leave-types/", headers=headers)
if r.status_code == 200:
    data = r.json()
    types = data.get('leave_types', [])
    print(f"Total types: {len(types)}")
    for t in types[:5]:
        print(f"  • {t.get('name')} - {t.get('days_allowed')} days - Category: {t.get('category')}")
