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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await AuthStorageService.getSavedToken() ?? '';
      final r = await http.get(
        Uri.parse(
          'https://jssolutions-eg.com/attendance/api/mobile/manager/permissions/users/',
        ),
        headers: {'Authorization': 'Token $token'},
      ).timeout(const Duration(seconds: 15));

      if (r.statusCode == 200) {
        final d = json.decode(utf8.decode(r.bodyBytes));
        setState(() {
          _users = d['users'] ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'http';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'connection';
        _loading = false;
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
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(child: Text(isAr ? 'حصلت مشكلة' : 'Error')),
                      Center(
                        child: TextButton(
                          onPressed: _load,
                          child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
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
                            BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4)),
                          ],
                        ),
                        child: ListTile(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _UserOverrideCheckboxScreen(user: user),
                            ),
                          ).then((_) => _load()),
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.withValues(alpha: 0.12),
                            child: const Icon(Icons.tune, color: Colors.orange),
                          ),
                          title: Text('$name', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('@${user['username']}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class _UserOverrideCheckboxScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const _UserOverrideCheckboxScreen({required this.user});

  @override
  State<_UserOverrideCheckboxScreen> createState() => _UserOverrideCheckboxScreenState();
}

class _UserOverrideCheckboxScreenState extends State<_UserOverrideCheckboxScreen> {
  List<dynamic> _allPermissions = [];
  List<dynamic> _allScopes = [];
  List<dynamic> _currentOverrides = [];
  bool _loading = true;
  final Map<String, Map<String, dynamic>> _selections = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final token = await AuthStorageService.getSavedToken() ?? '';
      final headers = {'Authorization': 'Token $token'};

      final r1 = await http.get(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/permissions/available/'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      final r2 = await http.get(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/permissions/users/${widget.user['id']}/'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (r1.statusCode == 200 && r2.statusCode == 200) {
        final d1 = json.decode(utf8.decode(r1.bodyBytes));
        final d2 = json.decode(utf8.decode(r2.bodyBytes));
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
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final token = await AuthStorageService.getSavedToken() ?? '';
    final headers = {'Authorization': 'Token $token', 'Content-Type': 'application/json'};
    final userId = widget.user['id'];

    for (final ov in _currentOverrides) {
      final item = ov as Map<String, dynamic>;
      final code = item['permission'] as String;
      if (!_selections.containsKey(code)) {
        await http.delete(
          Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/permissions/override/remove/'),
          headers: headers,
          body: json.encode({'user_id': userId, 'permission': code}),
        );
      }
    }

    for (final entry in _selections.entries) {
      await http.post(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/permissions/override/set/'),
        headers: headers,
        body: json.encode({
          'user_id': userId,
          'permission': entry.key,
          'scope': entry.value['scope'],
          'is_granted': entry.value['granted'],
        }),
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isAr ? 'تم حفظ الاستثناءات' : 'Overrides saved'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
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
            onPressed: _save,
            child: Text(
              isAr ? 'حفظ' : 'Save',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
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
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _allPermissions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final perm = _allPermissions[index] as Map<String, dynamic>;
                      final code = '${perm['code']}';
                      final label = isAr ? '${perm['label_ar'] ?? code}' : code;
                      final isSelected = _selections.containsKey(code);
                      final isGranted = isSelected ? _selections[code]!['granted'] as bool : true;
                      final scope = isSelected ? _selections[code]!['scope'] as String : 'company';

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isGranted ? Colors.green.shade50 : Colors.red.shade50)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? (isGranted ? Colors.green.shade200 : Colors.red.shade200)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          children: [
                            CheckboxListTile(
                              value: isSelected,
                              activeColor: const Color(0xFF4A148C),
                              title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: isSelected
                                  ? Row(
                                      children: [
                                        ChoiceChip(
                                          label: Text(isAr ? 'منح' : 'Grant',
                                              style: const TextStyle(fontSize: 11)),
                                          selected: isGranted,
                                          selectedColor: Colors.green.shade100,
                                          onSelected: (_) => setState(() {
                                            _selections[code] = {'granted': true, 'scope': scope};
                                          }),
                                        ),
                                        const SizedBox(width: 6),
                                        ChoiceChip(
                                          label: Text(isAr ? 'منع' : 'Block',
                                              style: const TextStyle(fontSize: 11)),
                                          selected: !isGranted,
                                          selectedColor: Colors.red.shade100,
                                          onSelected: (_) => setState(() {
                                            _selections[code] = {'granted': false, 'scope': scope};
                                          }),
                                        ),
                                      ],
                                    )
                                  : null,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _selections[code] = {'granted': true, 'scope': 'company'};
                                  } else {
                                    _selections.remove(code);
                                  }
                                });
                              },
                            ),
                            if (isSelected)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                                child: DropdownButtonFormField<String>(
                                  initialValue: scope,
                                  decoration: InputDecoration(
                                    labelText: isAr ? 'النطاق' : 'Scope',
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: _allScopes.map((s) {
                                    final item = s as Map<String, dynamic>;
                                    return DropdownMenuItem(
                                      value: '${item['code']}',
                                      child: Text(isAr ? '${item['label_ar']}' : '${item['code']}'),
                                    );
                                  }).toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      _selections[code] = {'granted': isGranted, 'scope': v ?? 'company'};
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

