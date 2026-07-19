import os
import re
import shutil
from datetime import datetime

BASE = r"C:\MotionHR\motionhr_employee\motionhr_employee\lib"
BACKUP_SUFFIX = f".bak_translate_{datetime.now().strftime('%Y%m%d_%H%M%S')}"

# ملفات نتجاهلها
SKIP_EXTENSIONS = ['.bak', '.backup', '.phase9', '.bak_push_foreground',
                   '.bak_before_reports_button']
SKIP_FILES = ['app_localizations.dart', 'app_localizations_ar.dart',
              'app_localizations_en.dart', 'l10n.dart',
              'app_strings.dart', 'language_service.dart']

# خريطة الاستبدال: النص الثابت → context.l10n.key
# ترتيب مهم: الأطول أولاً لتجنب التعارض
REPLACEMENTS = [
    # --- جمل طويلة أولاً ---
    ("'تسجيل الدخول والخروج'", "context.l10n.attendanceDone"),
    ("'تم تسجيل الحضور والانصراف'", "context.l10n.attendanceDone"),
    ("'يبقى الحساب منتوحاً حتى 72 ساعة أو حتى تسجيل الخروج'", "context.l10n.stayLoggedInDesc"),
    ("'يبقى الحساب مفتوحاً حتى 72 ساعة أو حتى تسجيل الخروج'", "context.l10n.stayLoggedInDesc"),
    ("'من فضلك تواصل مع مسؤول الموارد البشرية لإعادة تعيين كلمة المرور الخاصة بك.'", "context.l10n.forgotPasswordDesc"),
    ("'من فضلك ادخل اسم المستخدم وكلمة المرور'", "context.l10n.enterUsernamePassword"),
    ("'بيانات الدخول غير صحيحة'", "context.l10n.loginError"),
    ("'خطأ في الاتصال بالخادم'", "context.l10n.connectionError"),
    ("'تم تغيير كلمة المرور بنجاح'", "context.l10n.passwordChanged"),
    ("'كلمة المرور غير متطابقة'", "context.l10n.passwordMismatch"),
    ("'كلمة المرور يجب أن تكون 6 أحرف على الأقل'", "context.l10n.passwordTooShort"),
    ("'تم تسجيل الحضور والانصراف'", "context.l10n.attendanceDone"),
    ("'أحسنت العمل اليوم 🎉'", "context.l10n.greatWork"),
    ("'عندك إذن خروج مبكر'", "context.l10n.earlyLeavePermission"),
    ("'الشيفت خلص، تقدر تنصرف'", "context.l10n.shiftEnded"),
    ("'جاري التحميل...'", "context.l10n.loading"),
    ("'لا توجد بيانات'", "context.l10n.noData"),
    ("'لا يوجد بيانات'", "context.l10n.noData"),
    ("'لا توجد موظفون'", "context.l10n.noEmployees"),
    ("'لا يوجد موظفون'", "context.l10n.noEmployees"),
    ("'لا توجد طلبات'", "context.l10n.noRequests"),
    ("'لا يوجد طلبات'", "context.l10n.noRequests"),
    ("'لا توجد إشعارات'", "context.l10n.noNotifications"),
    ("'لا يوجد إشعارات'", "context.l10n.noNotifications"),
    ("'لا توجد مهمات'", "context.l10n.noMissions"),
    ("'لا يوجد مهمات'", "context.l10n.noMissions"),
    ("'لا يوجد فيدباك'", "context.l10n.noFeedback"),
    ("'لا توجد فيدباك'", "context.l10n.noFeedback"),
    ("'تعليم الكل كمقروءة'", "context.l10n.markAllRead"),
    ("'إعادة تعيين كلمة المرور'", "context.l10n.resetPassword"),
    ("'إنشاء موظف'", "context.l10n.createEmployee"),
    ("'تعديل بيانات الموظف'", "context.l10n.editEmployee"),
    ("'تفاصيل الموظف'", "context.l10n.employeeDetails"),
    ("'نقل الموظف'", "context.l10n.transferEmployee"),
    ("'قائمة الموظفين'", "context.l10n.employeesList"),
    ("'الإدارة السريعة'", "context.l10n.quickManagement"),
    ("'لوحة التحكم'", "context.l10n.dashboard"),
    ("'تقديم طلب'", "context.l10n.submitRequest"),
    ("'طلب إجازة'", "context.l10n.requestLeave"),
    ("'إلغاء الطلب'", "context.l10n.cancelRequest"),
    ("'تأكيد إلغاء الطلب'", "context.l10n.cancelRequestConfirm"),
    ("'سبب الإلغاء (اختياري)'", "context.l10n.cancelReason"),
    ("'تصدير PDF'", "context.l10n.exportPdf"),
    ("'تصدير Excel'", "context.l10n.exportExcel"),
    ("'رفع الشعار'", "context.l10n.uploadLogo"),
    ("'تعديل بيانات الشركة'", "context.l10n.editCompany"),
    ("'بيانات الشركة'", "context.l10n.companyInfo"),
    ("'الهيكل التنظيمي'", "context.l10n.orgTree"),
    ("'تقرير المواقع'", "context.l10n.locationReport"),
    ("'تسجيل الحضور'", "context.l10n.checkIn"),
    ("'تسجيل الانصراف'", "context.l10n.checkOut"),
    ("'تم الحضور'", "context.l10n.checkedIn"),
    ("'تم الانصراف'", "context.l10n.checkedOut"),
    ("'وقت الحضور'", "context.l10n.checkInTime"),
    ("'وقت الانصراف'", "context.l10n.checkOutTime"),
    ("'الوقت المتبقي'", "context.l10n.remainingTime"),
    ("'سجل الأيام السابقة'", "context.l10n.history"),
    ("'تقرير الحضور'", "context.l10n.attendanceReport"),
    ("'تقرير الإجازات'", "context.l10n.leavesReport"),
    ("'تقرير التأخيرات'", "context.l10n.lateReport"),
    ("'تقرير الغياب'", "context.l10n.absenceReport"),
    ("'تقرير ساعات العمل'", "context.l10n.workHoursReport"),
    ("'تقرير الطلبات'", "context.l10n.requestsReport"),
    ("'إجراءات المدير'", "context.l10n.managerActions"),
    ("'تحديث الموقع'", "context.l10n.locationUpdate"),
    ("'وصف الموقع'", "context.l10n.locationLabel"),
    ("'رفع مرفق'", "context.l10n.uploadAttachment"),
    ("'وصف المرفق'", "context.l10n.attachmentCaption"),
    ("'تم بدء المهمة'", "context.l10n.missionStarted"),
    ("'تم إنهاء المهمة'", "context.l10n.missionEnded"),
    ("'تم بدء المهمة وتسجيل حضورك تلقائياً'", "context.l10n.autoCheckin"),
    ("'يرجى كتابة فيدباك الزيارة'", "context.l10n.feedbackRequired"),
    ("'تم حفظ الفيدباك بنجاح'", "context.l10n.feedbackSaved"),
    ("'تم إرسال الطلب للمدير. انتظر الموافقة.'", "context.l10n.requestSentToManager"),
    ("'طلب الانسحاب'", "context.l10n.withdrawRequest"),
    ("'سبب الانسحاب'", "context.l10n.withdrawReason"),
    ("'إلغاء المهمة'", "context.l10n.cancelMission"),
    ("'سبب الإلغاء'", "context.l10n.cancelMissionReason"),
    ("'استبدال موظف'", "context.l10n.replaceEmployee"),
    ("'الموظف الحالي'", "context.l10n.currentEmployee"),
    ("'الموظف الجديد'", "context.l10n.newEmployee"),
    ("'مهمة جديدة'", "context.l10n.newMission"),
    ("'داشبورد الفيدباك'", "context.l10n.feedbackDashboard"),
    ("'طلبات المهمات المعلقة'", "context.l10n.pendingMissionRequests"),
    ("'تم توقيع عقد'", "context.l10n.contractSigned"),
    ("'مهتم جداً'", "context.l10n.veryInterested"),
    ("'يفكر'", "context.l10n.thinking"),
    ("'غير مهتم'", "context.l10n.notInterested"),
    ("'مؤجل'", "context.l10n.postponed"),
    ("'تاريخ المتابعة'", "context.l10n.followupDate"),
    ("'ملاحظات داخلية'", "context.l10n.internalNotes"),
    ("'تحذيرات'", "context.l10n.warnings"),
    ("'المشاركون'", "context.l10n.participants"),
    ("'قائد المهمة'", "context.l10n.missionLead"),
    ("'مساعد'", "context.l10n.assistant"),
    ("'مدير مرافق'", "context.l10n.accompaniedManager"),
    ("'متدرب'", "context.l10n.trainee"),
    ("'نسخ كلمة المرور'", "context.l10n.copyPassword"),
    ("'تم نسخ كلمة المرور'", "context.l10n.passwordCopied"),
    ("'Powered by MotionHR - JS Solutions'", "context.l10n.poweredBy"),
    ("'انتهت الجلسة، سجل دخولك مجدداً'", "context.l10n.sessionExpired"),
    ("'لا يوجد اتصال بالإنترنت'", "context.l10n.noInternetConnection"),
    ("'غير مصرح لك'", "context.l10n.permissionDenied"),
    ("'يجب منح صلاحية الموقع'", "context.l10n.locationPermission"),
    ("'الكاميرا'", "context.l10n.camera"),
    ("'المعرض'", "context.l10n.gallery"),
    ("'التقاط صورة'", "context.l10n.takePhoto"),
    ("'اختر من المعرض'", "context.l10n.chooseFromGallery"),
    ("'رفع ملف'", "context.l10n.uploadFile"),
    ("'تم رفع الملف'", "context.l10n.fileUploaded"),
    ("'كتابة الفيدباك'", "context.l10n.writeFeedback"),
    ("'فيدباك الزيارة'", "context.l10n.missionFeedback"),
    # --- كلمات مفردة ---
    ("'تسجيل الدخول'", "context.l10n.login"),
    ("'تسجيل الخروج'", "context.l10n.logout"),
    ("'اسم المستخدم'", "context.l10n.username"),
    ("'كلمة المرور'", "context.l10n.password"),
    ("'تذكرني'", "context.l10n.rememberMe"),
    ("'الإبقاء مسجلاً'", "context.l10n.stayLoggedIn"),
    ("'البقاء مسجلاً'", "context.l10n.stayLoggedIn"),
    ("'نسيت كلمة المرور؟'", "context.l10n.forgotPassword"),
    ("'نسيت كلمة المرور'", "context.l10n.forgotPassword"),
    ("'حفظ'", "context.l10n.save"),
    ("'إلغاء'", "context.l10n.cancel"),
    ("'تأكيد'", "context.l10n.confirm"),
    ("'حذف'", "context.l10n.delete"),
    ("'تعديل'", "context.l10n.edit"),
    ("'إضافة'", "context.l10n.add"),
    ("'بحث'", "context.l10n.search"),
    ("'تحديث'", "context.l10n.refresh"),
    ("'خطأ'", "context.l10n.error"),
    ("'نجاح'", "context.l10n.success"),
    ("'اللغة'", "context.l10n.language"),
    ("'الإعدادات'", "context.l10n.settings"),
    ("'تغيير اللغة'", "context.l10n.changeLanguage"),
    ("'نعم'", "context.l10n.yes"),
    ("'لا'", "context.l10n.no"),
    ("'حسناً'", "context.l10n.ok"),
    ("'رجوع'", "context.l10n.back"),
    ("'إغلاق'", "context.l10n.close"),
    ("'إرسال'", "context.l10n.send"),
    ("'إعادة المحاولة'", "context.l10n.retry"),
    ("'تم'", "context.l10n.done"),
    ("'اختر لغتك'", "context.l10n.chooseLanguage"),
    ("'العربية'", "context.l10n.arabic"),
    ("'متابعة'", "context.l10n.continueBtn"),
    ("'الدخول بالبصمة'", "context.l10n.loginBiometric"),
    ("'الرقم الوظيفي'", "context.l10n.employeeCode"),
    ("'الاسم الكامل'", "context.l10n.fullName"),
    ("'الاسم الأول'", "context.l10n.firstName"),
    ("'الاسم الأخير'", "context.l10n.lastName"),
    ("'الموبايل'", "context.l10n.phone"),
    ("'البريد الإلكتروني'", "context.l10n.email"),
    ("'الرقم القومي'", "context.l10n.nationalId"),
    ("'تاريخ الميلاد'", "context.l10n.birthDate"),
    ("'النوع'", "context.l10n.gender"),
    ("'ذكر'", "context.l10n.male"),
    ("'أنثى'", "context.l10n.female"),
    ("'العنوان'", "context.l10n.address"),
    ("'الفرع'", "context.l10n.branch"),
    ("'الإدارة'", "context.l10n.department"),
    ("'المسمى الوظيفي'", "context.l10n.jobTitle"),
    ("'المدير المباشر'", "context.l10n.directManager"),
    ("'تاريخ التعيين'", "context.l10n.hireDate"),
    ("'الراتب الأساسي'", "context.l10n.basicSalary"),
    ("'الموظفون'", "context.l10n.employees"),
    ("'إضافة موظف'", "context.l10n.addEmployee"),
    ("'الإعلانات'", "context.l10n.announcements"),
    ("'التقارير'", "context.l10n.reports"),
    ("'الرواتب'", "context.l10n.payroll"),
    ("'التذكيرات'", "context.l10n.reminders"),
    ("'لائحة الشركة'", "context.l10n.companyCharter"),
    ("'المهمات'", "context.l10n.missions"),
    ("'اسم الشركة'", "context.l10n.companyName"),
    ("'شعار الشركة'", "context.l10n.companyLogo"),
    ("'عنوان الشركة'", "context.l10n.companyAddress"),
    ("'تليفون الشركة'", "context.l10n.companyPhone"),
    ("'الفروع'", "context.l10n.branches"),
    ("'الإدارات'", "context.l10n.departments"),
    ("'المديرون'", "context.l10n.managers"),
    ("'طباعة'", "context.l10n.print"),
    ("'أهلاً يا'", "context.l10n.hello"),
    ("'صباح الخير'", "context.l10n.goodMorning"),
    ("'مساء الخير'", "context.l10n.goodEvening"),
    ("'مع السلامة'", "context.l10n.goodbye"),
    ("'الشيفت'", "context.l10n.shift"),
    ("'اليوم'", "context.l10n.today"),
    ("'التاريخ'", "context.l10n.date"),
    ("'الوقت'", "context.l10n.time"),
    ("'الطلبات'", "context.l10n.requests"),
    ("'الإجازات'", "context.l10n.leaves"),
    ("'طلباتي'", "context.l10n.myRequests"),
    ("'إجازاتي'", "context.l10n.myLeaves"),
    ("'نوع الطلب'", "context.l10n.requestType"),
    ("'نوع الإجازة'", "context.l10n.leaveType"),
    ("'عنوان الطلب'", "context.l10n.requestTitle"),
    ("'التفاصيل'", "context.l10n.requestDetails"),
    ("'من تاريخ'", "context.l10n.fromDate"),
    ("'إلى تاريخ'", "context.l10n.toDate"),
    ("'السبب'", "context.l10n.reason"),
    ("'رصيد الإجازات'", "context.l10n.leaveBalance"),
    ("'يوم'", "context.l10n.days"),
    ("'ساعة'", "context.l10n.hours"),
    ("'المبلغ'", "context.l10n.amount"),
    ("'عنوان المهمة'", "context.l10n.missionTitle"),
    ("'تفاصيل المهمة'", "context.l10n.missionDetails"),
    ("'موقع المهمة'", "context.l10n.missionLocation"),
    ("'اسم العميل'", "context.l10n.clientName"),
    ("'تليفون العميل'", "context.l10n.clientPhone"),
    ("'الأولوية'", "context.l10n.priority"),
    ("'عاجل'", "context.l10n.urgent"),
    ("'عالي'", "context.l10n.high"),
    ("'عادي'", "context.l10n.normal"),
    ("'وقت البدء المخطط'", "context.l10n.plannedStart"),
    ("'وقت الانتهاء المخطط'", "context.l10n.plannedEnd"),
    ("'بدء المهمة'", "context.l10n.startMission"),
    ("'إنهاء المهمة'", "context.l10n.endMission"),
    ("'قبول'", "context.l10n.acceptMission"),
    ("'رفض'", "context.l10n.rejectMission"),
    ("'مهماتي'", "context.l10n.myMissions"),
    ("'الإشعارات'", "context.l10n.notifications"),
    ("'الملف الشخصي'", "context.l10n.profile"),
    ("'تغيير كلمة المرور'", "context.l10n.changePassword"),
    ("'كلمة المرور الحالية'", "context.l10n.currentPassword"),
    ("'كلمة المرور الجديدة'", "context.l10n.newPassword"),
    ("'تأكيد كلمة المرور'", "context.l10n.confirmPassword"),
    ("'الشركة'", "context.l10n.company"),
    ("'الفروع'", "context.l10n.branches"),
    ("'قيد الانتظار'", "context.l10n.pending"),
    ("'موافق عليه'", "context.l10n.approved"),
    ("'مرفوض'", "context.l10n.rejected"),
    ("'ملغي'", "context.l10n.cancelled"),
    ("'جارية'", "context.l10n.inProgress"),
    ("'مكتملة'", "context.l10n.completed"),
    ("'نشط'", "context.l10n.active"),
    ("'في إجازة'", "context.l10n.onLeave"),
    ("'موقوف'", "context.l10n.suspended"),
    ("'مستقيل'", "context.l10n.resigned"),
    ("'مفصول'", "context.l10n.terminated"),
    ("'الملاحظات'", "context.l10n.notes"),
    ("'الحالة'", "context.l10n.status"),
    ("'النوع'", "context.l10n.type"),
    ("'الاسم'", "context.l10n.name"),
    ("'الكود'", "context.l10n.code"),
    ("'الرقم'", "context.l10n.number"),
    ("'الإجمالي'", "context.l10n.total"),
    ("'مطلوب'", "context.l10n.required"),
    ("'اختياري'", "context.l10n.optional"),
    ("'من'", "context.l10n.from"),
    ("'إلى'", "context.l10n.to"),
    ("'بواسطة'", "context.l10n.by"),
    ("'في'", "context.l10n.at"),
    ("'الرئيسية'", "context.l10n.home"),
    ("'مهتم'", "context.l10n.interested"),
]

