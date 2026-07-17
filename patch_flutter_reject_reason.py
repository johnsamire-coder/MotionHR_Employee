from pathlib import Path

p = Path("lib/main.dart")
content = p.read_text(encoding="utf-8-sig")

# الكود القديم — زر الرفض المباشر في ManagerPendingScreen
old_reject = """          Expanded(child: ElevatedButton.icon(onPressed: () => _action(item, 'reject'), icon: const Icon(Icons.close), label: const Text('رفض'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white)))])])));"""

# الكود الجديد — زر الرفض مع Dialog
new_reject = """          Expanded(child: ElevatedButton.icon(onPressed: () => _showRejectDialog(item), icon: const Icon(Icons.close), label: const Text('رفض'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white)))])])));"""

# دالة _showRejectDialog
reject_dialog_method = """
  Future<void> _showRejectDialog(dynamic item) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Row(children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Text('سبب الرفض'),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('يرجى كتابة سبب الرفض (إجباري)'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'اكتب السبب هنا...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonCtrl.text.trim().isEmpty) return;
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('تأكيد الرفض'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && reasonCtrl.text.trim().isNotEmpty) {
      await _action(item, 'reject', notes: reasonCtrl.text.trim());
    }
    reasonCtrl.dispose();
  }

"""

# تعديل دالة _action لتقبل notes
old_action = """  Future<void> _action(dynamic item, String action) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    try {
      final res = await http.post(Uri.parse('$kBaseUrl/attendance/api/mobile/manager/action/'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
          body: jsonEncode({'id': item['id'], 'type': item['type'], 'action': action}));
      final data = jsonDecode(res.body);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'تم'))); fetchUnreadCount(); }
      _load();
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث: $e'))); }
  }"""

new_action = """  Future<void> _action(dynamic item, String action, {String notes = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    try {
      final body = {'id': item['id'], 'type': item['type'], 'action': action};
      if (notes.isNotEmpty) body['notes'] = notes;
      final res = await http.post(Uri.parse('$kBaseUrl/attendance/api/mobile/manager/action/'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
          body: jsonEncode(body));
      final data = jsonDecode(res.body);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'تم'))); fetchUnreadCount(); }
      _load();
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث: $e'))); }
  }"""

# ─── تطبيق الباتشات ───
ok1 = ok2 = ok3 = False

if "_showRejectDialog" in content:
    print("⚠️ reject dialog موجود بالفعل")
    ok1 = True
elif old_reject in content:
    content = content.replace(old_reject, new_reject, 1)
    # أضف _showRejectDialog قبل _action
    content = content.replace(old_action, reject_dialog_method + new_action, 1)
    print("✅ تم تعديل زر الرفض ليفتح Dialog")
    ok1 = True
else:
    print("❌ لم يتم العثور على زر الرفض القديم")

if old_action in content:
    content = content.replace(old_action, new_action, 1)
    print("✅ تم تعديل دالة _action لتقبل notes")
    ok2 = True
else:
    if "String notes = ''" in content:
        print("⚠️ دالة _action محدّثة بالفعل")
        ok2 = True
    else:
        print("❌ لم يتم العثور على دالة _action")

p.write_text(content, encoding="utf-8-sig")
print("✅ تم حفظ main.dart")

# Verification
checks = [
    ("_showRejectDialog موجود", "_showRejectDialog" in content),
    ("notes في _action", "String notes = ''" in content),
    ("Dialog بيطلب السبب", "سبب الرفض" in content),
]

print("\nVerification:")
for label, ok in checks:
    print(("✅" if ok else "❌"), label)