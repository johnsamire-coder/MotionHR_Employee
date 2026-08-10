"""
MotionHR - Simulation Plan Generator
Generates comprehensive simulation plan + test data
"""
from pathlib import Path
from datetime import datetime, timedelta
import json

OUTPUT_PLAN = Path("SIMULATION_PLAN.md")
OUTPUT_SCENARIOS = Path("SCENARIOS_CHECKLIST.md")
OUTPUT_EMPLOYEES = Path("test_employees_data.json")

# ============================================
# بيانات الموظفين للاختبار
# ============================================
test_employees = [
    # موظفين مكتب (شيفت صباحي)
    {"id": 1, "name_ar": "أحمد محمد علي", "name_en": "Ahmed Mohamed Ali", "username": "ahmed_test", "role": "employee", "department": "IT", "job_title": "Software Developer", "shift": "morning", "salary": 8000, "type": "office", "location_restricted": True},
    {"id": 2, "name_ar": "سارة حسن", "name_en": "Sara Hassan", "username": "sara_test", "role": "employee", "department": "HR", "job_title": "HR Specialist", "shift": "morning", "salary": 7000, "type": "office", "location_restricted": True},
    {"id": 3, "name_ar": "محمود عبدالله", "name_en": "Mahmoud Abdullah", "username": "mahmoud_test", "role": "employee", "department": "Finance", "job_title": "Accountant", "shift": "morning", "salary": 6500, "type": "office", "location_restricted": True},
    {"id": 4, "name_ar": "فاطمة أحمد", "name_en": "Fatma Ahmed", "username": "fatma_test", "role": "employee", "department": "Marketing", "job_title": "Marketing Coordinator", "shift": "morning", "salary": 6000, "type": "office", "location_restricted": True},
    {"id": 5, "name_ar": "كريم سعيد", "name_en": "Karim Saeed", "username": "karim_test", "role": "employee", "department": "IT", "job_title": "QA Engineer", "shift": "morning", "salary": 7500, "type": "office", "location_restricted": True},
    
    # موظفين مكتب (شيفت مسائي)
    {"id": 6, "name_ar": "منى إبراهيم", "name_en": "Mona Ibrahim", "username": "mona_test", "role": "employee", "department": "Support", "job_title": "Support Agent", "shift": "evening", "salary": 5500, "type": "office", "location_restricted": True},
    {"id": 7, "name_ar": "طارق يوسف", "name_en": "Tarek Youssef", "username": "tarek_test", "role": "employee", "department": "Support", "job_title": "Support Agent", "shift": "evening", "salary": 5500, "type": "office", "location_restricted": True},
    {"id": 8, "name_ar": "نورا مصطفى", "name_en": "Nora Mostafa", "username": "nora_test", "role": "employee", "department": "Support", "job_title": "Support Team Lead", "shift": "evening", "salary": 7000, "type": "office", "location_restricted": True},
    
    # موظفين ميدانيين (Field Workers)
    {"id": 9, "name_ar": "خالد رمضان", "name_en": "Khaled Ramadan", "username": "khaled_test", "role": "employee", "department": "Sales", "job_title": "Field Sales", "shift": "flexible", "salary": 6000, "type": "field", "location_restricted": False},
    {"id": 10, "name_ar": "ياسمين علي", "name_en": "Yasmin Ali", "username": "yasmin_test", "role": "employee", "department": "Sales", "job_title": "Field Sales", "shift": "flexible", "salary": 6000, "type": "field", "location_restricted": False},
    {"id": 11, "name_ar": "عمر حسام", "name_en": "Omar Hossam", "username": "omar_test", "role": "employee", "department": "Delivery", "job_title": "Delivery Driver", "shift": "flexible", "salary": 4500, "type": "field", "location_restricted": False},
    
    # مديرين
    {"id": 12, "name_ar": "ماجد الجندي", "name_en": "Maged Elgendy", "username": "maged_test", "role": "manager", "department": "IT", "job_title": "IT Manager", "shift": "morning", "salary": 15000, "type": "office", "location_restricted": True},
    {"id": 13, "name_ar": "دينا محسن", "name_en": "Dina Mohsen", "username": "dina_test", "role": "manager", "department": "Sales", "job_title": "Sales Manager", "shift": "morning", "salary": 15000, "type": "office", "location_restricted": True},
    
    # موظف بمرتب عالي
    {"id": 14, "name_ar": "شريف فؤاد", "name_en": "Sherif Fouad", "username": "sherif_test", "role": "employee", "department": "IT", "job_title": "Senior Architect", "shift": "morning", "salary": 25000, "type": "office", "location_restricted": True},
    
    # موظف بمرتب منخفض للاختبار
    {"id": 15, "name_ar": "حسن جمال", "name_en": "Hassan Gamal", "username": "hassan_test", "role": "employee", "department": "Support", "job_title": "Junior Support", "shift": "morning", "salary": 4000, "type": "office", "location_restricted": True},
]

