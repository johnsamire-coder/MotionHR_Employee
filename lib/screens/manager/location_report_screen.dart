// lib/screens/manager/location_report_screen.dart
import 'package:flutter/material.dart';
import '../../services/location_tracking_service.dart';
import '../../services/employee_management_service.dart';
import '../../services/report_pdf_service.dart';
import 'package:motionhr_employee/l10n/l10n.dart';

class LocationReportScreen extends StatefulWidget {
  const LocationReportScreen({super.key});

  @override
  State<LocationReportScreen> createState() => _LocationReportScreenState();
}

class _LocationReportScreenState extends State<LocationReportScreen> {
  List<Map<String, dynamic>> _employees = [];
  Map<String, dynamic>? _selectedEmployee;
  DateTime _selectedDate = DateTime.now();
  bool _loadingEmployees = true;
  bool _loadingReport = false;
  bool _printing = false;
  Map<String, dynamic>? _reportData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final list = await EmployeeManagementService.getEmployeesSimple();
      setState(() {
        _employees = list;
        _loadingEmployees = false;
      });
    } catch (e) {
      setState(() { _loadingEmployees = false; });
    }
  }

  Future<void> _loadReport() async {
    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر موظفاً أولاً')),
      );
      return;
    }

    setState(() { _loadingReport = true; _error = null; _reportData = null; });

    try {
      final shiftDate =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      final data = await LocationTrackingService.getLocationReport(
        employeeId: _selectedEmployee!['id'],
        shiftDate: shiftDate,
      );

      setState(() {
        _reportData = data;
        _loadingReport = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingReport = false;
      });
    }
  }

  Future<void> _print() async {
    if (_reportData == null) return;
    setState(() => _printing = true);
    try {
      final points = (_reportData!['points'] as List?) ?? [];
      final rows = points.asMap().entries.map<List<String>>((entry) {
        final i = entry.key;
        final p = entry.value;
        return [
          '${i + 1}',
          p['address']?.toString() ?? 'موقع غير معروف',
          p['recorded_at']?.toString() ?? '-',
        ];
      }).toList();

      await ReportPdfService.printReport(
        title: 'تقرير المواقع اليومي',
        subtitle: 'الموظف: ${_reportData!['employee']?['name'] ?? ''} | التاريخ: ${_formatDate(_selectedDate)}',
        headers: ['#', 'العنوان / الموقع', 'الوقت'],
        rows: rows,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الطباعة: $e')));
    }
    if (mounted) setState(() => _printing = false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF4A148C),
          foregroundColor: Colors.white,
          title: const Text('تقرير المواقع اليومي',
              style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            if (_reportData != null)
              _printing
                  ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                  : IconButton(onPressed: _print, icon: const Icon(Icons.print)),
          ],
        ),
        body: Column(
          children: [
            // فلتر
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  _loadingEmployees
                      ? const CircularProgressIndicator()
                      : DropdownButtonFormField<Map<String, dynamic>>(
                          decoration: InputDecoration(
                            labelText: 'اختر الموظف',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.person),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          value: _selectedEmployee,
                          items: _employees.map((emp) {
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: emp,
                              child: Text(
                                emp['full_name'] ?? '',
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedEmployee = val),
                        ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 18, color: Color(0xFF4A148C)),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDate(_selectedDate),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _loadingReport ? null : _loadReport,
                        icon: const Icon(Icons.search, color: Colors.white),
                        label: Text(context.l10n.search,
                            style: const TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A148C),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: _loadingReport
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(_error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                  onPressed: _loadReport,
                                  child: Text(context.l10n.retry)),
                            ],
                          ),
                        )
                      : _reportData == null
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.location_on_outlined,
                                      size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('اختر موظفاً وتاريخاً للبحث',
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : _buildReport(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReport() {
    final points = _reportData!['points'] as List? ?? [];
    final empName = _reportData!['employee']?['name'] ?? '';
    final total = _reportData!['total_points'] ?? 0;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF4A148C),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.person, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(empName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    Text(_formatDate(_selectedDate),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$total نقطة',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: points.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('لا توجد بيانات موقع لهذا اليوم',
                          style: TextStyle(color: Colors.grey, fontSize: 15)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: points.length,
                  itemBuilder: (context, i) {
                    final point = points[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A148C).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  color: Color(0xFF4A148C),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  point['address']?.toString().isNotEmpty == true
                                      ? point['address']
                                      : 'موقع غير معروف',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time,
                                        size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      point['recorded_at'] ?? '',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.location_on,
                              color: Color(0xFF4A148C), size: 20),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}