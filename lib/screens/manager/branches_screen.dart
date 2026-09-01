import 'dart:convert';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/api_client.dart';

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key});

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  List<dynamic> _branches = [];
  bool _loading = true;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final res = await ApiClient.get(
        Uri.parse('$kBaseUrl/attendance/api/mobile/manager/branches/'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _branches = data['branches'] ?? data ?? [];
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _showCreateDialog() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final nameArCtrl = TextEditingController();
    final nameEnCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(isAr ? 'إضافة فرع جديد' : 'Add New Branch'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameArCtrl,
                    decoration: InputDecoration(
                      labelText: isAr ? 'الاسم بالعربي *' : 'Arabic Name *',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameEnCtrl,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: isAr ? 'الاسم بالإنجليزي' : 'English Name',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressCtrl,
                    decoration: InputDecoration(
                      labelText: isAr ? 'العنوان' : 'Address',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    textDirection: TextDirection.ltr,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: isAr ? 'الهاتف' : 'Phone',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: Text(isAr ? 'إلغاء' : 'Cancel'),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (nameArCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(isAr
                                ? 'الاسم بالعربي مطلوب'
                                : 'Arabic name is required'),
                            backgroundColor: Colors.red,
                          ));
                          return;
                        }
                        setS(() => saving = true);
                        try {
                          final res = await ApiClient.post(
                            Uri.parse('$kBaseUrl/attendance/api/mobile/manager/branches/'),
                            body: jsonEncode({
                              'name_ar': nameArCtrl.text.trim(),
                              'name_en': nameEnCtrl.text.trim(),
                              'address': addressCtrl.text.trim(),
                              'phone': phoneCtrl.text.trim(),
                            }),
                          );
                          final data = jsonDecode(res.body);
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (res.statusCode == 200 || res.statusCode == 201) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(isAr
                                  ? 'تم إنشاء الفرع بنجاح'
                                  : 'Branch created successfully'),
                              backgroundColor: Colors.green,
                            ));
                            _load();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  data['message'] ?? (isAr ? 'فشل الإنشاء' : 'Failed')),
                              backgroundColor: Colors.red,
                            ));
                          }
                        } catch (_) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(isAr ? 'خطأ في الاتصال' : 'Connection error'),
                            backgroundColor: Colors.red,
                          ));
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kManagerColor,
                  foregroundColor: Colors.white,
                ),
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(isAr ? 'إنشاء' : 'Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<dynamic> get _filtered {
    if (_search.isEmpty) return _branches;
    return _branches.where((b) {
      final ar = (b['name_ar'] ?? '').toString().toLowerCase();
      final en = (b['name_en'] ?? '').toString().toLowerCase();
      return ar.contains(_search.toLowerCase()) ||
          en.contains(_search.toLowerCase());
    }).toList();
  }

  int get _totalEmployees {
    int total = 0;
    for (final b in _branches) {
      total += ((b['employee_count'] ?? 0) as num).toInt();
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAr ? 'الفروع' : 'Branches'),
          backgroundColor: kManagerColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: isAr ? 'إضافة فرع' : 'Add Branch',
              onPressed: _showCreateDialog,
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // إحصائيات
                    Row(
                      children: [
                        _statCard(
                          isAr ? 'إجمالي الفروع' : 'Total Branches',
                          '${_branches.length}',
                          Icons.location_city,
                          Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        _statCard(
                          isAr ? 'إجمالي الموظفين' : 'Total Employees',
                          '$_totalEmployees',
                          Icons.people,
                          const Color(0xFF10B981),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // بحث
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _search = v),
                      decoration: InputDecoration(
                        hintText: isAr ? 'بحث...' : 'Search...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: _search.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _search = '');
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // القائمة
                    if (_filtered.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              const Icon(Icons.location_off,
                                  size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                _search.isNotEmpty
                                    ? (isAr ? 'لا توجد نتائج' : 'No results')
                                    : (isAr ? 'لا توجد فروع بعد' : 'No branches yet'),
                                style: const TextStyle(color: Colors.grey),
                              ),
                              if (_search.isEmpty) ...[
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _showCreateDialog,
                                  icon: const Icon(Icons.add),
                                  label: Text(isAr ? 'إضافة أول فرع' : 'Add First Branch'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kManagerColor,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    else
                      ..._filtered.map((b) => _branchCard(b, isAr)),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreateDialog,
          backgroundColor: kManagerColor,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(label,
                    style:
                        TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _branchCard(dynamic b, bool isAr) {
    final name =
        isAr ? (b['name_ar'] ?? b['name_en'] ?? '') : (b['name_en'] ?? b['name_ar'] ?? '');
    final subName =
        isAr ? (b['name_en'] ?? '') : (b['name_ar'] ?? '');
    final isMain = b['is_main'] == true;
    final isActive = b['is_active'] != false;
    final empCount = ((b['employee_count'] ?? 0) as num).toInt();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kManagerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_city,
                      color: kManagerColor, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      if (subName.isNotEmpty)
                        Text(subName,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isMain)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.amber.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                size: 12, color: Colors.amber),
                            const SizedBox(width: 3),
                            Text(
                              isAr ? 'رئيسي' : 'Main',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive
                            ? (isAr ? 'نشط' : 'Active')
                            : (isAr ? 'غير نشط' : 'Inactive'),
                        style: TextStyle(
                          fontSize: 11,
                          color: isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if ((b['address'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      b['address'],
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if ((b['phone'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    b['phone'],
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontFamily: 'monospace'),
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.people, size: 16, color: kManagerColor),
                const SizedBox(width: 4),
                Text(
                  '$empCount ${isAr ? 'موظف' : 'employee(s)'}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kManagerColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
