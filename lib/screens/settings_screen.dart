import 'package:flutter/material.dart';
import '../services/language_service.dart';
import 'package:motionhr_employee/l10n/l10n.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentLang = 'ar';

  @override
  void initState() {
    super.initState();
    _currentLang = LanguageService.currentLanguage;
  }

  Future<void> _changeLang(String lang) async {
    await LanguageService.changeLanguage(lang);
    if (!mounted) return;
    setState(() => _currentLang = lang);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(lang == 'ar' ? 'تم تغيير اللغة إلى العربية' : 'Language changed to English'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = LanguageService.isArabic;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(isAr ? context.l10n.settings : context.l10n.settings),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── قسم اللغة ──
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1976D2).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.language, color: Color(0xFF1976D2)),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr ? context.l10n.language : 'Language',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 2),
                            Text(
                              isAr ? 'اختر لغة التطبيق' : 'Choose app language',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1),
                RadioListTile<String>(
                  value: 'ar',
                  groupValue: _currentLang,
                  onChanged: (v) => _changeLang(v!),
                  activeColor: const Color(0xFF1976D2),
                  title: Row(
                    children: [
                      Text('🇸🇦', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text(context.l10n.arabic, style: TextStyle(fontSize: 15)),
                    ],
                  ),
                ),
                RadioListTile<String>(
                  value: 'en',
                  groupValue: _currentLang,
                  onChanged: (v) => _changeLang(v!),
                  activeColor: const Color(0xFF1976D2),
                  title: Row(
                    children: [
                      Text('🇬🇧', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text('English', style: TextStyle(fontSize: 15)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // ── معلومات التطبيق ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.info, color: Colors.purple),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'حول التطبيق' : 'About',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          const Text('MotionHR v1.0.0', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}