OUTPUT_EMPLOYEES.write_text(json.dumps(test_employees, ensure_ascii=False, indent=2), encoding="utf-8")

# ============================================
# خطة الـ Simulation
# ============================================
plan = []
plan.append("# 🧪 MotionHR - خطة الـ Simulation الشاملة")
plan.append("")
plan.append(f"**التاريخ:** {datetime.now().strftime('%Y-%m-%d')}")
plan.append("**الشركة المستهدفة:** GPS (الشركة التجريبية)")
plan.append("**الحساب المستخدم:** `john` (company_admin)")
plan.append("")
plan.append("---")
plan.append("")

# نظرة عامة
plan.append("## 📖 نظرة عامة")
plan.append("")
plan.append("### الهدف من الـ Simulation:")
plan.append("- ✅ اختبار كامل النظام على شركة حقيقية")
plan.append("- ✅ التأكد من صحة كل الحسابات (رواتب، إجازات، حضور)")
plan.append("- ✅ اكتشاف الأخطاء والمشاكل قبل الإطلاق")
plan.append("- ✅ اختبار السيناريوهات المركّبة (مهام + حضور + شيفتات)")
plan.append("- ✅ التأكد من عمل Background Services (Auto Check-in)")
plan.append("")
plan.append("### المعلومات المهمة:")
plan.append("- **عدد الموظفين:** 15 موظف (5 صباحي، 3 مسائي، 3 ميداني، 2 مدير، 2 حالات خاصة)")
plan.append("- **المدة المتوقعة:** يوم كامل من الاختبار")
plan.append("- **البيئة:** Production Server")
plan.append("")
plan.append("---")
plan.append("")

# قائمة الموظفين
plan.append("## 👥 قائمة موظفي الاختبار")
plan.append("")
plan.append("### 📊 الإحصائيات:")
plan.append(f"- إجمالي: **{len(test_employees)}** موظف")
office = sum(1 for e in test_employees if e['type'] == 'office')
field = sum(1 for e in test_employees if e['type'] == 'field')
managers = sum(1 for e in test_employees if e['role'] == 'manager')
plan.append(f"- موظفين مكتب: **{office}**")
plan.append(f"- موظفين ميدان: **{field}**")
plan.append(f"- مديرين: **{managers}**")
total_salary = sum(e['salary'] for e in test_employees)
plan.append(f"- إجمالي الرواتب الشهرية: **{total_salary:,} جنيه**")
plan.append("")

plan.append("### الجدول الكامل:")
plan.append("")
plan.append("| # | الاسم | Username | Role | القسم | الوظيفة | الشيفت | الراتب | النوع |")
plan.append("|---|-------|----------|------|-------|---------|---------|--------|--------|")
for e in test_employees:
    plan.append(f"| {e['id']} | {e['name_ar']} | `{e['username']}` | {e['role']} | {e['department']} | {e['job_title']} | {e['shift']} | {e['salary']:,} | {e['type']} |")
plan.append("")
plan.append("---")
plan.append("")

# مراحل الـ Simulation
plan.append("## 🎬 مراحل الـ Simulation")
plan.append("")

