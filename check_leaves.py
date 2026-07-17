# -*- coding: utf-8 -*-
"""
سكريبت يفحص LeaveRequests الموجودة على السيرفر
"""
import os
import sys
import django

os.chdir("/var/www/motionhr")
sys.path.insert(0, "/var/www/motionhr")
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "motionhr.settings")
django.setup()

from leaves.models import LeaveRequest
from django.contrib.auth import get_user_model

User = get_user_model()

# فحص testemp
try:
    testemp = User.objects.get(username="testemp")
    print(f"testemp: id={testemp.id}, company={testemp.company_id}")
    if hasattr(testemp, "employee_profile"):
        print(f"  employee_profile: id={testemp.employee_profile.id}")
    else:
        print("  NO employee_profile!")
except Exception as e:
    print(f"testemp error: {e}")

print("-" * 50)

# فحص LeaveRequests
all_leaves = LeaveRequest.all_objects.all()[:5]
print(f"Total LeaveRequests: {LeaveRequest.all_objects.count()}")

for lr in all_leaves:
    print(f"  ID={lr.id} | Employee={lr.employee_id} | Company={lr.company_id} | Status={lr.status}")

# لو مفيش، نعمل واحد للاختبار
if not all_leaves:
    print("\nNo leaves found. Creating a test leave request...")
    try:
        from leaves.models import LeaveType
        from employees.models import Employee
        from datetime import date
        
        emp = Employee.all_objects.filter(user__username="testemp").first()
        lt = LeaveType.all_objects.first()
        
        if emp and lt:
            lr = LeaveRequest(
                company=emp.company,
                employee=emp,
                leave_type=lt,
                start_date=date.today(),
                end_date=date.today(),
                days_count=1,
                reason="Test leave for attachments",
                status="pending",
            )
            lr.save()
            print(f"Created LeaveRequest ID={lr.id}")
        else:
            print(f"Cannot create: emp={emp}, lt={lt}")
    except Exception as e:
        print(f"Create error: {e}")