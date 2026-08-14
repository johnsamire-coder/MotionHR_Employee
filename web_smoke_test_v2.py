from playwright.sync_api import sync_playwright
import time

BASE = "https://app.jssolutions-eg.com"

SCENARIOS = [
    ("re_admin", "Test@1234", "manager", "عقاري - مدير"),
    ("con_admin", "Test@1234", "manager", "مقاولات - مدير"),
    ("ph_hr", "Test@1234", "manager", "أدوية - HR"),
    ("wh_admin", "Test@1234", "manager", "مخازن - مدير"),
    ("re_sales_1", "Test@1234", "employee", "عقاري - موظف ميداني"),
    ("con_worker_1", "Test@1234", "employee", "مقاولات - عامل"),
    ("ph_rep_1", "Test@1234", "employee", "أدوية - مندوب"),
    ("wh_dispatch", "Test@1234", "employee", "مخازن - مندوب"),
]

MANAGER_PAGES = [
    ("/hr/dashboard", "لوحة التحكم"),
    ("/hr/employees", "الموظفين"),
    ("/hr/attendance", "الحضور"),
    ("/hr/leaves", "الإجازات"),
    ("/hr/requests", "الطلبات"),
    ("/hr/termination", "إنهاء الخدمة"),
    ("/hr/work-locations", "مواقع العمل"),
    ("/hr/reports/eos", "تقرير EOS"),
    ("/hr/reports/bank-transfer", "تحويل بنكي"),
    ("/hr/reports/insurance", "التأمينات"),
    ("/hr/reports/tax", "الضرائب"),
    ("/hr/reports/turnover", "دوران الموظفين"),
]

EMPLOYEE_PAGES = [
    ("/employee/dashboard", "الرئيسية"),
    ("/employee/leaves", "الإجازات"),
    ("/employee/requests", "الطلبات"),
]

total = 0
passed = 0
failed = []

def test_user(page, username, password, role, label):
    global total, passed

    page.goto(f"{BASE}/login", timeout=30000)
    page.wait_for_load_state("networkidle", timeout=15000)
    page.fill("#username", username)
    page.fill("#password", password)
    page.click("button[type='submit']")

    time.sleep(5)
    page.wait_for_load_state("networkidle", timeout=15000)

    total += 1
    url_after = page.url
    try:
        body_after = page.inner_text("body")[:1000]
    except:
        body_after = ""

    logged_in = (
        "/hr/" in url_after or
        "/employee/" in url_after or
        "/manager/" in url_after or
        "dashboard" in url_after or
        "لوحة التحكم" in body_after or
        "Employee Portal" in body_after or
        "بوابة المدير" in body_after or
        "تسجيل الحضور" in body_after or
        ("مرحباً" in body_after and "MotionHR" in body_after) or
        ("الرئيسية" in body_after and len(body_after) > 200)
    )

    if logged_in:
        passed += 1
        print(f"  ✅ LOGIN OK")
    else:
        failed.append((label, "LOGIN", url_after))
        print(f"  ❌ LOGIN FAIL → {url_after}")
        return

    pages_to_check = MANAGER_PAGES if role == "manager" else EMPLOYEE_PAGES
    for path, name in pages_to_check:
        total += 1
        try:
            page.goto(f"{BASE}{path}", timeout=20000)
            page.wait_for_load_state("networkidle", timeout=15000)
            time.sleep(2)
            current_url = page.url
            body_text = page.inner_text("body")[:500]

            not_login = "/login" not in current_url
            has_content = len(body_text) > 100

            if not_login and has_content:
                passed += 1
                print(f"  ✅ {name:30s} [{current_url.split('jssolutions-eg.com')[-1]}]")
            else:
                failed.append((label, name, current_url))
                print(f"  ❌ {name:30s} → Redirected or empty")
        except Exception as e:
            failed.append((label, name, str(e)[:80]))
            print(f"  ❌ {name:30s} → {str(e)[:80]}")

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)

    for username, password, role, label in SCENARIOS:
        print(f"\n{'─'*65}")
        print(f"USER: {username} | {label}")
        context = browser.new_context()
        page = context.new_page()
        try:
            test_user(page, username, password, role, label)
        except Exception as e:
            failed.append((label, "CRASH", str(e)[:200]))
            print(f"  ❌ CRASH: {str(e)[:200]}")
        finally:
            context.close()

    browser.close()

print(f"\n{'='*65}")
print(f"WEB UI SMOKE TEST V2 RESULTS")
print(f"TOTAL: {total} | PASS: {passed} | FAIL: {len(failed)}")
print(f"{'='*65}")

if failed:
    print("\nFAILED ITEMS:")
    for item in failed:
        print(f"  ❌ {item[0]} → {item[1]} [{item[2]}]")
else:
    print("\n✅ ALL WEB CHECKS PASSED — الويب سليم للبيع")