# المرحلة 1: التجهيز
plan.append("### المرحلة 1️⃣: التجهيز (30 دقيقة)")
plan.append("")
plan.append("#### أ) تجهيز الشركة:")
plan.append("- [ ] الدخول بـ `john` (company_admin)")
plan.append("- [ ] التأكد من إعدادات الشركة (اسم، لوجو، عنوان)")
plan.append("- [ ] ضبط Geofence (النطاق الجغرافي للشركة)")
plan.append("- [ ] ضبط الإجازات الرسمية للسنة")
plan.append("")
plan.append("#### ب) تجهيز الأقسام والفروع:")
plan.append("- [ ] إضافة الأقسام: IT, HR, Finance, Marketing, Sales, Support, Delivery")
plan.append("- [ ] إضافة الفروع (لو أكثر من فرع)")
plan.append("- [ ] إضافة المسميات الوظيفية")
plan.append("")
plan.append("#### ج) تجهيز الشيفتات:")
plan.append("- [ ] شيفت صباحي: 9:00 AM - 5:00 PM")
plan.append("- [ ] شيفت مسائي: 2:00 PM - 10:00 PM")
plan.append("- [ ] شيفت مرن (للميدانيين)")
plan.append("")
plan.append("#### د) تجهيز السياسات:")
plan.append("- [ ] سياسة الحضور (تأخير، غياب، سماحية)")
plan.append("- [ ] سياسة الإجازات (سنوية، مرضية، عارضة)")
plan.append("- [ ] سياسة العمل (ساعات العمل، الراحة)")
plan.append("- [ ] سياسة الرواتب (الراتب الأساسي، البدلات)")
plan.append("- [ ] سياسة الضرائب")
plan.append("- [ ] سياسة التأمين الاجتماعي والطبي")
plan.append("- [ ] سياسة نهاية الخدمة")
plan.append("")
plan.append("---")
plan.append("")

# المرحلة 2: إضافة الموظفين
plan.append("### المرحلة 2️⃣: إضافة الموظفين (30 دقيقة)")
plan.append("")
plan.append("#### أ) إضافة عن طريق Import (10 موظفين):")
plan.append("- [ ] تحميل قالب Excel من التطبيق")
plan.append("- [ ] ملء بيانات 10 موظفين (رقم 1-10 من الجدول)")
plan.append("- [ ] رفع الملف")
plan.append("- [ ] التحقق من نجاح الاستيراد")
plan.append("- [ ] التحقق من إرسال بيانات الدخول للموظفين")
plan.append("")
plan.append("#### ب) إضافة يدوية (5 موظفين):")
plan.append("- [ ] إضافة الموظفين 11-15 يدوياً واحد واحد")
plan.append("- [ ] التأكد من كل الحقول (اسم، وظيفة، شيفت، راتب)")
plan.append("- [ ] تعيين الشيفت لكل موظف")
plan.append("- [ ] تعيين المدير المباشر")
plan.append("")
plan.append("---")
plan.append("")

# المرحلة 3: سيناريوهات الحضور
plan.append("### المرحلة 3️⃣: سيناريوهات الحضور")
plan.append("")
plan.append("#### 🎯 سيناريو 1: حضور عادي")
plan.append("- [ ] دخول موظف صباحي (`ahmed_test`) في الوقت")
plan.append("- [ ] التحقق من تسجيل الحضور")
plan.append("- [ ] التحقق من ظهوره في dashboard المدير")
plan.append("")
plan.append("#### 🎯 سيناريو 2: تأخير")
plan.append("- [ ] دخول موظف بعد وقت الشيفت بـ 15 دقيقة")
plan.append("- [ ] التحقق من حساب التأخير")
plan.append("- [ ] التحقق من ظهوره في تقرير التأخيرات")
plan.append("")
plan.append("#### 🎯 سيناريو 3: Auto Check-in (Geofence)")
plan.append("- [ ] موظف يدخل نطاق الشركة")
plan.append("- [ ] التحقق من تسجيل الحضور تلقائياً")
plan.append("- [ ] التحقق من الـ notification للموظف والمدير")
plan.append("")
plan.append("#### 🎯 سيناريو 4: خروج جزئي (Partial Checkout)")
plan.append("- [ ] موظف يعمل check-out جزئي (يخرج ويرجع)")
plan.append("- [ ] التحقق من حساب الساعات الصحيح")
plan.append("- [ ] التحقق من إمكانية Resume check-in")
plan.append("")
plan.append("#### 🎯 سيناريو 5: نسيان تسجيل خروج")
plan.append("- [ ] موظف لم يعمل check-out")
plan.append("- [ ] التحقق من التعامل مع الحالة")
plan.append("- [ ] هل يعتبر يوم كامل ولا جزء؟")
plan.append("")
plan.append("---")
plan.append("")

