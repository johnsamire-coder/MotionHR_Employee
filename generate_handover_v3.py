"""
MotionHR - Complete Handover v3 (with Background Services)
"""
import json
import re
from pathlib import Path
from collections import defaultdict
from datetime import datetime

MOBILE_DIR = Path("lib")
OUTPUT = Path("MOTIONHR_HANDOVER_V3.md")

# ============================================
# اكتشاف Background Services
# ============================================

def analyze_service_file(fp):
    """يحلل service file ويطلع معلوماته"""
    try:
        text = fp.read_text(encoding="utf-8", errors="ignore")
    except:
        return None
    
    info = {
        'file': str(fp).replace('\\', '/'),
        'name': fp.stem,
        'timers': [],
        'methods': [],
        'apis': set(),
        'features': [],
        'is_background': False,
        'is_periodic': False,
        'permissions_needed': [],
    }
    
    # كشف Timer
    timer_matches = re.findall(r"Timer\.periodic\s*\(\s*(?:const\s+)?Duration\s*\(([^)]+)\)", text)
    for m in timer_matches:
        info['timers'].append(m.strip())
        info['is_periodic'] = True
        info['is_background'] = True
    
    # كشف الـ methods العامة
    method_matches = re.findall(r"static\s+(?:Future<[\w?]+>|void|bool)\s+(\w+)\s*\(", text)
    info['methods'] = list(set(method_matches))
    
    # كشف الـ APIs
    api_matches = re.findall(r"['\"](?:\$_?baseUrl)?(/(?:attendance|leaves|employee|hr|api|accounts|companies|subscriptions|requests|notifications)/[a-zA-Z0-9_\-/${{}}.]+)", text)
    for api in api_matches:
        clean = api.split('?')[0].split("'")[0].split('"')[0]
        clean = re.sub(r'\$\{[^}]+\}', '{var}', clean)
        clean = re.sub(r'\$\w+', '{var}', clean)
        if len(clean) > 4:
            info['apis'].add(clean.rstrip('/'))
    info['apis'] = sorted(info['apis'])
    
    # كشف الميزات
    if 'BackgroundFetch' in text or 'background_fetch' in text:
        info['features'].append('BackgroundFetch (يعمل حتى مع إغلاق التطبيق)')
        info['is_background'] = True
    if 'Geolocator' in text:
        info['features'].append('Geolocator (تحديد الموقع)')
        info['permissions_needed'].append('Location')
    if 'FirebaseMessaging' in text or 'FCM' in text:
        info['features'].append('Firebase Cloud Messaging (Push Notifications)')
        info['permissions_needed'].append('Notifications')
    if 'flutter_local_notifications' in text or 'FlutterLocalNotifications' in text:
        info['features'].append('Local Notifications (تنبيهات محلية)')
    if 'SharedPreferences' in text:
        info['features'].append('SharedPreferences (تخزين محلي)')
    if 'OfflineQueue' in text or 'offline_queue' in text.lower():
        info['features'].append('Offline Queue (طابور طلبات أوفلاين)')
    if 'WebSocket' in text:
        info['features'].append('WebSocket (اتصال مباشر)')
    
    return info

def extract_features_from_main(text):
    """يستخرج الميزات الخفية من main.dart"""
    features = {
        'initialization': [],
        'background_tasks': [],
        'auto_actions': [],
        'firebase': [],
    }
    
    # Firebase
    if 'FirebaseMessaging' in text:
        features['firebase'].append('Firebase Cloud Messaging')
    if 'firebaseBackgroundHandler' in text:
        features['firebase'].append('Firebase Background Handler (يعمل حتى مع إغلاق التطبيق)')
    if 'onBackgroundMessage' in text:
        features['firebase'].append('Background Message Handler')
    
    # Background Tracking
    if 'configureBackgroundTracking' in text:
        features['background_tasks'].append('Background Tracking (تتبع خلفي)')
    if 'startBackgroundTracking' in text:
        features['background_tasks'].append('Auto Start Tracking on Login')
    if 'stopBackgroundTracking' in text:
        features['background_tasks'].append('Stop Tracking on Logout')
    
    # Auto Actions
    if 'AutoCheckinService.startMonitoring' in text:
        features['auto_actions'].append('Auto Check-in Monitoring (بدء المراقبة عند الدخول)')
    if 'LocationTrackingService.startTracking' in text:
        features['auto_actions'].append('Location Tracking (تتبع الموقع كل ساعة)')
    if 'LocationTrackingService.stopTracking' in text:
        features['auto_actions'].append('Stop Location Tracking')
    
    return features

