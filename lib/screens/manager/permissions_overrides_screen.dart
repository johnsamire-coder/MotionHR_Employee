import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_storage_service.dart';

class PermissionsOverridesScreen extends StatefulWidget {
  const PermissionsOverridesScreen({super.key});

  @override
  State<PermissionsOverridesScreen> createState() =>
      _PermissionsOverridesScreenState();
}

class _PermissionsOverridesScreenState
    extends State<PermissionsOverridesScreen> {
  List<dynamic> _users = [];
  bool _loading = true;
  String? _error;
  String _debugInfo = '';

  final String _baseUrl = 'https://jssolutions-eg.com';

  @override
  void initState() {
    super.initState();
    debugPrint('OVERRIDES SCREEN: initState called');
    _load();
  }

  Future<void> _load() async {
    debugPrint('OVERRIDES SCREEN: _load started');
    setState(() {
      _loading = true;
      _error = null;
      _debugInfo = 'جاري التحميل...';
    });

    try {
      final token = await AuthStorageService.getSavedToken() ?? '';
      debugPrint('OVERRIDES SCREEN: token length = ${token.length}');

      if (token.isEmpty) {
        setState(() {
          _error = 'no_token';
          _loading = false;
          _debugInfo = 'مفيش توكن مخزن';
        });
        return;
      }

      final url = Uri.parse(
        '$_baseUrl/attendance/api/mobile/manager/permissions/users/',
      );
      debugPrint('OVERRIDES SCREEN: calling $url');

      final r = await http.get(
        url,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Accept-Language': 'ar',
        },
      ).timeout(const Duration(seconds: 20));

      debugPrint('OVERRIDES SCREEN: status = ${r.statusCode}');
      debugPrint('OVERRIDES SCREEN: body length = ${r.body.length}');

      if (r.statusCode == 200) {
        final d = json.decode(utf8.decode(r.bodyBytes));
        final users = d['users'] ?? [];
        setState(() {
          _users = users;
          _loading = false;
          _debugInfo = 'المستخدمين: ${users.length}';
        });
      } else if (r.statusCode == 401) {
        setState(() {
          _error = 'unauthorized';
          _loading = false;
          _debugInfo = 'التوكن غير صحيح أو منتهي';
        });
      } else {
        setState(() {
          _error = 'http';
          _loading = false;
          _debugInfo = 'خطأ من السيرفر: ${r.statusCode}';
        });
      }
    } catch (e, st) {
      debugPrint('OVERRIDES SCREEN: error = $e');
      debugPrint('OVERRIDES SCREEN: stack = $st');
      setState(() {
        _error = 'connection';
        _loading = false;
        _debugInfo = 'مشكلة اتصال: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'استثناءات المستخدمين' : 'User Overrides'),
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(isAr),
      ),
    );
  }

  Widget _buildBody(bool isAr) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري تحميل المستخدمين...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _errorText(isAr),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _debugInfo,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
            ),
          ),
        ],
      );
    }

    if (_users.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Center(
            child: Text(
              isAr ? 'مفيش مستخدمين متاحين' : 'No users available',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _debugInfo,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final user = _users[index] as Map<String, dynamic>;
        final name = (user['full_name']?.toString().isNotEmpty == true)
            ? user['full_name']
            : user['username'];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _UserOverrideCheckboxScreen(
                  user: user,
                  baseUrl: _baseUrl,
                ),
              ),
            ).then((_) => _load()),
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.12),
              child: const Icon(Icons.tune, color: Colors.orange),
            ),
            title: Text(
              '$name',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '@${user['username']}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        );
      },
    );
  }

  String _errorText(bool isAr) {
    switch (_error) {
      case 'no_token':
        return isAr ? 'مفيش توكن مخزن' : 'No saved token';
      case 'unauthorized':
        return isAr ? 'التوكن غير صحيح' : 'Unauthorized';
      case 'connection':
        return isAr ? 'مشكلة في الاتصال' : 'Connection error';
      default:
        return isAr ? 'حصلت مشكلة' : 'Error';
    }
  }
}

class _UserOverrideCheckboxScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String baseUrl;

  const _UserOverrideCheckboxScreen({
    required this.user,
    required this.baseUrl,
  });

  @override
  State<_UserOverrideCheckboxScreen> createState() =>
      _UserOverrideCheckboxScreenState();
}