# المرحلة 4: سيناريو المهام والزيارات (المهم!)
plan.append("### المرحلة 4️⃣: 🔥 سيناريوهات المهام والزيارات (المركّبة)")
plan.append("")
plan.append("> **ملاحظة مهمة:** دي أهم سيناريوهات ولازم نتأكد إنها شغالة")
plan.append("")
plan.append("#### 🎯 سيناريو 6: موظف في زيارة وقت تسجيل الحضور")
plan.append("- [ ] المدير ينشئ مهمة/زيارة لموظف ميداني (`khaled_test`)")
plan.append("- [ ] الموظف يذهب لمكان الزيارة")
plan.append("- [ ] الموظف يعمل check-in من مكان الزيارة (بره نطاق الشركة)")
plan.append("- [ ] **السؤال:** هل السيستم يقبل الحضور من موقع المهمة؟")
plan.append("- [ ] **المتوقع:** ✅ يقبل لأن الموظف نوعه ميداني وله مهمة معتمدة")
plan.append("- [ ] التحقق من عدم اعتباره غياب")
plan.append("")
plan.append("#### 🎯 سيناريو 7: موظف مكتب يحاول check-in من بره الشركة")
plan.append("- [ ] موظف مكتب (`ahmed_test`) يحاول check-in من بره Geofence")
plan.append("- [ ] **المتوقع:** ❌ السيستم يرفض")
plan.append("- [ ] التحقق من رسالة الخطأ الواضحة")
plan.append("")
plan.append("#### 🎯 سيناريو 8: موظف مشي قبل ما تخلص المهمة")
plan.append("- [ ] موظف ميداني (`yasmin_test`) في مهمة")
plan.append("- [ ] المهمة لسه شغالة والوقت اتأخر")
plan.append("- [ ] الموظف يحاول check-out")
plan.append("- [ ] **السؤال:** هل السيستم يسمح بـ check-out قبل انتهاء المهمة؟")
plan.append("- [ ] **الاحتمالات:**")
plan.append("  - أ) يسمح بشرط إغلاق المهمة")
plan.append("  - ب) يمنع ويطلب إنهاء المهمة أولاً")
plan.append("  - ج) يسمح ويسجل ملاحظة على المهمة")
plan.append("- [ ] **القرار المطلوب من المستخدم**")
plan.append("")
plan.append("#### 🎯 سيناريو 9: مهمة مستمرة لليوم التاني")
plan.append("- [ ] مهمة بدأت اليوم ومستمرة لبكرة")
plan.append("- [ ] التحقق من حساب ساعات العمل صحيح")
plan.append("- [ ] التحقق من عدم تكرار الحضور")
plan.append("")
plan.append("#### 🎯 سيناريو 10: زيارات متعددة في يوم واحد")
plan.append("- [ ] موظف ميداني يعمل 3 زيارات في يوم")
plan.append("- [ ] كل زيارة في موقع مختلف")
plan.append("- [ ] التحقق من تسجيل الحضور/الانصراف لكل زيارة")
plan.append("- [ ] التحقق من إجمالي ساعات العمل صحيح")
plan.append("")
plan.append("---")
plan.append("")