def build():
    print("[BUILD] Analyzing services...")
    
    services_data = []
    services_root = MOBILE_DIR / "services"
    if services_root.exists():
        for fp in sorted(services_root.rglob("*.dart")):
            data = analyze_service_file(fp)
            if data:
                services_data.append(data)
    
    # main.dart features
    main_text = (MOBILE_DIR / "main.dart").read_text(encoding="utf-8", errors="ignore")
    main_features = extract_features_from_main(main_text)
    
    # background_service.dart
    bg_file = MOBILE_DIR / "background_service.dart"
    bg_info = None
    if bg_file.exists():
        bg_info = analyze_service_file(bg_file)
    
    # ============================================
    # بناء التقرير
    # ============================================
    md = []
    md.append("# 🎯 MotionHR - وثيقة الميزات الشاملة (v3)")
    md.append("")
    md.append(f"**تاريخ الإصدار:** {datetime.now().strftime('%Y-%m-%d %H:%M')}")
    md.append("**نطاق التغطية:** UI + Background Services + Auto Actions")
    md.append("")
    md.append("---")
    md.append("")
    
    # ============================================
    # قسم Background Services (الجديد!)
    # ============================================
    md.append("## 🔒 الميزات الخفية / Background Services")
    md.append("")
    md.append("> **مهم:** دي ميزات بتشتغل في الخلفية بدون تفاعل من المستخدم")
    md.append("")
    
    # Firebase
    if main_features['firebase']:
        md.append("### 🔥 Firebase Cloud Messaging (FCM)")
        md.append("")
        md.append("**الوظيفة:** استقبال Push Notifications من السيرفر")
        md.append("")
        md.append("**الميزات:**")
        for f in main_features['firebase']:
            md.append(f"- ✅ {f}")
        md.append("")
        md.append("**Trigger:** يبدأ تلقائياً عند فتح التطبيق")
        md.append("**Behavior:** يستقبل إشعارات حتى لو التطبيق مقفول")
        md.append("")
        md.append("---")
        md.append("")
    
    # Background Tracking
    if main_features['background_tasks']:
        md.append("### 📍 Background Location Tracking")
        md.append("")
        md.append("**الوظيفة:** تتبع موقع الموظف بشكل دوري")
        md.append("")
        md.append("**الميزات:**")
        for f in main_features['background_tasks']:
            md.append(f"- ✅ {f}")
        md.append("")
        md.append("**Trigger:** يبدأ بعد Login وينتهي عند Logout")
        md.append("**Frequency:** كل ساعة (Timer.periodic)")
        md.append("**Permissions:** Location (Always)")
        md.append("")
        md.append("---")
        md.append("")
    
    # Auto Actions
    if main_features['auto_actions']:
        md.append("### ⚡ Auto Actions (الإجراءات التلقائية)")
        md.append("")
        for f in main_features['auto_actions']:
            md.append(f"- ✅ {f}")
        md.append("")
        md.append("---")
        md.append("")
    
    # ============================================
    # الـ Services التفصيلية
    # ============================================
    md.append("## ⚙️ خدمات النظام (Services)")
    md.append("")
    md.append(f"**العدد الإجمالي:** {len(services_data)} service")
    md.append("")
    
    # Background Services first
    bg_services = [s for s in services_data if s.get('is_background') or s.get('is_periodic')]
    other_services = [s for s in services_data if not s.get('is_background') and not s.get('is_periodic')]
    
    if bg_services:
        md.append(f"### 🔴 Background Services (بتشتغل في الخلفية) - {len(bg_services)}")
        md.append("")
        for svc in bg_services:
            md.append(f"#### 📦 `{svc['name']}.dart`")
            md.append(f"**📁 الملف:** `{svc['file']}`")
            
            if svc.get('features'):
                md.append("")
                md.append("**🎯 الميزات:**")
                for f in svc['features']:
                    md.append(f"- ✅ {f}")
            
            if svc.get('timers'):
                md.append("")
                md.append("**⏰ Timers (توقيتات):**")
                for t in svc['timers']:
                    md.append(f"- `{t}`")
            
            if svc.get('permissions_needed'):
                md.append("")
                md.append(f"**🔐 الصلاحيات المطلوبة:** {', '.join(svc['permissions_needed'])}")
            
            if svc.get('methods'):
                md.append("")
                md.append("**🔧 الـ Methods:**")
                for m in svc['methods'][:10]:
                    md.append(f"- `{m}()`")
            
            if svc.get('apis'):
                md.append("")
                md.append("**🌐 APIs:**")
                for api in svc['apis'][:10]:
                    md.append(f"- `{api}`")
            
            md.append("")
            md.append("---")
            md.append("")
    
    if other_services:
        md.append(f"### 🔵 Regular Services - {len(other_services)}")
        md.append("")
        for svc in other_services:
            md.append(f"#### `{svc['name']}.dart`")
            md.append(f"**📁 الملف:** `{svc['file']}`")
            
            if svc.get('features'):
                md.append("**🎯 الميزات:**")
                for f in svc['features']:
                    md.append(f"- {f}")
            
            if svc.get('methods'):
                md.append(f"**🔧 Methods:** {', '.join([f'`{m}`' for m in svc['methods'][:8]])}")
            
            if svc.get('apis'):
                md.append(f"**🌐 APIs:** {len(svc['apis'])}")
                for api in svc['apis'][:5]:
                    md.append(f"  - `{api}`")
            
            md.append("")
    
    # ============================================
    # background_service.dart
    # ============================================
    if bg_info:
        md.append("---")
        md.append("")
        md.append("## 🔧 background_service.dart (الملف الرئيسي للـ Background)")
        md.append("")
        md.append(f"**📁 الملف:** `{bg_info['file']}`")
        
        if bg_info.get('methods'):
            md.append("")
            md.append("**🔧 Methods:**")
            for m in bg_info['methods']:
                md.append(f"- `{m}()`")
        
        if bg_info.get('features'):
            md.append("")
            md.append("**🎯 الميزات:**")
            for f in bg_info['features']:
                md.append(f"- {f}")
        
        md.append("")
    
    # ============================================
    # Summary
    # ============================================
    md.append("---")
    md.append("")
    md.append("## 📊 الإحصائيات النهائية")
    md.append("")
    md.append("| القسم | العدد |")
    md.append("|-------|-------|")
    md.append(f"| Background Services | {len(bg_services)} |")
    md.append(f"| Regular Services | {len(other_services)} |")
    md.append(f"| Firebase Features | {len(main_features['firebase'])} |")
    md.append(f"| Background Tasks | {len(main_features['background_tasks'])} |")
    md.append(f"| Auto Actions | {len(main_features['auto_actions'])} |")
    md.append("")
    
    OUTPUT.write_text("\n".join(md), encoding="utf-8")
    
    print(f"\n[OK] Report: {OUTPUT.absolute()}")
    print(f"[OK] Size: {OUTPUT.stat().st_size / 1024:.1f} KB")
    print(f"[OK] Background Services: {len(bg_services)}")
    print(f"[OK] Regular Services: {len(other_services)}")
    print(f"[OK] Firebase Features: {len(main_features['firebase'])}")
    print(f"[OK] Background Tasks: {len(main_features['background_tasks'])}")
    print(f"[OK] Auto Actions: {len(main_features['auto_actions'])}")

if __name__ == "__main__":
    build()