def should_skip(filepath):
    filename = os.path.basename(filepath)
    for ext in SKIP_EXTENSIONS:
        if filepath.endswith(ext):
            return True
    for skip in SKIP_FILES:
        if filename == skip:
            return True
    return False

def get_dart_files(base):
    dart_files = []
    for root, dirs, files in os.walk(base):
        for f in files:
            if f.endswith('.dart'):
                full = os.path.join(root, f)
                if not should_skip(full):
                    dart_files.append(full)
    return dart_files

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    count = 0
    
    for old, new in REPLACEMENTS:
        if old in content:
            occurrences = content.count(old)
            content = content.replace(old, new)
            count += occurrences
    
    if count > 0:
        # عمل backup
        shutil.copy2(filepath, filepath + BACKUP_SUFFIX)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  ✅ {os.path.relpath(filepath, BASE)} — {count} استبدال")
    else:
        print(f"  ⏭  {os.path.relpath(filepath, BASE)} — لا تغييرات")
    
    return count

def main():
    print("=" * 60)
    print("🔄 MotionHR — سكريبت الترجمة التلقائية")
    print("=" * 60)
    
    dart_files = get_dart_files(BASE)
    print(f"\n📁 عدد الملفات: {len(dart_files)}\n")
    
    total = 0
    changed_files = 0
    
    for filepath in dart_files:
        count = process_file(filepath)
        total += count
        if count > 0:
            changed_files += 1
    
    print("\n" + "=" * 60)
    print(f"✅ انتهى! {total} استبدال في {changed_files} ملف")
    print("=" * 60)

if __name__ == '__main__':
    main() 
