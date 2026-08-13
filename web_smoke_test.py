from playwright.sync_api import sync_playwright
import time

BASE = "https://app.jssolutions-eg.com"
API = "https://jssolutions-eg.com"

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
    ("/hr/reports/eos", "تقرير EOS"),
    ("/hr/reports/bank-transfer", "تحويل بنكي"),
    ("/hr/reports/insurance", "التأمينات"),
    ("/hr/reports/tax", "الضرائب"),
]

EMPLOYEE_PAGES = [
    ("/hr/dashboard", "الرئيسية"),
]

total = 0
passed = 0
failed = []

def run():
    global total, passed
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)

        for username, password, role, label in SCENARIOS:
            print(f"\n{'─'*60}")
            print(f"USER: {username} | {label}")
            context = browser.new_context()
            page = context.new_page()

            try:
                page.goto(f"{BASE}/login", timeout=30000)
                page.wait_for_load_state("networkidle", timeout=15000)

                page.fill("input[name='username'], input[type='text']", username)
                page.fill("input[name='password'], input[type='password']", password)
                page.click("button[type='submit']")
                page.wait_for_load_state("networkidle", timeout=20000)

                url = page.url
                total += 1
                if "/hr/" in url or "/dashboard" in url or url != f"{BASE}/login":
                    passed += 1
                    print(f"  ✅ LOGIN OK → {url}")
                else:
                    failed.append((label, "LOGIN", url))
                    print(f"  ❌ LOGIN FAIL → {url}")
                    context.close()
                    continue

                pages_to_check = MANAGER_PAGES if role == "manager" else EMPLOYEE_PAGES

                for path, name in pages_to_check:
                    total += 1
                    try:
                        page.goto(f"{BASE}{path}", timeout=20000)
                        page.wait_for_load_state("networkidle", timeout=15000)
                        title = page.title()
                        status_ok = page.url != f"{BASE}/login"
                        if status_ok:
                            passed += 1
                            print(f"  ✅ {name:25s} → {page.url}")
                        else:
                            failed.append((label, name, "REDIRECT_LOGIN"))
                            print(f"  ❌ {name:25s} → Redirected to login")
                    except Exception as e:
                        failed.append((label, name, str(e)[:80]))
                        print(f"  ❌ {name:25s} → {str(e)[:80]}")

            except Exception as e:
                failed.append((label, "EXCEPTION", str(e)[:200]))
                print(f"  ❌ EXCEPTION: {str(e)[:200]}")

            finally:
                context.close()

        browser.close()

    print(f"\n{'='*60}")
    print(f"WEB UI SMOKE TEST RESULTS")
    print(f"TOTAL: {total} | PASS: {passed} | FAIL: {len(failed)}")
    print(f"{'='*60}")

    if failed:
        print("\nFAILED ITEMS:")
        for item in failed:
            print(f"  ❌ {item[0]} → {item[1]} [{item[2]}]")
    else:
        print("\n✅ ALL WEB CHECKS PASSED")

run()
