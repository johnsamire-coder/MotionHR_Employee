import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/language_service.dart';
import 'package:motionhr_employee/l10n/l10n.dart';

class FirstLaunchLanguageScreen extends StatefulWidget {
  final VoidCallback onDone;

  const FirstLaunchLanguageScreen({super.key, required this.onDone});

  @override
  State<FirstLaunchLanguageScreen> createState() => _FirstLaunchLanguageScreenState();
}

class _FirstLaunchLanguageScreenState extends State<FirstLaunchLanguageScreen> {
  String? _selected;

  Future<void> _confirm() async {
    if (_selected == null) return;
    await LanguageService.changeLanguage(_selected!);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_launch_done', true);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF42A5F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(height: 40),

                // ── لوجو ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.language, size: 70, color: Colors.white),
                ),
                SizedBox(height: 24),

                // ── عناوين مزدوجة ──
                const Text(
                  'اختر لغتك',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                const Text(
                  'Choose your language',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),

                SizedBox(height: 50),

                // ── العربية ──
                _langCard(
                  code: 'ar',
                  flag: '🇸🇦',
                  name: context.l10n.arabic,
                  subtitle: 'Arabic',
                ),
                SizedBox(height: 16),

                // ── الإنجليزية ──
                _langCard(
                  code: 'en',
                  flag: '🇬🇧',
                  name: 'English',
                  subtitle: 'إنجليزي',
                ),

                const Spacer(),

                // ── زر التأكيد ──
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selected == null ? null : _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0D47A1),
                      disabledBackgroundColor: Colors.white.withValues(alpha: 0.3),
                      disabledForegroundColor: Colors.white70,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _selected == 'en' ? 'Continue' : context.l10n.continueBtn,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _langCard({
    required String code,
    required String flag,
    required String name,
    required String subtitle,
  }) {
    final isSelected = _selected == code;
    return InkWell(
      onTap: () => setState(() => _selected = code),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 40)),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF0D47A1) : Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected
                          ? Colors.grey[700]
                          : Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D47A1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: Colors.white, size: 22),
              ),
          ],
        ),
      ),
    );
  }
}