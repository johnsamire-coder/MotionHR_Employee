// lib/screens/employee/field_visits_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/field_visits_service.dart';

class FieldVisitsScreen extends StatefulWidget {
  const FieldVisitsScreen({super.key});

  @override
  State<FieldVisitsScreen> createState() => _FieldVisitsScreenState();
}

class _FieldVisitsScreenState extends State<FieldVisitsScreen> {
  final _service = FieldVisitsService();
  bool _loading = true;
  bool _processing = false;
  Map<String, dynamic>? _data;
  List<dynamic> _visitTypes = [];

  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final visits = await _service.getMyVisits(filter: 'today');
      final types = await _service.getVisitTypes();
      if (mounted) {
        setState(() {
          _data = visits;
          _visitTypes = types;
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

  Future<Position?> _getCurrentLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          _showError(isAr ? 'يجب السماح بالوصول للموقع' : 'Location permission denied');
          return null;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        _showError(isAr ? 'يرجى تفعيل الموقع من إعدادات الجهاز' : 'Please enable location');
        return null;
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      _showError('${isAr ? 'خطأ في الموقع' : 'Location error'}: $e');
      return null;
    }
  }

  Future<void> _startNewVisit() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _StartVisitDialog(visitTypes: _visitTypes),
    );

    if (result == null) return;

    setState(() => _processing = true);
    final position = await _getCurrentLocation();
    if (position == null) {
      setState(() => _processing = false);
      return;
    }

