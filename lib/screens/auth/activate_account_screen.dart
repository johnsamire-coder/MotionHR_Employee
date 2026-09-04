import 'package:flutter/material.dart';
import '../../services/employee_management_service.dart';

class ActivateAccountScreen extends StatefulWidget {
  const ActivateAccountScreen({super.key});

  @override
  State<ActivateAccountScreen> createState() => _ActivateAccountScreenState();
}

class _ActivateAccountScreenState extends State<ActivateAccountScreen> {
  final _phoneController = TextEditingController();
  final _nationalController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _step2 = false;
  String? _username;
  String? _error;

  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  Future<void> _handleAction() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await EmployeeManagementService.activateEmployeeAccount(
        phone: _phoneController.text,
        nationalIdSuffix: _nationalController.text,
        newPassword: _step2 ? _passwordController.text : null,
      );

      if (res['success'] == true) {
        if (!_step2) {
          setState(() {
            _step2 = true;
            _username = res['username'];
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res['message'] ?? ''), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          }
        }
      } else {
        setState(() => _error = res['message']);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAr ? 'تفعيل الحساب لأول مرة' : 'First Time Activation'),
          backgroundColor: const Color(0xFF37474F),
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Icon(Icons.verified_user_outlined, size: 80, color: Color(0xFF37474F)),
            const SizedBox(height: 24),
            Text(
              isAr ? 'أدخل بياناتك المسجلة في الشركة لتفعيل حسابك' : 'Enter your registered data to activate account',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: isAr ? 'رقم الموبايل' : 'Phone Number',
                prefixIcon: const Icon(Icons.phone),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              enabled: !_step2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nationalController,
              decoration: InputDecoration(
                labelText: isAr ? 'آخر 4 أرقام من القومي' : 'Last 4 digits of National ID',
                prefixIcon: const Icon(Icons.badge),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              enabled: !_step2,
            ),
            if (_step2) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                color: Color(0xFF382483).withAlpha(20),
                child: Text('${isAr ? "اسم المستخدم الخاص بك هو" : "Your username is"}: $_username',
                  style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: isAr ? 'كلمة السر الجديدة' : 'New Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loading ? null : _handleAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF37474F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _loading 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(_step2 ? (isAr ? 'تفعيل الآن' : 'Activate Now') : (isAr ? 'تحقق من هويتي' : 'Verify Identity')),
            ),
          ]),
        ),
      ),
    );
  }
}
