"""
Get branches and job titles
"""
import requests
import json
from pathlib import Path

BASE_URL = "https://jssolutions-eg.com"
token = Path("_token.txt").read_text(encoding="utf-8").strip()
headers = {"Authorization": f"Token {token}", "Content-Type": "application/json"}

# 1) Branches
print("="*60)
print("BRANCHES")
print("="*60)
urls_to_try = [
    "/attendance/api/mobile/manager/branches/",
    "/attendance/api/mobile/branches/",
]
for url in urls_to_try:
    r = requests.get(f"{BASE_URL}{url}", headers=headers, timeout=10)
    print(f"\nTrying: {url} -> Status {r.status_code}")
    if r.status_code == 200:
        data = r.json()
        print(json.dumps(data, ensure_ascii=False, indent=2)[:1500])
        Path("_branches.json").write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        break

# 2) Job Titles
print("\n" + "="*60)
print("JOB TITLES")
print("="*60)
urls_to_try = [
    "/attendance/api/mobile/manager/job-titles/",
    "/attendance/api/mobile/job-titles/",
]
for url in urls_to_try:
    r = requests.get(f"{BASE_URL}{url}", headers=headers, timeout=10)
    print(f"\nTrying: {url} -> Status {r.status_code}")
    if r.status_code == 200:
        data = r.json()
        print(json.dumps(data, ensure_ascii=False, indent=2)[:1500])
        Path("_job_titles.json").write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        break

# 3) Test create with all required fields
print("\n" + "="*60)
print("TEST: Create employee with ALL required fields")
print("="*60)

test_employee = {
    "first_name_ar": "اختبار",
    "last_name_ar": "سيمولاتور",
    "first_name_en": "Test",
    "last_name_en": "Simulator",
    "birth_date": "1995-01-01",
    "hire_date": "2026-01-01",
    "branch_id": 40,  # الفرع الرئيسي
    "job_title_id": 5340,  # موجود من التست السابق
    "department_id": 118,  # الحسابات
    "phone": "01000000099",
    "national_id": "29501011234567",
    "gender": "male",
    "basic_salary": 5000,
    "worker_type": "office",
}

r = requests.post(
    f"{BASE_URL}/attendance/api/mobile/manager/employees/create/",
    headers=headers,
    json=test_employee
)
print(f"Status: {r.status_code}")
print(f"Response: {r.text[:1500]}")