# المرحلة 5: سيناريوهات الإجازات
plan.append("### المرحلة 5️⃣: سيناريوهات الإجازات")
plan.append("")
plan.append("#### 🎯 سيناريو 11: طلب إجازة سنوية")
plan.append("- [ ] موظف يطلب إجازة 3 أيام")
plan.append("- [ ] المدير يوافق")
plan.append("- [ ] التحقق من خصم الرصيد")
plan.append("- [ ] التحقق من ظهورها في التقويم")
plan.append("")
plan.append("#### 🎯 سيناريو 12: طلب إجازة نصف يوم")
plan.append("- [ ] موظف يطلب Half-day (صباحي أو مسائي)")
plan.append("- [ ] التحقق من الحساب (0.5 يوم)")
plan.append("- [ ] التحقق من الحضور في الجزء التاني من اليوم")
plan.append("")
plan.append("#### 🎯 سيناريو 13: إجازة مرضية بشهادة")
plan.append("- [ ] موظف يرفع طلب إجازة مرضية")
plan.append("- [ ] يرفع الشهادة الطبية")
plan.append("- [ ] المدير يعتمد")
plan.append("- [ ] التحقق من عدم تأثيرها على الراتب")
plan.append("")
plan.append("#### 🎯 سيناريو 14: استدعاء إجازة")
plan.append("- [ ] موظف في إجازة")
plan.append("- [ ] المدير يستدعيه (Leave Recall)")
plan.append("- [ ] التحقق من إرجاع الأيام للرصيد")
plan.append("- [ ] التحقق من تسجيل الحضور")
plan.append("")
plan.append("#### 🎯 سيناريو 15: طلب إجازة برصيد غير كافي")
plan.append("- [ ] موظف يطلب أكثر من رصيده")
plan.append("- [ ] **المتوقع:** ❌ السيستم يرفض")
plan.append("")
plan.append("---")
plan.append("")

# المرحلة 6: سيناريوهات الشيفتات
plan.append("### المرحلة 6️⃣: سيناريوهات الشيفتات")
plan.append("")
plan.append("#### 🎯 سيناريو 16: تغيير شيفت مؤقت")
plan.append("- [ ] المدير يغير شيفت موظف ليوم واحد (Override)")
plan.append("- [ ] التحقق من حساب الحضور على الشيفت الجديد")
plan.append("")
plan.append("#### 🎯 سيناريو 17: دوران الشيفتات (Rotation)")
plan.append("- [ ] إعداد rotation لفريق (أسبوع صباحي، أسبوع مسائي)")
plan.append("- [ ] التحقق من التطبيق التلقائي")
plan.append("")
plan.append("#### 🎯 سيناريو 18: طلب تغيير شيفت من الموظف")
plan.append("- [ ] موظف يطلب تغيير شيفت")
plan.append("- [ ] المدير يوافق/يرفض")
plan.append("- [ ] التحقق من التطبيق")
plan.append("")
plan.append("---")
plan.append("")

