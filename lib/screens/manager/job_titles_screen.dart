import 'dart:convert';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/api_client.dart';

class JobTitlesScreen extends StatefulWidget {
  const JobTitlesScreen({super.key});

  @override
  State<JobTitlesScreen> createState() => _JobTitlesScreenState();
}

class _JobTitlesScreenState extends State<JobTitlesScreen> {
  List<dynamic> _titles = [];
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
        Uri.parse('$kBaseUrl/attendance/api/mobile/manager/job-titles/'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _titles = data['job_titles'] ?? data['jobTitles'] ?? data ?? [];
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
    final descCtrl = TextEditingController();
    bool saving = false;
    bool isManager = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(isAr ? 'إضافة مسمى وظيفي' : 'Add Job Title'),
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
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: isAr ? 'الوصف' : 'Description',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: isManager,
                    onChanged: (v) => setS(() => isManager = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      isAr
                          ? 'هل هذا المسمى مدير؟'
                          : 'Is this job title a manager?',
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
                            Uri.parse(
                                '$kBaseUrl/attendance/api/mobile/manager/job-titles/'),
                            body: jsonEncode({
                              'name_ar': nameArCtrl.text.trim(),
                              'name_en': nameEnCtrl.text.trim(),
                              'description': descCtrl.text.trim(),
                              'is_manager': isManager,
                            }),
                          );
                          final data = jsonDecode(res.body);
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (res.statusCode == 200 || res.statusCode == 201) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(isAr
                                  ? 'تم إنشاء المسمى بنجاح'
                                  : 'Job title created successfully'),
                              backgroundColor: Colors.green,
                            ));
                            _load();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(data['message'] ??
                                  (isAr ? 'فشل الإنشاء' : 'Failed')),
                              backgroundColor: Colors.red,
                            ));
                          }
                        } catch (_) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content:
                                Text(isAr ? 'خطأ في الاتصال' : 'Connection error'),
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
    if (_search.isEmpty) return _titles;
    return _titles.where((t) {
      final ar = (t['name_ar'] ?? '').toString().toLowerCase();
      final en = (t['name_en'] ?? '').toString().toLowerCase();
      return ar.contains(_search.toLowerCase()) ||
          en.contains(_search.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAr ? 'المسميات الوظيفية' : 'Job Titles'),
          backgroundColor: kManagerColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: isAr ? 'إضافة مسمى' : 'Add Title',
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
                    // إحصائية
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kManagerColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: kManagerColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.work,
                              color: kManagerColor, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            '${_titles.length} ${isAr ? 'مسمى وظيفي' : 'job title(s)'}',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: kManagerColor),
                          ),
                        ],
                      ),
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
                              const Icon(Icons.work_off,
                                  size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                _search.isNotEmpty
                                    ? (isAr
                                        ? 'لا توجد نتائج'
                                        : 'No results')
                                    : (isAr
                                        ? 'لا توجد مسميات بعد'
                                        : 'No job titles yet'),
                                style: const TextStyle(color: Colors.grey),
                              ),
                              if (_search.isEmpty) ...[
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _showCreateDialog,
                                  icon: const Icon(Icons.add),
                                  label: Text(isAr
                                      ? 'إضافة أول مسمى'
                                      : 'Add First Title'),
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
                      ..._filtered.map((t) => _titleCard(t, isAr)),
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

  Widget _titleCard(dynamic t, bool isAr) {
    final name = isAr
        ? (t['name_ar'] ?? t['name_en'] ?? '')
        : (t['name_en'] ?? t['name_ar'] ?? '');
    final subName =
        isAr ? (t['name_en'] ?? '') : (t['name_ar'] ?? '');
    final isActive = t['is_active'] != false;
    final desc = (t['description'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kManagerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.work, color: kManagerColor, size: 22),
            ),
            const SizedBox(width: 12),
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
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
      ),
    );
  }
}