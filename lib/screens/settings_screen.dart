import 'package:flutter/material.dart';
import '../services/language_service.dart';
import 'package:motionhr_employee/l10n/l10n.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  String _currentLang = 'ar';
  late TabController _tabController;

  // Password
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _changingPass = false;

  // Prefs
  String _theme = 'light';
  bool _emailNotif = true;
  bool _pushNotif = true;
  bool _dailyReports = false;
  bool _weeklyReports = true;

  @override
  void initState() {
    super.initState();
    _currentLang = LanguageService.currentLanguage;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  bool get isAr => LanguageService.isArabic;

  Future<void> _changeLang(String lang) async {
    await LanguageService.changeLanguage(lang);
    if (!mounted) return;
    setState(() => _currentLang = lang);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          lang == 'ar'
              ? 'تم تغيير اللغة إلى العربية'
              : 'Language changed to English',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _changePassword() async {
    if (_newPassCtrl.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            isAr ? 'كلمة المرور أقل من 8 حروف' : 'Password too short'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            isAr ? 'كلمتا المرور غير متطابقتين' : 'Passwords do not match'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    setState(() => _changingPass = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _changingPass = false);
    _currentPassCtrl.clear();
    _newPassCtrl.clear();
    _confirmPassCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          isAr ? 'تم تغيير كلمة المرور بنجاح' : 'Password changed successfully'),
      backgroundColor: Colors.green,
    ));
  }

  void _savePrefs() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(isAr ? 'تم حفظ التفضيلات' : 'Preferences saved'),
      backgroundColor: Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            isAr ? 'الإعدادات' : 'Settings',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(
                icon: const Icon(Icons.person, size: 18),
                text: isAr ? 'الملف' : 'Profile',
              ),
              Tab(
                icon: const Icon(Icons.lock, size: 18),
                text: isAr ? 'الأمان' : 'Security',
              ),
              Tab(
                icon: const Icon(Icons.tune, size: 18),
                text: isAr ? 'التفضيلات' : 'Prefs',
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildProfileTab(),
            _buildSecurityTab(),
            _buildPrefsTab(),
          ],
        ),
      ),
    );
  }

  // ─── تبويب الملف الشخصي ───
  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          icon: Icons.language,
          color: const Color(0xFF1976D2),
          title: isAr ? 'اللغة' : 'Language',
          subtitle: isAr ? 'اختر لغة التطبيق' : 'Choose app language',
          child: Column(
            children: [
              RadioListTile<String>(
                value: 'ar',
                groupValue: _currentLang,
                onChanged: (v) => _changeLang(v!),
                activeColor: const Color(0xFF1976D2),
                title: Row(
                  children: [
                    const Text('🇸🇦', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(context.l10n.arabic,
                        style: const TextStyle(fontSize: 15)),
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
                    const Text('🇬🇧', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    const Text('English',
                        style: TextStyle(fontSize: 15)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          icon: Icons.info,
          color: Colors.purple,
          title: isAr ? 'حول التطبيق' : 'About',
          subtitle: 'MotionHR v1.0.0',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Icon(Icons.verified, color: Colors.purple[300], size: 16),
                const SizedBox(width: 8),
                Text(
                  isAr
                      ? 'نظام إدارة الموارد البشرية'
                      : 'Human Resources Management System',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── تبويب الأمان ───
  Widget _buildSecurityTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          icon: Icons.lock,
          color: const Color(0xFF1976D2),
          title: isAr ? 'تغيير كلمة المرور' : 'Change Password',
          subtitle: isAr
              ? 'استخدم كلمة مرور قوية لحماية حسابك'
              : 'Use a strong password to protect your account',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // كلمة المرور الحالية
                _passField(
                  label: isAr ? 'كلمة المرور الحالية' : 'Current Password',
                  controller: _currentPassCtrl,
                  show: _showCurrent,
                  onToggle: () =>
                      setState(() => _showCurrent = !_showCurrent),
                ),
                const SizedBox(height: 12),
                // كلمة المرور الجديدة
                _passField(
                  label: isAr ? 'كلمة المرور الجديدة' : 'New Password',
                  controller: _newPassCtrl,
                  show: _showNew,
                  onToggle: () =>
                      setState(() => _showNew = !_showNew),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr
                      ? '* يجب أن تكون 8 أحرف على الأقل'
                      : '* At least 8 characters',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey[500]),
                ),
                const SizedBox(height: 12),
                // تأكيد كلمة المرور
                _passField(
                  label: isAr ? 'تأكيد كلمة المرور' : 'Confirm Password',
                  controller: _confirmPassCtrl,
                  show: _showConfirm,
                  onToggle: () =>
                      setState(() => _showConfirm = !_showConfirm),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _changingPass ? null : _changePassword,
                    icon: _changingPass
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.lock_reset),
                    label: Text(
                      isAr ? 'تغيير كلمة المرور' : 'Update Password',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── تبويب التفضيلات ───
  Widget _buildPrefsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // الثيم
        _sectionCard(
          icon: Icons.palette,
          color: Colors.deepPurple,
          title: isAr ? 'المظهر' : 'Theme',
          subtitle: isAr ? 'اختر مظهر التطبيق' : 'Choose app theme',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _themeBtn('light', Icons.wb_sunny,
                    isAr ? 'فاتح' : 'Light', Colors.amber),
                const SizedBox(width: 8),
                _themeBtn('dark', Icons.nights_stay,
                    isAr ? 'داكن' : 'Dark', Colors.indigo),
                const SizedBox(width: 8),
                _themeBtn('system', Icons.phone_android,
                    isAr ? 'النظام' : 'System', Colors.teal),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // الإشعارات
        _sectionCard(
          icon: Icons.notifications,
          color: Colors.orange,
          title: isAr ? 'الإشعارات' : 'Notifications',
          subtitle: isAr
              ? 'تحكم في إشعارات التطبيق'
              : 'Control app notifications',
          child: Column(
            children: [
              _notifRow(
                icon: Icons.email,
                label: isAr ? 'إشعارات البريد الإلكتروني' : 'Email Notifications',
                value: _emailNotif,
                onChanged: (v) => setState(() => _emailNotif = v),
              ),
              _notifRow(
                icon: Icons.notifications_active,
                label: isAr ? 'إشعارات الدفع' : 'Push Notifications',
                value: _pushNotif,
                onChanged: (v) => setState(() => _pushNotif = v),
              ),
              _notifRow(
                icon: Icons.today,
                label: isAr ? 'التقارير اليومية' : 'Daily Reports',
                value: _dailyReports,
                onChanged: (v) => setState(() => _dailyReports = v),
              ),
              _notifRow(
                icon: Icons.calendar_view_week,
                label: isAr ? 'التقارير الأسبوعية' : 'Weekly Reports',
                value: _weeklyReports,
                onChanged: (v) => setState(() => _weeklyReports = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _savePrefs,
            icon: const Icon(Icons.save),
            label: Text(isAr ? 'حفظ التفضيلات' : 'Save Preferences'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  // ─── مساعدات ───
  Widget _sectionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
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
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          child,
        ],
      ),
    );
  }

  Widget _passField({
    required String label,
    required TextEditingController controller,
    required bool show,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !show,
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: IconButton(
          icon: Icon(show ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
        isDense: true,
      ),
    );
  }

  Widget _themeBtn(
      String value, IconData icon, String label, Color color) {
    final selected = _theme == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _theme = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.15) : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : Colors.grey, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? color : Colors.grey[600],
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notifRow({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      dense: true,
      secondary: Icon(icon, color: Colors.orange, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      value: value,
      activeColor: Colors.orange,
      onChanged: onChanged,
    );
  }
}