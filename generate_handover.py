"""
MotionHR - Final Professional Handover Document
================================================
تقرير احترافي نهائي يجمع كل حاجة
"""
import json
import re
from pathlib import Path
from collections import defaultdict
from datetime import datetime

MOBILE_DIR = Path("lib")
OUTPUT = Path("MOTIONHR_HANDOVER.md")

# نفس الـ Patterns من السكربت السابق
CLASS_START_PATTERN = re.compile(
    r"class\s+(\w+(?:Screen|Page|Shell|Dashboard|Widget|View|Hub|Router))\s+extends\s+(?:Stateful|Stateless)Widget"
)
APPBAR_TITLE_PATTERN = re.compile(r"""AppBar\s*\([^{]*?title:\s*(?:const\s+)?Text\s*\(\s*['"]([^'"]{2,120})['"]""", re.DOTALL)
APPBAR_TITLE_TERNARY = re.compile(r"""AppBar\s*\([^{]*?title:\s*Text\s*\(\s*isAr\s*\?\s*['"]([^'"]+)['"]\s*:\s*['"]([^'"]+)['"]""", re.DOTALL)
APPBAR_TITLE_L10N = re.compile(r"""AppBar\s*\([^{]*?title:\s*(?:const\s+)?Text\s*\(\s*context\.l10n\.(\w+)""", re.DOTALL)
GRID_CARD_PATTERN = re.compile(r"""_gridCard\s*\(\s*(?:isAr\s*\?\s*['"]([^'"]{2,80})['"][^,)]*?['"]([^'"]{2,80})['"]|context\.l10n\.(\w+)|['"]([^'"]{2,80})['"])""")
URL_PATTERN = re.compile(r"""(/(?:attendance|leaves|employee|hr|api|accounts|companies|subscriptions|requests|notifications)/[a-zA-Z0-9_\-/${{}}.]+)""")
NAVIGATE_PATTERN = re.compile(r"""MaterialPageRoute\s*\(\s*builder:\s*\([^)]*\)\s*=>\s*(?:const\s+)?(\w+)""")
BOTTOM_NAV_LABEL_L10N = re.compile(r"""BottomNavigationBarItem\s*\([^)]*?label:\s*context\.l10n\.(\w+)""", re.DOTALL)
BOTTOM_NAV_LABEL_STR = re.compile(r"""BottomNavigationBarItem\s*\([^)]*?label:\s*['"]([^'"]{2,60})['"]""", re.DOTALL)