# المرحلة 7: سيناريوهات الرواتب (المهم!)
plan.append("### المرحلة 7️⃣: 💰 سيناريوهات الرواتب (المهمة جداً)")
plan.append("")
plan.append("#### 🎯 سيناريو 19: تشغيل Payroll Run كامل")
plan.append("- [ ] المدير يبدأ Payroll Run لشهر معين")
plan.append("- [ ] السيستم يحسب لكل موظف:")
plan.append("  - [ ] الراتب الأساسي")
plan.append("  - [ ] البدلات")
plan.append("  - [ ] المكافآت")
plan.append("  - [ ] الخصومات (تأخيرات، غيابات)")
plan.append("  - [ ] الضرائب")
plan.append("  - [ ] التأمين الاجتماعي")
plan.append("  - [ ] التأمين الطبي")
plan.append("  - [ ] السلف")
plan.append("- [ ] التحقق من الحسابات بالحسبة اليدوية")
plan.append("")
plan.append("#### 🎯 سيناريو 20: حساب ساعات العمل الفعلية")
plan.append("- [ ] موظف عمل 5 أيام كاملة + 1 يوم تأخير ساعة + 1 غياب")
plan.append("- [ ] التحقق من الحساب:")
plan.append("  - عدد الأيام الفعلية")
plan.append("  - قيمة الخصم على التأخير")
plan.append("  - قيمة الخصم على الغياب")
plan.append("")
plan.append("#### 🎯 سيناريو 21: مكافأة")
plan.append("- [ ] إضافة مكافأة يدوية لموظف (Manual Entry)")
plan.append("- [ ] التحقق من ظهورها في Payslip")
plan.append("")
plan.append("#### 🎯 سيناريو 22: خصم استثنائي")
plan.append("- [ ] إضافة خصم يدوي (مثلاً سلفة)")
plan.append("- [ ] التحقق من الحساب")
plan.append("")
plan.append("#### 🎯 سيناريو 23: نهاية خدمة")
plan.append("- [ ] موظف يستقيل / يتم إنهاء خدمته")
plan.append("- [ ] السيستم يحسب:")
plan.append("  - [ ] مكافأة نهاية الخدمة")
plan.append("  - [ ] رصيد الإجازات المتبقي")
plan.append("  - [ ] أي مستحقات تانية")
plan.append("")
plan.append("#### 🎯 سيناريو 24: موظف بمرتب عالي")
plan.append("- [ ] `sherif_test` (25000 جنيه)")
plan.append("- [ ] التحقق من حساب الضرائب على شرائح")
plan.append("- [ ] التحقق من التأمين على الحد الأقصى")
plan.append("")
plan.append("#### 🎯 سيناريو 25: موظف بمرتب منخفض")
plan.append("- [ ] `hassan_test` (4000 جنيه)")
plan.append("- [ ] التحقق من عدم خصم ضريبة (تحت الحد الأدنى)")
plan.append("")
plan.append("---")
plan.append("")

# المرحلة 8: سيناريوهات الصلاحيات
plan.append("### المرحلة 8️⃣: سيناريوهات الصلاحيات")
plan.append("")
plan.append("#### 🎯 سيناريو 26: إنشاء Role مخصص")
plan.append("- [ ] إنشاء role جديد (مثلاً: 'Team Lead')")
plan.append("- [ ] تحديد صلاحيات محددة")
plan.append("- [ ] تعيين موظف للـ role")
plan.append("")
plan.append("#### 🎯 سيناريو 27: صلاحيات استثنائية")
plan.append("- [ ] إعطاء موظف صلاحية محددة (Override)")
plan.append("- [ ] التحقق من عملها")
plan.append("- [ ] سحبها بعد فترة")
plan.append("")
plan.append("---")
plan.append("")

# المرحلة 9: التقارير
plan.append("### المرحلة 9️⃣: التقارير")
plan.append("")
plan.append("#### 🎯 سيناريو 28: تقارير الحضور")
plan.append("- [ ] تقرير الحضور اليومي")
plan.append("- [ ] تقرير الحضور الشهري")
plan.append("- [ ] تقرير التأخيرات")
plan.append("- [ ] تقرير الغياب")
plan.append("- [ ] تقرير ساعات العمل")
plan.append("")
plan.append("#### 🎯 سيناريو 29: تقارير الإجازات والطلبات")
plan.append("- [ ] تقرير الإجازات الأساسي")
plan.append("- [ ] تقرير الإجازات المطوّر")
plan.append("- [ ] تقرير الطلبات")
plan.append("- [ ] تقرير الأذونات")
plan.append("")
plan.append("#### 🎯 سيناريو 30: تقارير الرواتب")
plan.append("- [ ] تقرير Payroll الشهري")
plan.append("- [ ] Payslip لكل موظف")
plan.append("- [ ] تقرير الضرائب")
plan.append("- [ ] تقرير التأمينات")
plan.append("")
plan.append("#### 🎯 سيناريو 31: تقارير المواقع")
plan.append("- [ ] تقرير المواقع للموظفين الميدانيين")
plan.append("- [ ] تقرير الزيارات")
plan.append("- [ ] تتبع Live Locations")
plan.append("")
plan.append("---")
plan.append("")