    try {
      final response = await _service.startVisit(
        visitType: result['visit_type']!,
        locationName: result['location_name']!,
        purpose: result['purpose']!,
        latitude: position.latitude,
        longitude: position.longitude,
        notes: result['notes'] ?? '',
      );

      if (response['success'] == true) {
        _showSuccess(isAr ? 'تم بدء الزيارة بنجاح' : 'Visit started');
        await _load();
      } else {
        _showError(response['message'] ?? 'فشل بدء الزيارة');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _endVisit(int visitId, String locationName) async {
    final notes = await showDialog<String>(
      context: context,
      builder: (context) => _EndVisitDialog(locationName: locationName),
    );

    if (notes == null) return;

    setState(() => _processing = true);
    final position = await _getCurrentLocation();
    if (position == null) {
      setState(() => _processing = false);
      return;
    }

    try {
      final response = await _service.endVisit(
        visitId: visitId,
        latitude: position.latitude,
        longitude: position.longitude,
        notes: notes,
      );

      if (response['success'] == true) {
        _showSuccess(isAr ? 'تم إنهاء الزيارة' : 'Visit ended');
        await _load();
      } else {
        _showError(response['message'] ?? 'فشل إنهاء الزيارة');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeVisit = _data?['active_visit'];
    final visits = (_data?['visits'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'الزيارات الميدانية' : 'Field Visits'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (activeVisit != null) _buildActiveVisitCard(activeVisit),
                  const SizedBox(height: 16),
                  _buildStartButton(),
                  const SizedBox(height: 24),
                  Text(
                    isAr ? 'زيارات اليوم' : 'Today\'s Visits',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (visits.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            isAr ? 'لا توجد زيارات اليوم' : 'No visits today',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ),
                    )
                  else
                    ...visits.map((v) => _buildVisitCard(v)),
                ],
              ),
            ),
    );
  }

  Widget _buildActiveVisitCard(Map<String, dynamic> visit) {
    return Card(
      elevation: 4,
      color: Colors.green[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.green, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.location_on, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? ' زيارة نشطة' : ' Active Visit',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        visit['location_name'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _infoRow(Icons.info_outline, isAr ? 'النوع:' : 'Type:',
                visit['visit_type_display'] ?? ''),
            const SizedBox(height: 8),
            _infoRow(Icons.assignment, isAr ? 'الغرض:' : 'Purpose:',
                visit['purpose'] ?? ''),
            const SizedBox(height: 8),
            _infoRow(Icons.access_time, isAr ? 'من:' : 'Since:',
                visit['arrival_time'] ?? ''),
            if (visit['duration_minutes'] != null) ...[
              const SizedBox(height: 8),
              _infoRow(Icons.timer, isAr ? 'المدة:' : 'Duration:',
                  '${visit['duration_minutes']} ${isAr ? "دقيقة" : "min"}'),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _processing
                    ? null
                    : () => _endVisit(
                          visit['id'],
                          visit['location_name'] ?? '',
                        ),
                icon: const Icon(Icons.logout),
                label: Text(isAr ? 'إنهاء الزيارة' : 'End Visit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _processing ? null : _startNewVisit,
        icon: _processing
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.add_location, size: 28),
        label: Text(
          isAr ? 'بدء زيارة جديدة' : 'Start New Visit',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildVisitCard(Map<String, dynamic> visit) {
    final isActive = visit['is_active'] == true;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isActive ? Icons.location_on : Icons.check_circle,
                  color: isActive ? Colors.green : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    visit['location_name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Chip(
                  label: Text(
                    visit['status_display'] ?? '',
                    style: const TextStyle(fontSize: 10),
                  ),
                  padding: EdgeInsets.zero,
                  backgroundColor: isActive ? Colors.green[100] : Colors.blue[100],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${visit['visit_type_display']}  ${visit['purpose']}',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              '${visit['arrival_time']} ${visit['departure_time'] != null ? " ${visit["departure_time"]}" : ""}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[700])),
        const SizedBox(width: 4),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}


// 
// Start Visit Dialog
// 
class _StartVisitDialog extends StatefulWidget {
  final List<dynamic> visitTypes;
  const _StartVisitDialog({required this.visitTypes});

  @override
  State<_StartVisitDialog> createState() => _StartVisitDialogState();
}

class _StartVisitDialogState extends State<_StartVisitDialog> {
  final _locationCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _selectedType;

  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isAr ? 'بدء زيارة جديدة' : 'Start New Visit'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: isAr ? 'نوع الزيارة *' : 'Visit Type *',
                border: const OutlineInputBorder(),
              ),
              items: widget.visitTypes
                  .map<DropdownMenuItem<String>>((t) => DropdownMenuItem(
                        value: t['value'],
                        child: Text(t['label']),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedType = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationCtrl,
              decoration: InputDecoration(
                labelText: isAr ? 'اسم الموقع *' : 'Location Name *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _purposeCtrl,
              decoration: InputDecoration(
                labelText: isAr ? 'الغرض من الزيارة *' : 'Purpose *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.assignment),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                labelText: isAr ? 'ملاحظات (اختياري)' : 'Notes (optional)',
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
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
            if (_selectedType == null ||
                _locationCtrl.text.trim().isEmpty ||
                _purposeCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(isAr
                        ? 'يرجى ملء الحقول المطلوبة'
                        : 'Please fill required fields')),
              );
              return;
            }
            Navigator.pop(context, {
              'visit_type': _selectedType!,
              'location_name': _locationCtrl.text.trim(),
              'purpose': _purposeCtrl.text.trim(),
              'notes': _notesCtrl.text.trim(),
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          child: Text(isAr ? 'بدء' : 'Start'),
        ),
      ],
    );
  }
}


// 
// End Visit Dialog
// 
class _EndVisitDialog extends StatefulWidget {
  final String locationName;
  const _EndVisitDialog({required this.locationName});

  @override
  State<_EndVisitDialog> createState() => _EndVisitDialogState();
}

class _EndVisitDialogState extends State<_EndVisitDialog> {
  final _notesCtrl = TextEditingController();

  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isAr ? 'إنهاء الزيارة' : 'End Visit'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.locationName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            decoration: InputDecoration(
              labelText: isAr ? 'ملاحظات (اختياري)' : 'Notes (optional)',
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(isAr ? 'إلغاء' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _notesCtrl.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(isAr ? 'إنهاء' : 'End'),
        ),
      ],
    );
  }
}
