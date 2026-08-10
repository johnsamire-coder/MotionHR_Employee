"""
MotionHR - Simulation Batch 1: Company Setup
==============================================
تجهيز شركة GPS قبل إضافة الموظفين
"""
import requests
import json
from pathlib import Path

BASE_URL = "https://jssolutions-eg.com"

# ─── Login ───
print("="*60)
print("🔐 STEP 0: Login as john")
print("="*60)
r = requests.post(
    f"{BASE_URL}/attendance/api/mobile/login/",
    json={"username": "john", "password": "12345678"},
    timeout=15
)
if r.status_code != 200:
    print(f"❌ Login failed: {r.status_code}")
    exit(1)

data = r.json()
token = data['token']
headers = {"Authorization": f"Token {token}", "Content-Type": "application/json"}
print(f"✅ Logged in as {data.get('user', {}).get('username', 'john')}")
print(f"   Company: {data.get('company_name', 'GPS')}")

# ─── Helper ───
results = {
    "departments": [],
    "job_titles": [],
    "shifts": [],
    "geofence": None,
    "errors": []
}

def try_post(name, url, payload):
    print(f"\n▶ {name}...")
    try:
        r = requests.post(f"{BASE_URL}{url}", headers=headers, json=payload, timeout=15)
        if r.status_code in [200, 201]:
            data = r.json()
            print(f"  ✅ Success ({r.status_code})")
            return data
        else:
            print(f"  ❌ Failed ({r.status_code}): {r.text[:200]}")
            results["errors"].append({"name": name, "status": r.status_code, "error": r.text[:300]})
            return None
    except Exception as e:
        print(f"  ❌ Exception: {e}")
        results["errors"].append({"name": name, "error": str(e)})
        return None

# ═══════════════════════════════════════════════
# STEP 1: إضافة الأقسام (7 قسم جديد)
# ═══════════════════════════════════════════════
print("\n" + "="*60)
print("🏛️ STEP 1: Adding Departments (7 new)")
print("="*60)

departments_to_add = [
    {"name_ar": "تكنولوجيا المعلومات", "name_en": "IT", "code": "IT"},
    {"name_ar": "المبيعات", "name_en": "Sales", "code": "SALES"},
    {"name_ar": "الدعم الفني", "name_en": "Support", "code": "SUPPORT"},
    {"name_ar": "التسويق", "name_en": "Marketing", "code": "MKT"},
    {"name_ar": "الموارد البشرية", "name_en": "Human Resources", "code": "HR"},
    {"name_ar": "العمليات", "name_en": "Operations", "code": "OPS"},
    {"name_ar": "التوصيل", "name_en": "Delivery", "code": "DEL"},
]

for dept in departments_to_add:
    result = try_post(f"Add Department: {dept['name_ar']}", 
                     "/attendance/api/mobile/manager/departments/add/", dept)
    if result and result.get('success'):
        dept_data = result.get('department', {})
        results["departments"].append({
            "id": dept_data.get('id'),
            "name": dept['name_ar'],
            "code": dept['code']
        })

# ═══════════════════════════════════════════════
# STEP 2: إضافة المسميات الوظيفية (10 مسمى)
# ═══════════════════════════════════════════════
print("\n" + "="*60)
print("💼 STEP 2: Adding Job Titles (10 new)")
print("="*60)

# نجيب الـ URL الصحيح لإضافة job title
# جرب URLs مختلفة
job_titles_to_add = [
    {"name_ar": "مطور برمجيات", "name_en": "Software Developer"},
    {"name_ar": "مهندس QA", "name_en": "QA Engineer"},
    {"name_ar": "مندوب مبيعات", "name_en": "Sales Representative"},
    {"name_ar": "متخصص دعم فني", "name_en": "Support Specialist"},
    {"name_ar": "منسق تسويق", "name_en": "Marketing Coordinator"},
    {"name_ar": "متخصص موارد بشرية", "name_en": "HR Specialist"},
    {"name_ar": "منسق عمليات", "name_en": "Operations Coordinator"},
    {"name_ar": "سائق توصيل", "name_en": "Delivery Driver"},
    {"name_ar": "مهندس معماري أول", "name_en": "Senior Architect"},
    {"name_ar": "مدير فريق", "name_en": "Team Lead"},
]

# جرب endpoints مختلفة
job_title_endpoints = [
    "/attendance/api/mobile/manager/job-titles/create/",
    "/attendance/api/mobile/manager/job-titles/add/",
    "/attendance/api/mobile/manager/job-titles/",
]

# جرب الأول endpoint واحد عشان نعرف الصحيح
print("\n🔍 Testing job title endpoints...")
for endpoint in job_title_endpoints:
    try:
        r = requests.post(f"{BASE_URL}{endpoint}", headers=headers, 
                         json={"name_ar": "TEST_JOB", "name_en": "TEST"}, timeout=10)
        print(f"  {endpoint} -> {r.status_code}")
        if r.status_code in [200, 201]:
            print(f"  ✅ Using: {endpoint}")
            active_jt_endpoint = endpoint
            break
    except:
        pass