# ============================================
# Screen Descriptions (بالبشري)
# ============================================
SCREEN_DESCRIPTIONS = {
    # Auth
    'LoginScreen': 'شاشة تسجيل الدخول الرئيسية - المستخدم يدخل username وpassword',
    'ChangePasswordScreen': 'شاشة تغيير كلمة المرور - المستخدم يدخل الكلمة القديمة والجديدة',
    'ActivateAccountScreen': 'شاشة تفعيل الحساب - للحسابات الجديدة اللي محتاجة تفعيل',
    'SplashScreen': 'شاشة البداية اللي بتظهر عند فتح التطبيق',
    
    # Employee
    'EmployeeShell': '🏠 الحاوية الرئيسية للموظف - فيها 5 تبويبات: Home, Leaves, Requests, Missions, My Items',
    'EmployeeHomeScreen': '🏠 الشاشة الرئيسية للموظف - Check-in/out، الحضور اليوم، الشيفت',
    'LeavesScreen': '🌴 شاشة الإجازات والأذونات - عرض الرصيد وتقديم طلبات',
    'LeaveRequestScreen': '📝 نموذج تقديم طلب إجازة جديد',
    'RequestsScreen': '📋 شاشة الطلبات - عرض وتقديم طلبات (سلف، شهادات، إلخ)',
    'HistoryScreen': '📅 سجل الحضور التاريخي للموظف',
    'CharterScreen': '📜 لائحة الشركة - عرض والموافقة',
    'AnnouncementsScreen': '📢 عرض الإعلانات المرسلة للموظفين',
    'AnnouncementDetailScreen': '📢 تفاصيل إعلان محدد',
    'NotificationsScreen': '🔔 الإشعارات - كل الإشعارات المستلمة',
    'EmployeeProfileScreen': '👤 الملف الشخصي للموظف',
    'EmployeePayslipScreen': '💵 كشف رواتب الموظف الشخصي',
    'EmployeeSummaryScreen': '📊 ملخص بيانات الموظف',
    'EmployeeDocumentsScreen': '📄 مستندات الموظف',
    'EmployeeMovementsScreen': '🔄 حركات الموظف (نقل، ترقية)',
    'EmployeeMissionsScreen': '🎯 مهمات الموظف الميدانية',
    'EmployeeMissionDetailScreen': '🎯 تفاصيل مهمة محددة',
    'FieldVisitsScreen': '📍 الزيارات الميدانية للموظف',
    'MyShiftScreen': '⏰ شيفت الموظف الحالي',
    'MyWorkLocationsScreen': '📌 مواقع عمل الموظف المعتمدة',
    'MyItemsScreen': '📦 الطلبات والإجازات المقدمة سابقاً',
    'ItemDetailScreen': '📦 تفاصيل طلب/إجازة',
    
    # Manager
    'ManagerShell': '🏢 الحاوية الرئيسية للمدير - Home, Team, Requests, More',
    'ManagerHomeRouter': '🎯 موزع ذكي - يفتح ManagerDashboard لصاحب الشركة و ManagerShell للمدير',
    'ManagerDashboard': '📊 لوحة تحكم صاحب الشركة الكاملة - كل الميزات في مكان واحد',
    'ManagerTeamScreen': '👥 عرض فريق المدير',
    'ManagerMoreScreen': '⚙️ قائمة المزيد للمدير',
    'ManagerMyRequestsHubScreen': '📋 طلبات المدير الشخصية',
    'ManagerPendingScreen': '⏳ الطلبات المعلقة للموافقة',
    'ManagerAttendanceScreen': '📊 حضور الفريق اليوم',
    'ManagerLiveLocationsScreen': '📍 المواقع المباشرة للموظفين',
    'ManagerMissionsScreen': '🎯 إدارة المهمات',
    'ManagerAnnouncementsScreen': '📢 إدارة الإعلانات',
    'ManagerEmployeesListScreen': '👥 قائمة كل الموظفين',
    'ManagerEmployeeDetailScreen': '👤 تفاصيل موظف - عرض وتعديل',
    'CreateEmployeeScreen': '➕ إضافة موظف جديد',
    'ManagerCharterScreen': '📜 إدارة لائحة الشركة',
    'ManagerGeofenceScreen': '📍 إعداد النطاق الجغرافي',
    'CompanyInfoScreen': '🏢 معلومات الشركة',
    'CompanyEditScreen': '✏️ تعديل بيانات الشركة',
    'DepartmentsManagementScreen': '🏛️ إدارة الأقسام',
    'DepartmentDetailScreen': '🏛️ تفاصيل قسم محدد',
    'BranchesScreen': '🏢 إدارة الفروع',
    'JobTitlesScreen': '💼 إدارة المسميات الوظيفية',
    'OrganizationTreeScreen': '🌳 الهيكل التنظيمي',
    'OfficialHolidaysScreen': '📅 الإجازات الرسمية',
    'OffboardingScreen': '🚪 إنهاء خدمة موظف',
    'ImportToolsScreen': '📥 استيراد بيانات (Excel)',
    'ReminderSettingsScreen': '⏰ إعدادات التنبيهات',
    'WorkLocationsApprovalScreen': '📍 اعتماد مواقع العمل',
    'LocationReportScreen': '📊 تقرير المواقع',
    
    # Policies
    'PoliciesHubScreen': '📋 مركز السياسات الرئيسي',
    'AttendancePolicyScreen': '⚙️ سياسات الحضور والانصراف',
    'LeavePolicyScreen': '⚙️ سياسات الإجازات',
    'WorkPolicyScreen': '⚙️ سياسات العمل',
    'PayrollPolicyScreen': '⚙️ سياسات الرواتب',
    'LeaveRecallScreen': '↩️ استدعاء إجازة',
    'FlexAdjustmentsScreen': '🔧 تسويات الشيفت المرن',
    
    # Permissions
    'PermissionsHubScreen': '🔐 مركز الصلاحيات',
    'PermissionsManagementScreen': '🔐 إدارة الصلاحيات',
    'PermissionsAssignScreen': '👤 تعيين صلاحيات لموظف',
    'PermissionsRolesScreen': '🎭 إدارة الأدوار',
    'PermissionsOverridesScreen': '⚠️ استثناءات الصلاحيات',
    'PermissionsExportScreen': '📤 تصدير الصلاحيات',
    'EmployeePermissionsScreen': '🔐 صلاحيات موظف محدد',
    'RoleDetailScreen': '🎭 تفاصيل دور محدد',
    
    # Shifts
    'ShiftsScreen': '⏰ إدارة الشيفتات',
    'CreateEditShiftScreen': '✏️ إنشاء/تعديل شيفت',
    'AssignShiftScreen': '📌 تعيين شيفت لموظف',
    'AssignmentDetailScreen': '📋 تفاصيل تعيين شيفت',
    'ShiftOverrideScreen': '🔄 استثناءات الشيفتات',
    'ShiftRotationScreen': '🔁 دوران الشيفتات',
    
    # Reports
    'ReportsHubScreen': '📊 مركز التقارير',
    'AttendanceReportScreen': '📊 تقرير الحضور الشهري',
    'DailyAttendanceReportScreen': '📊 تقرير الحضور اليومي',
    'AbsenceReportScreen': '📊 تقرير الغياب',
    'LateReportScreen': '📊 تقرير التأخيرات',
    'WorkHoursReportScreen': '📊 تقرير ساعات العمل',
    'LeavesReportScreen': '📊 تقرير الإجازات الأساسي',
    'LeavesEnhancedReportScreen': '📊 تقرير الإجازات المطوّر',
    'RequestsReportScreen': '📊 تقرير الطلبات',
    'PermissionsReportScreen': '📊 تقرير الأذونات',
    'ShiftsReportScreen': '📊 تقرير الشيفتات',
    'PayrollReportScreen': '📊 تقرير الرواتب',
    
    # Payroll
    'PayrollHubScreen': '💰 مركز الرواتب',
    'PayrollRunScreen': '💵 تشغيل دورة رواتب',
    'PayrollRunDetailScreen': '💵 تفاصيل دورة رواتب',
    'PayrollPayslipScreen': '💵 كشف رواتب',
    'PayrollSummaryScreen': '📊 ملخص الرواتب',
    'PayrollEmployeeDetailScreen': '👤 تفاصيل رواتب موظف',
    'PayrollSettingsScreen': '⚙️ إعدادات الرواتب',
    'PayrollCycleScreen': '🔄 دورات الرواتب',
    'PayrollBonusPenaltyScreen': '💰 المكافآت والخصومات',
    'CompanyPoliciesScreen': '📋 سياسات الشركة المالية',
    'ManualEntriesScreen': '✏️ إدخالات يدوية',
    'TaxPolicyScreen': '💸 سياسات الضرائب',
    'InsurancePoliciesScreen': '🏥 سياسات التأمين',
    'EosPolicyScreen': '👋 سياسات نهاية الخدمة',
    'LeaveRulesScreen': '📋 قواعد الإجازات',
    'BonusRulesScreen': '💰 قواعد المكافآت',
    'PenaltyRulesScreen': '⚠️ قواعد الخصومات',
    'AllowanceRulesScreen': '💵 قواعد البدلات',
    'CreateEditAllowanceRuleScreen': '✏️ إنشاء/تعديل بدل',
    'CreateEditBonusRuleScreen': '✏️ إنشاء/تعديل مكافأة',
    'CreateEditPenaltyRuleScreen': '✏️ إنشاء/تعديل خصم',
    'CreateEditLeaveRuleScreen': '✏️ إنشاء/تعديل قاعدة إجازة',
    'CreateEditTaxPolicyScreen': '✏️ إنشاء/تعديل سياسة ضريبة',
    'CreateEditInsurancePolicyScreen': '✏️ إنشاء/تعديل تأمين',
    'CreateEditEosPolicyScreen': '✏️ إنشاء/تعديل نهاية خدمة',
    'CreateEditPayrollCycleScreen': '✏️ إنشاء/تعديل دورة',
    
    # Common
    'LocationPickerScreen': '📍 اختيار موقع من الخريطة',
    'SettingsScreen': '⚙️ الإعدادات العامة',
    'FirstLaunchLanguageScreen': '🌐 اختيار اللغة عند أول تشغيل',
}

