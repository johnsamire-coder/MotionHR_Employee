// lib/screens/employee/my_work_locations_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/work_locations_service.dart';

class MyWorkLocationsScreen extends StatefulWidget {
  const MyWorkLocationsScreen({super.key});

  @override
  State<MyWorkLocationsScreen> createState() => _MyWorkLocationsScreenState();
}

class _MyWorkLocationsScreenState extends State<MyWorkLocationsScreen> {
  final _service = WorkLocationsService();
  bool _loading = true;
  bool _processing = false;
  List<dynamic> _locations = [];
  List<dynamic> _types = [];
  String _filter = 'all';

  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getMyLocations(filter: _filter);
      final types = await _service.getLocationTypes();
      if (mounted) {
        setState(() {
          _locations = data['locations'] ?? [];
          _types = types;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError(e.toString());
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  Future<Position?> _getLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return null;
      }
      if (perm == LocationPermission.deniedForever) return null;
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _proposeNewLocation() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ProposeLocationDialog(types: _types),
    );

    if (result == null) return;

    setState(() => _processing = true);

    double lat, lng;

    if (result['use_current_location'] == true) {
      final pos = await _getLocation();
      if (pos == null) {
        setState(() => _processing = false);
        _showError(isAr ? 'يجب السماح بالموقع' : 'Location required');
        return;
      }
      lat = pos.latitude;
      lng = pos.longitude;
    } else {
      lat = result['latitude'];
      lng = result['longitude'];
    }

    try {
      final response = await _service.proposeLocation(
        name: result['name'],
        locationType: result['location_type'],
        latitude: lat,
        longitude: lng,
        radius: result['radius'] ?? 500,
        description: result['description'] ?? '',
        projectCode: result['project_code'] ?? '',
        clientName: result['client_name'] ?? '',
        contactPerson: result['contact_person'] ?? '',
        contactPhone: result['contact_phone'] ?? '',
        notes: result['notes'] ?? '',
      );

      if (response['success'] == true) {
        _showSuccess(isAr
            ? 'تم اقتراح الموقع، في انتظار الموافقة'
            : 'Location proposed, awaiting approval');
        await _load();
      } else {
        _showError(response['message'] ?? 'فشل الاقتراح');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _cancelLocation(int locationId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isAr ? 'إلغاء الطلب' : 'Cancel Request'),
        content: Text(isAr
            ? 'هل تريد إلغاء طلب اعتماد [$name]؟'
            : 'Cancel request for [$name]?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isAr ? 'لا' : 'No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(isAr ? 'نعم' : 'Yes',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _processing = true);
    try {
      final r = await _service.cancelPendingLocation(locationId);
      if (r['success'] == true) {
        _showSuccess(isAr ? 'تم إلغاء الطلب' : 'Request cancelled');
        await _load();
      } else {
        _showError(r['message'] ?? 'فشل الإلغاء');
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      case 'suspended':
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'pending':
        return Icons.hourglass_empty;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'مواقع عملي' : 'My Work Locations'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter chips
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('all', isAr ? 'الكل' : 'All'),
                        _filterChip('approved', isAr ? 'معتمد' : 'Approved'),
                        _filterChip('pending', isAr ? 'قيد الموافقة' : 'Pending'),
                        _filterChip('rejected', isAr ? 'مرفوض' : 'Rejected'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: _locations.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_off,
                                    size: 80, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  isAr
                                      ? 'لا توجد مواقع'
                                      : 'No locations',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _locations.length,
                            itemBuilder: (_, i) => _buildCard(_locations[i]),
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _processing ? null : _proposeNewLocation,
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add_location, color: Colors.white),
        label: Text(
          isAr ? 'اقتراح موقع' : 'Propose',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _filter = value);
          _load();
        },
        selectedColor: Colors.deepPurple,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> loc) {
    final status = loc['status'] ?? 'pending';
    final statusColor = _statusColor(status);
    final canCancel = status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_statusIcon(status), color: statusColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc['name'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Chip(
                  label: Text(loc['status_display'] ?? '',
                      style: const TextStyle(fontSize: 10)),
                  backgroundColor: statusColor.withValues(alpha: 0.2),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              loc['location_type_display'] ?? '',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            if ((loc['address'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.place, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      loc['address'],
                      style:
                          TextStyle(color: Colors.grey[700], fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (status == 'rejected' &&
                (loc['rejection_reason'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, size: 14, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        loc['rejection_reason'],
                        style: const TextStyle(
                            color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (canCancel) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _processing
                      ? null
                      : () => _cancelLocation(loc['id'], loc['name'] ?? ''),
                  icon: const Icon(Icons.cancel, size: 16),
                  label: Text(isAr ? 'إلغاء الطلب' : 'Cancel'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Propose Location Dialog
// ═══════════════════════════════════════════════════
class _ProposeLocationDialog extends StatefulWidget {
  final List<dynamic> types;
  const _ProposeLocationDialog({required this.types});

  @override
  State<_ProposeLocationDialog> createState() =>
      _ProposeLocationDialogState();
}

class _ProposeLocationDialogState extends State<_ProposeLocationDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();
  final _projectCtrl = TextEditingController();
  final _radiusCtrl = TextEditingController(text: '500');
  String? _selectedType;
  bool _useCurrentLocation = true;

  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isAr ? 'اقتراح موقع جديد' : 'Propose New Location'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: isAr ? 'نوع الموقع *' : 'Type *',
                border: const OutlineInputBorder(),
              ),
              items: widget.types
                  .map<DropdownMenuItem<String>>((t) => DropdownMenuItem(
                        value: t['value'],
                        child: Text(t['label']),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedType = v),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: isAr ? 'اسم الموقع *' : 'Name *',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              decoration: InputDecoration(
                labelText: isAr ? 'الوصف' : 'Description',
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _clientCtrl,
              decoration: InputDecoration(
                labelText: isAr ? 'اسم العميل (اختياري)' : 'Client',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _projectCtrl,
              decoration: InputDecoration(
                labelText: isAr ? 'كود المشروع (اختياري)' : 'Project Code',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _radiusCtrl,
              decoration: InputDecoration(
                labelText: isAr ? 'نصف قطر (متر)' : 'Radius (m)',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: Text(
                isAr ? 'استخدم موقعي الحالي' : 'Use current location',
                style: const TextStyle(fontSize: 13),
              ),
              value: _useCurrentLocation,
              onChanged: (v) => setState(() => _useCurrentLocation = v),
              activeColor: Colors.deepPurple,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(isAr ? 'إلغاء' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedType == null || _nameCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(isAr
                        ? 'يرجى ملء الحقول المطلوبة'
                        : 'Fill required fields')),
              );
              return;
            }
            Navigator.pop(context, {
              'name': _nameCtrl.text.trim(),
              'location_type': _selectedType,
              'description': _descCtrl.text.trim(),
              'client_name': _clientCtrl.text.trim(),
              'project_code': _projectCtrl.text.trim(),
              'radius': int.tryParse(_radiusCtrl.text) ?? 500,
              'use_current_location': _useCurrentLocation,
            });
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
          child: Text(isAr ? 'اقتراح' : 'Propose',
              style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