# المرحلة 10: تقارير CEO المقترحة
plan.append("### المرحلة 🔟: 📊 تقارير CEO المقترحة (سنبنيها)")
plan.append("")
plan.append("> بناءً على أفضل الممارسات في أنظمة HR الاحترافية")
plan.append("")

plan.append("#### 📈 Dashboard CEO المقترح:")
plan.append("")
plan.append("##### KPIs رئيسية (أعلى الشاشة):")
plan.append("1. **إجمالي الموظفين** (مقسّم: نشط، إجازة، معلق)")
plan.append("2. **نسبة الالتزام اليومي** (Attendance Rate %)")
plan.append("3. **إجمالي الرواتب الشهرية**")
plan.append("4. **متوسط ساعات العمل / موظف**")
plan.append("5. **عدد الطلبات المعلقة**")
plan.append("6. **معدل الغياب %**")
plan.append("")

plan.append("##### الرسوم البيانية:")
plan.append("")
plan.append("**1. مخطط الحضور اليومي (Line Chart)**")
plan.append("- المحور X: الأيام (آخر 30 يوم)")
plan.append("- المحور Y: عدد الحاضرين")
plan.append("- خط إضافي: المتوسط")
plan.append("")

plan.append("**2. توزيع الموظفين حسب القسم (Pie Chart)**")
plan.append("- كل قسم بلونه")
plan.append("- النسبة المئوية")
plan.append("")

plan.append("**3. مقارنة الرواتب حسب القسم (Bar Chart)**")
plan.append("- Bar chart لكل قسم")
plan.append("- Total salary لكل قسم")
plan.append("")

plan.append("**4. معدل الالتزام الشهري (Area Chart)**")
plan.append("- آخر 6 شهور")
plan.append("- خط لكل شهر بنسبة الحضور")
plan.append("")

plan.append("**5. أنواع الإجازات المستخدمة (Donut Chart)**")
plan.append("- توزيع أنواع الإجازات")
plan.append("- سنوية / مرضية / عارضة / بدون راتب")
plan.append("")

plan.append("**6. Top 5 Departments بأعلى معدل غياب**")
plan.append("- Horizontal bar chart")
plan.append("- علامات تنبيه")
plan.append("")

plan.append("**7. توزيع الأعمار (Age Distribution)**")
plan.append("- Histogram")
plan.append("")

plan.append("**8. توزيع سنوات الخبرة**")
plan.append("- Bar chart")
plan.append("- تحديد الموظفين المؤهلين للترقية")
plan.append("")

plan.append("##### تقارير جاهزة للتصدير:")
plan.append("1. **تقرير شهري شامل للشركة** (PDF)")
plan.append("2. **تقرير الأداء ربع السنوي**")
plan.append("3. **تقرير مالي شامل** (رواتب + بدلات + خصومات)")
plan.append("4. **تقرير الموارد البشرية** (تعيينات، استقالات، ترقيات)")
plan.append("5. **تقرير ساعات العمل الإضافية**")
plan.append("6. **تقرير التوظيف** (Recruitment funnel)")
plan.append("")

plan.append("##### Alerts & Notifications:")
plan.append("- 🔴 موظفين متأخرين اليوم")
plan.append("- 🟡 طلبات معلقة أكثر من 3 أيام")
plan.append("- 🔴 موظفين تجاوزوا الرصيد")
plan.append("- 🟢 موظفين وصلوا مواعيد ترقية")
plan.append("- 🔴 عقود قاربت على الانتهاء")
plan.append("")

plan.append("---")
plan.append("")

# نتائج مطلوبة
plan.append("## 📋 ما يجب أن يظهر في التقرير النهائي")
plan.append("")
plan.append("لكل سيناريو، يجب تسجيل:")
plan.append("- ✅ / ❌ نجح ولا لأ")
plan.append("- 📝 ملاحظات")
plan.append("- 🐛 أخطاء (لو موجودة)")
plan.append("- 💡 اقتراحات للتحسين")
plan.append("")