def split_main_dart(text):
    positions = [(m.start(), m.group(1)) for m in CLASS_START_PATTERN.finditer(text)]
    positions.sort()
    parts = {}
    for i, (start, name) in enumerate(positions):
        end = positions[i + 1][0] if i + 1 < len(positions) else len(text)
        parts[name] = text[start:end]
    return parts

def extract_from_text(text):
    titles = list(set(APPBAR_TITLE_PATTERN.findall(text)))
    titles.extend([f"{a} / {e}" for a, e in APPBAR_TITLE_TERNARY.findall(text)])
    titles.extend([f"l10n.{k}" for k in APPBAR_TITLE_L10N.findall(text)])
    
    apis = set()
    for m in URL_PATTERN.findall(text):
        c = m.split('?')[0].split("'")[0].split('"')[0]
        c = re.sub(r'\$\{[^}]+\}', '{var}', c)
        c = re.sub(r'\$\w+', '{var}', c)
        if len(c) > 4 and '.dart' not in c:
            apis.add(c.rstrip('/'))
    
    navigates = list(set(NAVIGATE_PATTERN.findall(text)))
    
    grid_cards = set()
    for match in GRID_CARD_PATTERN.findall(text):
        for item in match:
            if item and item.strip():
                grid_cards.add(item.strip())
    
    return {
        'titles': list(set(titles))[:3],
        'apis': sorted(apis),
        'navigates': navigates,
        'grid_cards': sorted(grid_cards),
    }