class _UserOverrideCheckboxScreenState
    extends State<_UserOverrideCheckboxScreen> {
  List<dynamic> _allPermissions = [];
  List<dynamic> _allScopes = [];
  List<dynamic> _currentOverrides = [];
  bool _loading = true;
  String? _error;
  final Map<String, Map<String, dynamic>> _selections = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Map<String, String>> _headers() async {
    final token = await AuthStorageService.getSavedToken() ?? '';
    return {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Language': 'ar',
    };
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final headers = await _headers();

      final r1 = await http.get(
        Uri.parse(
          '${widget.baseUrl}/attendance/api/mobile/manager/permissions/available/',
        ),
        headers: headers,
      ).timeout(const Duration(seconds: 20));

      final r2 = await http.get(
        Uri.parse(
          '${widget.baseUrl}/attendance/api/mobile/manager/permissions/users/${widget.user['id']}/',
        ),
        headers: headers,
      ).timeout(const Duration(seconds: 20));

      debugPrint('OVERRIDE DETAIL: available status = ${r1.statusCode}');
      debugPrint('OVERRIDE DETAIL: user status = ${r2.statusCode}');

      if (r1.statusCode == 200 && r2.statusCode == 200) {
        final d1 = json.decode(utf8.decode(r1.bodyBytes));
        final d2 = json.decode(utf8.decode(r2.bodyBytes));

        setState(() {
          _allPermissions = d1['permissions'] ?? [];
          _allScopes = d1['scopes'] ?? [];
          _currentOverrides = d2['overrides'] ?? [];
          _selections.clear();

          for (final ov in _currentOverrides) {
            final item = ov as Map<String, dynamic>;
            _selections[item['permission']] = {
              'granted': item['is_granted'] == true,
              'scope': item['scope'] ?? 'company',
            };
          }
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'load';
          _loading = false;
        });
      }
    } catch (e, st) {
      debugPrint('OVERRIDE DETAIL: error = $e');
      debugPrint('OVERRIDE DETAIL: stack = $st');
      setState(() {
        _error = 'connection';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final headers = await _headers();
    final userId = widget.user['id'];

    setState(() => _loading = true);

    try {
      // أولاً: نمسح الاستثناءات القديمة كلها
      for (final ov in _currentOverrides) {
        final item = ov as Map<String, dynamic>;
        final code = item['permission'] as String;
        final res = await http.delete(
          Uri.parse(
            '${widget.baseUrl}/attendance/api/mobile/manager/permissions/override/remove/',
          ),
          headers: headers,
          body: json.encode({'user_id': userId, 'permission': code}),
        );
        debugPrint('OVERRIDE SAVE: remove $code = ${res.statusCode}');
      }

      // ثانياً: نضيف الاستثناءات المختارة
      for (final entry in _selections.entries) {
        final res = await http.post(
          Uri.parse(
            '${widget.baseUrl}/attendance/api/mobile/manager/permissions/override/set/',
          ),
          headers: headers,
          body: json.encode({
            'user_id': userId,
            'permission': entry.key,
            'scope': entry.value['scope'],
            'is_granted': entry.value['granted'],
          }),
        );
        debugPrint('OVERRIDE SAVE: set ${entry.key} = ${res.statusCode}');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'تم حفظ الاستثناءات' : 'Overrides saved'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('OVERRIDE SAVE: error = $e');
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'فشل الحفظ' : 'Save failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final name = (widget.user['full_name']?.toString().isNotEmpty == true)
        ? widget.user['full_name']
        : widget.user['username'];

    return Scaffold(
      appBar: AppBar(
        title: Text('$name'),
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: Text(
              isAr ? 'حفظ' : 'Save',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(isAr ? 'مشكلة في التحميل' : 'Load error'),
                      TextButton(
                        onPressed: _load,
                        child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      color: const Color(0xFFF3F4F6),
                      child: Text(
                        isAr
                            ? 'علّم على الصلاحيات اللي عايز تمنحها أو تمنعها'
                            : 'Select permissions to grant or block',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _allPermissions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final perm =
                              _allPermissions[index] as Map<String, dynamic>;
                          final code = '${perm['code']}';
                          final label = isAr
                              ? '${perm['label_ar'] ?? code}'
                              : code;
                          final isSelected = _selections.containsKey(code);
                          final isGranted = isSelected
                              ? _selections[code]!['granted'] as bool
                              : true;
                          final scope = isSelected
                              ? _selections[code]!['scope'] as String
                              : 'company';

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isGranted
                                      ? Colors.green.shade50
                                      : Colors.red.shade50)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? (isGranted
                                        ? Colors.green.shade200
                                        : Colors.red.shade200)
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Column(
                              children: [
                                CheckboxListTile(
                                  value: isSelected,
                                  activeColor: const Color(0xFF4A148C),
                                  title: Text(
                                    label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: isSelected
                                      ? Row(
                                          children: [
                                            ChoiceChip(
                                              label: Text(
                                                isAr ? 'منح' : 'Grant',
                                                style: const TextStyle(
                                                    fontSize: 11),
                                              ),
                                              selected: isGranted,
                                              selectedColor:
                                                  Colors.green.shade100,
                                              onSelected: (_) =>
                                                  setState(() {
                                                _selections[code] = {
                                                  'granted': true,
                                                  'scope': scope
                                                };
                                              }),
                                            ),
                                            const SizedBox(width: 6),
                                            ChoiceChip(
                                              label: Text(
                                                isAr ? 'منع' : 'Block',
                                                style: const TextStyle(
                                                    fontSize: 11),
                                              ),
                                              selected: !isGranted,
                                              selectedColor:
                                                  Colors.red.shade100,
                                              onSelected: (_) =>
                                                  setState(() {
                                                _selections[code] = {
                                                  'granted': false,
                                                  'scope': scope
                                                };
                                              }),
                                            ),
                                          ],
                                        )
                                      : null,
                                  onChanged: (v) {
                                    setState(() {
                                      if (v == true) {
                                        _selections[code] = {
                                          'granted': true,
                                          'scope': 'company'
                                        };
                                      } else {
                                        _selections.remove(code);
                                      }
                                    });
                                  },
                                ),
                                if (isSelected)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 10),
                                    child: DropdownButtonFormField<String>(
                                      value: scope,
                                      decoration: InputDecoration(
                                        labelText: isAr ? 'النطاق' : 'Scope',
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      items: _allScopes.map((s) {
                                        final item =
                                            s as Map<String, dynamic>;
                                        return DropdownMenuItem(
                                          value: '${item['code']}',
                                          child: Text(isAr
                                              ? '${item['label_ar']}'
                                              : '${item['code']}'),
                                        );
                                      }).toList(),
                                      onChanged: (v) {
                                        setState(() {
                                          _selections[code] = {
                                            'granted': isGranted,
                                            'scope': v ?? 'company'
                                          };
                                        });
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}