plan.append("---")
plan.append("")
plan.append("**جاهزين نبدأ؟** 🚀")

OUTPUT_PLAN.write_text("\n".join(plan), encoding="utf-8")

# ============================================
# Checklist منفصل
# ============================================
checklist = []
checklist.append("# ✅ MotionHR - Checklist الـ Simulation")
checklist.append("")
checklist.append("**استخدم هذا الملف لتتبع التقدم**")
checklist.append("")
checklist.append("---")
checklist.append("")

sections = [
    ("🎯 التجهيز", [
        "الدخول بـ john",
        "إعدادات الشركة",
        "Geofence",
        "الإجازات الرسمية",
        "الأقسام",
        "الفروع",
        "المسميات الوظيفية",
        "الشيفتات (صباحي، مسائي، مرن)",
        "سياسة الحضور",
        "سياسة الإجازات",
        "سياسة الرواتب",
        "سياسة الضرائب",
        "سياسة التأمين",
        "سياسة نهاية الخدمة",
    ]),
    ("👥 إضافة الموظفين", [
        "استيراد 10 موظفين (Import)",
        "إضافة 5 موظفين يدوياً",
        "تعيين الشيفتات",
        "تعيين المديرين",
        "إرسال بيانات الدخول",
    ]),
    ("🎯 سيناريوهات الحضور (5)", [
        "حضور عادي",
        "تأخير",
        "Auto Check-in (Geofence)",
        "Partial Checkout",
        "نسيان تسجيل خروج",
    ]),
    ("🔥 سيناريوهات المهام (5)", [
        "موظف في زيارة وقت الحضور",
        "موظف مكتب من بره الشركة",
        "موظف مشي قبل انتهاء المهمة",
        "مهمة مستمرة لليوم التاني",
        "زيارات متعددة في يوم",
    ]),
    ("🌴 سيناريوهات الإجازات (5)", [
        "إجازة سنوية",
        "نصف يوم",
        "مرضية بشهادة",
        "استدعاء إجازة",
        "رصيد غير كافي",
    ]),
    ("⏰ سيناريوهات الشيفتات (3)", [
        "تغيير شيفت مؤقت",
        "Rotation",
        "طلب تغيير من الموظف",
    ]),
    ("💰 سيناريوهات الرواتب (7)", [
        "Payroll Run كامل",
        "حساب ساعات العمل",
        "مكافأة",
        "خصم استثنائي",
        "نهاية خدمة",
        "موظف بمرتب عالي (شرائح ضريبية)",
        "موظف بمرتب منخفض (تحت الحد)",
    ]),
    ("🔐 سيناريوهات الصلاحيات (2)", [
        "Role مخصص",
        "صلاحيات استثنائية",
    ]),
    ("📊 التقارير (4)", [
        "تقارير الحضور",
        "تقارير الإجازات",
        "تقارير الرواتب",
        "تقارير المواقع",
    ]),
]

total_items = 0
for section_title, items in sections:
    checklist.append(f"## {section_title}")
    checklist.append("")
    for item in items:
        checklist.append(f"- [ ] {item}")
        total_items += 1
    checklist.append("")

checklist.append("---")
checklist.append("")
checklist.append(f"**إجمالي البنود:** {total_items}")

OUTPUT_SCENARIOS.write_text("\n".join(checklist), encoding="utf-8")

# ============================================
# Summary
# ============================================
print(f"\n[OK] Simulation Plan: {OUTPUT_PLAN.absolute()}")
print(f"[OK] Checklist: {OUTPUT_SCENARIOS.absolute()}")
print(f"[OK] Test Employees Data: {OUTPUT_EMPLOYEES.absolute()}")
print(f"\n[SUMMARY]")
print(f"  - Test Employees: {len(test_employees)}")
print(f"  - Total Scenarios: 31")
print(f"  - Total Checklist Items: {total_items}")
print(f"  - Total Salary: {sum(e['salary'] for e in test_employees):,} EGP")