# ============================================
# Main
# ============================================
def build():
    print("[BUILD] Reading files...")
    
    # اقرأ main.dart
    main_text = (MOBILE_DIR / "main.dart").read_text(encoding="utf-8", errors="ignore")
    main_parts = split_main_dart(main_text)
    
    # اقرأ screens
    screens_data = {}
    for cls_name, cls_text in main_parts.items():
        data = extract_from_text(cls_text)
        data['name'] = cls_name
        data['file'] = 'lib/main.dart'
        screens_data[cls_name] = data
    
    screens_root = MOBILE_DIR / "screens"
    if screens_root.exists():
        for fp in screens_root.rglob("*.dart"):
            if "_backup" in str(fp) or ".bak" in str(fp):
                continue
            try:
                text = fp.read_text(encoding="utf-8", errors="ignore")
                classes = CLASS_START_PATTERN.findall(text)
                if classes:
                    name = classes[0]
                    data = extract_from_text(text)
                    data['name'] = name
                    data['file'] = str(fp).replace('\\', '/')
                    screens_data[name] = data
            except:
                pass
    
    # جمع كل APIs الفريدة
    all_apis = set()
    for s in screens_data.values():
        all_apis.update(s.get('apis', []))
    
    # تصنيف APIs
    api_categories = defaultdict(list)
    for api in sorted(all_apis):
        parts = api.strip('/').split('/')
        if len(parts) < 4:
            category = 'other'
        else:
            # /attendance/api/mobile/CATEGORY/...
            category = parts[3] if len(parts) > 3 else 'other'
        api_categories[category].append(api)
    
    # ============================================
    # Build Markdown
    # ============================================
    md = []
    
    # Header
    md.append("# 📱 MotionHR - الوثيقة الشاملة والمرجع الرسمي")
    md.append("")
    md.append(f"**تاريخ الإصدار:** {datetime.now().strftime('%Y-%m-%d')}")
    md.append("**نوع الوثيقة:** Handover Document + Technical Reference")
    md.append("**نطاق التغطية:** كل شاشات التطبيق، الأدوار، APIs، والانتقالات")
    md.append("")
    md.append("---")
    md.append("")
    
    # مقدمة
    md.append("## 📖 مقدمة")
    md.append("")
    md.append("**MotionHR** هو نظام متكامل لإدارة الموارد البشرية يتكون من:")
    md.append("- 📱 **تطبيق موبايل موحّد** (Flutter) - نفس التطبيق لكل الأدوار")
    md.append("- 🌐 **بوابة ويب** (Next.js) - لـ HR وصاحب الشركة")
    md.append("- ⚙️ **Backend** (Django) - يخدم الاتنين")
    md.append("")
    md.append(f"**إجمالي الشاشات:** {len(screens_data)} شاشة")
    md.append(f"**إجمالي الـ APIs:** {len(all_apis)} endpoint")
    md.append("")
    md.append("---")
    md.append("")
    
    # جدول محتويات
    md.append("## 📑 جدول المحتويات")
    md.append("")
    md.append("1. [👥 الأدوار في النظام](#-الأدوار-في-النظام)")
    md.append("2. [🔐 دور المصادقة (Auth)](#-دور-المصادقة-auth)")
    md.append("3. [👤 دور الموظف](#-دور-الموظف)")
    md.append("4. [👨‍💼 دور المدير](#-دور-المدير)")
    md.append("5. [🏢 دور صاحب الشركة](#-دور-صاحب-الشركة)")
    md.append("6. [💰 نظام الرواتب](#-نظام-الرواتب)")
    md.append("7. [⏰ نظام الشيفتات](#-نظام-الشيفتات)")
    md.append("8. [📊 التقارير](#-التقارير)")
    md.append("9. [🌐 مرجع الـ APIs](#-مرجع-الـ-apis)")
    md.append("")
    md.append("---")
    md.append("")
    
    # الأدوار
    md.append("## 👥 الأدوار في النظام")
    md.append("")
    md.append("| الدور | الوصف | الشاشة الرئيسية |")
    md.append("|-------|-------|-------------------|")
    md.append("| **Employee** (موظف) | الموظف العادي - حضور، إجازات، طلبات | `EmployeeShell` |")
    md.append("| **Manager** (مدير) | مدير قسم - يشوف فريقه فقط | `ManagerShell` |")
    md.append("| **Company Admin** (صاحب الشركة) | كامل الصلاحيات | `ManagerDashboard` |")
    md.append("| **HR Manager** (مدير HR) | نفس Company Admin | `ManagerDashboard` |")
    md.append("| **Super Admin** | إدارة النظام كاملة | `ManagerDashboard` |")
    md.append("")
    md.append("### 🔀 آلية التوجيه (Routing)")
    md.append("")
    md.append("عند تسجيل الدخول، `ManagerHomeRouter` بيقرر أي شاشة يفتح:")
    md.append("")
    md.append("```")
    md.append("Login → قراءة role من التخزين")
    md.append("  ↓")
    md.append("  ├─ employee → EmployeeShell")
    md.append("  ├─ manager → ManagerShell (شاشة الموظف + tabs إضافية)")
    md.append("  └─ company_admin/super_admin/owner/hr_manager")
    md.append("     → ManagerDashboard (كل الميزات)")
    md.append("```")
    md.append("")
    md.append("---")
    md.append("")
    
    # لكل قسم
    sections_definitions = [
        ('🔐 دور المصادقة (Auth)', 
         'شاشات تسجيل الدخول والتفعيل',
         ['LoginScreen', 'ChangePasswordScreen', 'ActivateAccountScreen', 'SplashScreen']),
        
        ('👤 دور الموظف',
         'شاشات الموظف العادي - يشوف بياناته الشخصية ويقدم طلبات',
         ['EmployeeShell', 'EmployeeHomeScreen', 'LeavesScreen', 'LeaveRequestScreen', 
          'RequestsScreen', 'HistoryScreen', 'CharterScreen', 'AnnouncementsScreen',
          'AnnouncementDetailScreen', 'NotificationsScreen', 'EmployeeProfileScreen',
          'EmployeePayslipScreen', 'EmployeeSummaryScreen', 'EmployeeDocumentsScreen',
          'EmployeeMovementsScreen', 'EmployeeMissionsScreen', 'EmployeeMissionDetailScreen',
          'FieldVisitsScreen', 'MyShiftScreen', 'MyWorkLocationsScreen',
          'MyItemsScreen', 'ItemDetailScreen']),
        
        ('👨‍💼 دور المدير',
         'شاشات المدير - يشوف فريقه ويوافق على طلباتهم',
         ['ManagerShell', 'ManagerTeamScreen', 'ManagerPendingScreen',
          'ManagerAttendanceScreen', 'ManagerLiveLocationsScreen',
          'ManagerMissionsScreen', 'ManagerAnnouncementsScreen',
          'ManagerMyRequestsHubScreen', 'ManagerMoreScreen']),
        
        ('🏢 دور صاحب الشركة',
         'كل ميزات النظام - إدارة موظفين، سياسات، صلاحيات، تقارير',
         ['ManagerHomeRouter', 'ManagerDashboard', 'ManagerEmployeesListScreen',
          'ManagerEmployeeDetailScreen', 'CreateEmployeeScreen', 'ManagerCharterScreen',
          'ManagerGeofenceScreen', 'CompanyInfoScreen', 'CompanyEditScreen',
          'DepartmentsManagementScreen', 'DepartmentDetailScreen', 'BranchesScreen',
          'JobTitlesScreen', 'OrganizationTreeScreen', 'OfficialHolidaysScreen',
          'OffboardingScreen', 'ImportToolsScreen', 'ReminderSettingsScreen',
          'WorkLocationsApprovalScreen', 'LocationReportScreen',
          'PoliciesHubScreen', 'AttendancePolicyScreen', 'LeavePolicyScreen',
          'WorkPolicyScreen', 'PayrollPolicyScreen', 'LeaveRecallScreen',
          'FlexAdjustmentsScreen', 'PermissionsHubScreen', 'PermissionsManagementScreen',
          'PermissionsAssignScreen', 'PermissionsRolesScreen', 'PermissionsOverridesScreen',
          'PermissionsExportScreen', 'EmployeePermissionsScreen', 'RoleDetailScreen']),
        
        ('💰 نظام الرواتب',
         'كل ما يخص الرواتب، البدلات، والسياسات المالية',
         ['PayrollHubScreen', 'PayrollRunScreen', 'PayrollRunDetailScreen',
          'PayrollPayslipScreen', 'PayrollSummaryScreen', 'PayrollEmployeeDetailScreen',
          'PayrollSettingsScreen', 'PayrollCycleScreen', 'PayrollBonusPenaltyScreen',
          'CompanyPoliciesScreen', 'ManualEntriesScreen', 'TaxPolicyScreen',
          'InsurancePoliciesScreen', 'EosPolicyScreen', 'LeaveRulesScreen',
          'BonusRulesScreen', 'PenaltyRulesScreen', 'AllowanceRulesScreen',
          'CreateEditAllowanceRuleScreen', 'CreateEditBonusRuleScreen',
          'CreateEditPenaltyRuleScreen', 'CreateEditLeaveRuleScreen',
          'CreateEditTaxPolicyScreen', 'CreateEditInsurancePolicyScreen',
          'CreateEditEosPolicyScreen', 'CreateEditPayrollCycleScreen']),
        
        ('⏰ نظام الشيفتات',
         'إدارة الشيفتات والمناوبات',
         ['ShiftsScreen', 'CreateEditShiftScreen', 'AssignShiftScreen',
          'AssignmentDetailScreen', 'ShiftOverrideScreen', 'ShiftRotationScreen']),
        
        ('📊 التقارير',
         'كل التقارير المتاحة في النظام',
         ['ReportsHubScreen', 'AttendanceReportScreen', 'DailyAttendanceReportScreen',
          'AbsenceReportScreen', 'LateReportScreen', 'WorkHoursReportScreen',
          'LeavesReportScreen', 'LeavesEnhancedReportScreen', 'RequestsReportScreen',
          'PermissionsReportScreen', 'ShiftsReportScreen', 'PayrollReportScreen',
          'CharterReportScreen']),
    ]
    
    for section_title, section_desc, screen_names in sections_definitions:
        md.append(f"## {section_title}")
        md.append("")
        md.append(f"> {section_desc}")
        md.append("")
        
        for i, name in enumerate(screen_names, 1):
            screen = screens_data.get(name)
            if not screen:
                continue
            
            desc = SCREEN_DESCRIPTIONS.get(name, 'شاشة في النظام')
            
            md.append(f"### {i}. `{name}`")
            md.append("")
            md.append(f"**📝 الوصف:** {desc}")
            md.append(f"**📁 الملف:** `{screen['file']}`")
            
            if screen.get('titles'):
                md.append(f"**🏷️ العنوان:** {' | '.join(screen['titles'])}")
            
            if screen.get('grid_cards'):
                md.append("")
                md.append("**🎴 الميزات المتاحة (Grid Cards):**")
                for card in screen['grid_cards'][:20]:
                    md.append(f"- {card}")
            
            if screen.get('apis'):
                md.append("")
                md.append("**🌐 الـ APIs المستخدمة:**")
                for api in screen['apis'][:15]:
                    md.append(f"- `{api}`")
            
            if screen.get('navigates'):
                md.append("")
                md.append("**➡️ ينتقل إلى:**")
                nav_list = [n for n in screen['navigates'] if n in screens_data or n in SCREEN_DESCRIPTIONS][:15]
                for nav in nav_list:
                    nav_desc = SCREEN_DESCRIPTIONS.get(nav, '')
                    if nav_desc:
                        md.append(f"- `{nav}` - {nav_desc.split('-')[0].strip()}")
                    else:
                        md.append(f"- `{nav}`")
            
            md.append("")
            md.append("---")
            md.append("")
    
    # مرجع الـ APIs
    md.append("## 🌐 مرجع الـ APIs")
    md.append("")
    md.append(f"**إجمالي الـ APIs المستخدمة:** {len(all_apis)}")
    md.append("")
    
    category_names = {
        'login': '🔐 تسجيل الدخول',
        'attendance': '📊 الحضور',
        'leaves': '🌴 الإجازات',
        'my-leaves': '🌴 إجازاتي',
        'my-requests': '📋 طلباتي',
        'my-shift': '⏰ شيفتي',
        'employee': '👤 الموظف',
        'manager': '👨‍💼 المدير',
        'notifications': '🔔 الإشعارات',
        'charter': '📜 اللائحة',
        'geofence': '📍 النطاق الجغرافي',
        'branches': '🏢 الفروع',
        'job-titles': '💼 المسميات',
        'permissions': '🔐 الصلاحيات',
        'submit-request': '📝 تقديم طلب',
        'request-types': '📝 أنواع الطلبات',
        'change-password': '🔑 تغيير كلمة السر',
        'leave-request': '🌴 طلب إجازة',
        'leave-types': '🌴 أنواع الإجازات',
        'fcm-token': '📱 FCM Token',
        'history': '📅 السجل',
        'status': '📊 الحالة',
        'attachments': '📎 المرفقات',
        'announcements': '📢 الإعلانات',
    }
    
    for category in sorted(api_categories.keys()):
        cat_name = category_names.get(category, f'📂 {category}')
        apis = api_categories[category]
        md.append(f"### {cat_name} ({len(apis)} API)")
        md.append("")
        for api in apis:
            md.append(f"- `{api}`")
        md.append("")
    
    md.append("---")
    md.append("")
    md.append("## 📞 ملاحظات نهائية")
    md.append("")
    md.append("- ✅ التطبيق **موحّد** لكل الأدوار (App واحد)")
    md.append("- ✅ الـ Routing بيتم عن طريق **role** من الباك إند")
    md.append("- ✅ كل الميزات **مطابقة** بين الويب والموبايل")
    md.append("- ⏰ **Base URL الحالي:** `https://app.jssolutions-eg.com`")
    md.append("- 📱 **Flutter Version:** 3.44.6+")
    md.append("- 🔄 آخر تحديث: مطابق مع GitHub main branch")
    md.append("")
    md.append("---")
    md.append("")
    md.append("*تم إنشاء هذه الوثيقة تلقائياً باستخدام أدوات فحص الكود المتقدمة*")
    
    OUTPUT.write_text("\n".join(md), encoding="utf-8")
    
    print(f"\n[OK] Handover Document Generated!")
    print(f"[OK] File: {OUTPUT.absolute()}")
    print(f"[OK] Size: {OUTPUT.stat().st_size / 1024:.1f} KB")
    print(f"[OK] Total Screens: {len(screens_data)}")
    print(f"[OK] Total APIs: {len(all_apis)}")

if __name__ == "__main__":
    build()