else:
    active_jt_endpoint = None
    print("  ⚠️ No working endpoint found for job titles - skipping")

if active_jt_endpoint:
    for jt in job_titles_to_add:
        result = try_post(f"Add Job Title: {jt['name_ar']}", active_jt_endpoint, jt)
        if result and result.get('success'):
            jt_data = result.get('job_title', {})
            results["job_titles"].append({
                "id": jt_data.get('id'),
                "name": jt['name_ar']
            })

# ═══════════════════════════════════════════════
# STEP 3: إضافة الشيفتات (3 شيفتات)
# ═══════════════════════════════════════════════
print("\n" + "="*60)
print("⏰ STEP 3: Adding Shifts (3 shifts)")
print("="*60)

shifts_to_add = [
    {
        "name": "الشيفت الصباحي",
        "start_time": "09:00",
        "end_time": "17:00",
        "shift_type": "fixed",
        "grace_period": 15,
        "break_duration": 60,
        "required_daily_hours": 8,
        "work_sunday": True,
        "work_monday": True,
        "work_tuesday": True,
        "work_wednesday": True,
        "work_thursday": True,
        "work_friday": False,
        "work_saturday": False,
    },
    {
        "name": "الشيفت المسائي",
        "start_time": "14:00",
        "end_time": "22:00",
        "shift_type": "fixed",
        "grace_period": 15,
        "break_duration": 60,
        "required_daily_hours": 8,
        "work_sunday": True,
        "work_monday": True,
        "work_tuesday": True,
        "work_wednesday": True,
        "work_thursday": True,
        "work_friday": False,
        "work_saturday": False,
    },
    {
        "name": "الشيفت المرن",
        "start_time": "08:00",
        "end_time": "20:00",
        "shift_type": "flexible",
        "grace_period": 30,
        "break_duration": 60,
        "required_daily_hours": 8,
        "work_sunday": True,
        "work_monday": True,
        "work_tuesday": True,
        "work_wednesday": True,
        "work_thursday": True,
        "work_friday": False,
        "work_saturday": False,
    }
]

# جرب endpoints
shift_endpoints = [
    "/attendance/api/mobile/manager/shifts/create/",
    "/attendance/api/mobile/manager/shifts/",
]

print("\n🔍 Testing shift endpoints...")
for endpoint in shift_endpoints:
    try:
        r = requests.post(f"{BASE_URL}{endpoint}", headers=headers,
                         json=shifts_to_add[0], timeout=10)
        print(f"  {endpoint} -> {r.status_code}")
        if r.status_code in [200, 201]:
            print(f"  ✅ Using: {endpoint}")
            active_shift_endpoint = endpoint
            # الأول تم إضافته
            shift_data = r.json().get('shift', {})
            results["shifts"].append({
                "id": shift_data.get('id'),
                "name": shifts_to_add[0]['name']
            })
            # أضف الباقي
            for shift in shifts_to_add[1:]:
                res = try_post(f"Add Shift: {shift['name']}", active_shift_endpoint, shift)
                if res and res.get('success'):
                    sh = res.get('shift', {})
                    results["shifts"].append({"id": sh.get('id'), "name": shift['name']})
            break
    except Exception as e:
        print(f"  Error: {e}")

# ═══════════════════════════════════════════════
# STEP 4: ضبط Geofence
# ═══════════════════════════════════════════════
print("\n" + "="*60)
print("📍 STEP 4: Setting Geofence")
print("="*60)

geofence_payload = {
    "latitude": 30.0444,   # القاهرة
    "longitude": 31.2357,
    "radius": 200,
    "enabled": True,
    "address": "القاهرة، مصر"
}

result = try_post("Set Geofence", "/attendance/api/mobile/geofence/set/", geofence_payload)
if result and result.get('success'):
    results["geofence"] = geofence_payload
    print(f"  📍 Location: ({geofence_payload['latitude']}, {geofence_payload['longitude']})")
    print(f"  📏 Radius: {geofence_payload['radius']} meters")

# ═══════════════════════════════════════════════
# النتائج
# ═══════════════════════════════════════════════
print("\n" + "="*60)
print("📊 SETUP RESULTS SUMMARY")
print("="*60)
print(f"✅ Departments added: {len(results['departments'])}")
print(f"✅ Job Titles added: {len(results['job_titles'])}")
print(f"✅ Shifts added: {len(results['shifts'])}")
print(f"✅ Geofence: {'Set' if results['geofence'] else 'Not Set'}")
print(f"⚠️ Errors: {len(results['errors'])}")

if results['errors']:
    print("\n📝 Errors details:")
    for err in results['errors'][:5]:
        print(f"  - {err['name']}: {err.get('error', 'unknown')[:100]}")

# احفظ النتائج
Path("_setup_results.json").write_text(
    json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8"
)

print(f"\n💾 Results saved to: _setup_results.json")
print("\n🎯 Next Step: Add 50 employees!")
