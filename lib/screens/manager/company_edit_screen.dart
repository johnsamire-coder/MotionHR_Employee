import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/employee_management_service.dart';
import 'package:motionhr_employee/l10n/l10n.dart';

class CompanyEditScreen extends StatefulWidget {
  final Map<String, dynamic> company;
  const CompanyEditScreen({super.key, required this.company});

  @override
  State<CompanyEditScreen> createState() => _CompanyEditScreenState();
}

class _CompanyEditScreenState extends State<CompanyEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _uploadingLogo = false;
  File? _pickedLogo;

  late TextEditingController _nameAr;
  late TextEditingController _nameEn;
  late TextEditingController _phone;
  late TextEditingController _email;
  late TextEditingController _website;
  late TextEditingController _address;
  late TextEditingController _commercialRegister;
  late TextEditingController _taxNumber;

  @override
  void initState() {
    super.initState();
    final c = widget.company;
    _nameAr             = TextEditingController(text: c['name_ar']?.toString() ?? '');
    _nameEn             = TextEditingController(text: c['name_en']?.toString() ?? '');
    _phone              = TextEditingController(text: c['phone']?.toString() ?? '');
    _email              = TextEditingController(text: c['email']?.toString() ?? '');
    _website            = TextEditingController(text: c['website']?.toString() ?? '');
    _address            = TextEditingController(text: c['address']?.toString() ?? '');
    _commercialRegister = TextEditingController(text: c['commercial_register']?.toString() ?? '');
    _taxNumber          = TextEditingController(text: c['tax_number']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameAr.dispose();
    _nameEn.dispose();
    _phone.dispose();
    _email.dispose();
    _website.dispose();
    _address.dispose();
    _commercialRegister.dispose();
    _taxNumber.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    final file = File(picked.path);
    final sizeBytes = await file.length();
    final sizeMB = sizeBytes / (1024 * 1024);
    final ext = picked.path.split('.').last.toLowerCase();

    final allowedExts = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    if (!allowedExts.contains(ext)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          isAr
              ? '❌ نوع الملف غير مدعوم: .$ext\nالمسموح: JPG / PNG / GIF / WEBP'
              : '❌ Unsupported file type: .$ext\nAllowed: JPG / PNG / GIF / WEBP',
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ));
      return;
    }

    if (sizeMB > 5) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          isAr
              ? '❌ حجم الصورة ${sizeMB.toStringAsFixed(2)} MB\nالحد الأقصى: 5 MB'
              : '❌ Image size ${sizeMB.toStringAsFixed(2)} MB\nMax allowed: 5 MB',
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ));
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        isAr
            ? '✅ الصورة جاهزة (${sizeMB.toStringAsFixed(2)} MB)'
            : '✅ Image ready (${sizeMB.toStringAsFixed(2)} MB)',
      ),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    ));

    setState(() => _pickedLogo = file);
  }

  Future<void> _uploadLogo() async {
    if (_pickedLogo == null) return;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    setState(() => _uploadingLogo = true);
    try {
      await EmployeeManagementService.uploadCompanyLogo(_pickedLogo!.path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? '✅ تم رفع اللوجو بنجاح' : '✅ Logo uploaded successfully'),
        backgroundColor: Colors.green,
      ));
      try {
        final fresh = await EmployeeManagementService.getCompanyInfo();
        if (!mounted) return;
        setState(() {
          widget.company['logo_url'] = fresh['logo_url'];
          _pickedLogo = null;
        });
      } catch (_) {}
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          isAr ? '❌ فشل رفع اللوجو:\n$e' : '❌ Logo upload failed:\n$e',
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 6),
      ));
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    setState(() => _saving = true);
    try {
      final data = {
        'name_ar':             _nameAr.text.trim(),
        'name_en':             _nameEn.text.trim(),
        'phone':               _phone.text.trim(),
        'email':               _email.text.trim(),
        'website':             _website.text.trim(),
        'address':             _address.text.trim(),
        'commercial_register': _commercialRegister.text.trim(),
        'tax_number':          _taxNumber.text.trim(),
      };
      final ok = await EmployeeManagementService.updateCompanyInfo(data);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            isAr ? '✅ تم حفظ البيانات بنجاح' : '✅ Data saved successfully',
          ),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            isAr ? '❌ فشل حفظ البيانات' : '❌ Failed to save data',
          ),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? '❌ خطأ: $e' : '❌ Error: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final logoUrl = widget.company['logo_url']?.toString() ?? '';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(isAr ? 'تعديل بيانات الشركة' : isAr ? 'تعديل بيانات الشركة' : 'Edit Company Info'),
          backgroundColor: const Color(0xFF6A1B9A),
          foregroundColor: Colors.white,
          actions: [
            if (_saving)
              const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: context.l10n.save,
                onPressed: _save,
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Logo picker ──
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickLogo,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF6A1B9A),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _pickedLogo != null
                              ? Image.file(_pickedLogo!, fit: BoxFit.cover)
                              : logoUrl.isNotEmpty
                                  ? Image.network(
                                      logoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.business,
                                        size: 50,
                                        color: Color(0xFF6A1B9A),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.business,
                                      size: 50,
                                      color: Color(0xFF6A1B9A),
                                    ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: _pickLogo,
                          icon: const Icon(Icons.image, size: 16),
                          label: Text(isAr ? 'اختر صورة' : 'Choose Image'),
                        ),
                        if (_pickedLogo != null) ...[
                          const SizedBox(width: 8),
                          _uploadingLogo
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : ElevatedButton.icon(
                                  onPressed: _uploadLogo,
                                  icon: const Icon(Icons.upload, size: 16),
                                  label: Text(isAr ? 'رفع اللوجو' : 'Upload Logo'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6A1B9A),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Company name card ──
              _buildCard(
                context.l10n.companyInfo,
                Icons.business,
                Colors.purple,
                [
                  _field(
                    _nameAr,
                    isAr ? 'اسم الشركة بالعربي *' : 'Company Name (Arabic) *',
                    Icons.translate,
                    required: true,
                    isAr: isAr,
                  ),
                  _field(
                    _nameEn,
                    isAr ? 'اسم الشركة بالإنجليزي' : 'Company Name (English)',
                    Icons.translate,
                    isAr: isAr,
                  ),
                ],
              ),

              // ── Contact card ──
              _buildCard(
                isAr ? 'بيانات الاتصال' : 'Contact Info',
                Icons.phone,
                Colors.blue,
                [
                  _field(
                    _phone,
                    isAr ? 'الهاتف' : 'Phone',
                    Icons.phone,
                    isAr: isAr,
                  ),
                  _field(
                    _email,
                    isAr ? 'البريد الإلكتروني' : 'Email',
                    Icons.email,
                    isAr: isAr,
                  ),
                  _field(
                    _website,
                    isAr ? 'الموقع الإلكتروني' : 'Website',
                    Icons.language,
                    isAr: isAr,
                  ),
                  _field(
                    _address,
                    context.l10n.address,
                    Icons.location_on,
                    maxLines: 2,
                    isAr: isAr,
                  ),
                ],
              ),

              // ── Legal card ──
              _buildCard(
                isAr ? 'البيانات القانونية' : 'Legal Info',
                Icons.gavel,
                Colors.green,
                [
                  _field(
                    _commercialRegister,
                    isAr ? 'السجل التجاري' : 'Commercial Register',
                    Icons.assignment,
                    isAr: isAr,
                  ),
                  _field(
                    _taxNumber,
                    isAr ? 'الرقم الضريبي' : 'Tax Number',
                    Icons.receipt_long,
                    isAr: isAr,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Save button ──
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save),
                  label: Text(
                    isAr ? 'حفظ البيانات' : 'Save Data',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A1B9A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
    bool isAr = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty)
                ? (isAr ? 'هذا الحقل مطلوب' : 'This field is required')
                : null
            : null,
      ),
    );
  }
}