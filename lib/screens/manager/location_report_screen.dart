// lib/screens/manager/location_report_screen.dart
// Phase 16 — Final clean version (0 warnings)

import 'package:flutter/material.dart';
import '../../services/location_tracking_service.dart';
import '../../services/employee_management_service.dart';
import '../../services/report_pdf_service.dart';
import '../../services/report_excel_service.dart';

class LocationReportScreen extends StatefulWidget {
  const LocationReportScreen({super.key});

  @override
  State<LocationReportScreen> createState() => _LocationReportScreenState();
}

class _LocationReportScreenState extends State<LocationReportScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  List<Map<String, dynamic>> _employees = [];
  Map<String, dynamic>? _selectedEmployee;
  DateTime _selectedDate = DateTime.now();
  bool _loadingEmployees = true;
  bool _loadingReport = false;
  bool _exporting = false;
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
      if (mounted) {
        setState(() {
          _employees = list;
          _loadingEmployees = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingEmployees = false);
    }
  }

  Future<void> _loadReport() async {
    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr ? 'اختر موظفاً أولاً' : 'Please select an employee first',
          ),
        ),
      );
      return;
    }
    setState(() {
      _loadingReport = true;
      _error = null;
      _reportData = null;
    });
    try {
      final shiftDate =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final data = await LocationTrackingService.getLocationReport(
        employeeId: _selectedEmployee!['id'],
        shiftDate: shiftDate,
      );
      if (mounted) {
        setState(() {
          _reportData = data;
          _loadingReport = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loadingReport = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: Locale(isAr ? 'ar' : 'en'),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Future<void> _printPdf() async {
    if (_reportData == null) return;
    setState(() => _printing = true);
    try {
      final points = (_reportData!['points'] as List?) ?? [];
      final rows = points.asMap().entries.map<List<String>>((entry) {
        final p = entry.value;
        return [
          '${entry.key + 1}',
          p['address']?.toString().isNotEmpty == true
              ? p['address']
              : (isAr ? 'موقع غير معروف' : 'Unknown'),
          p['recorded_at']?.toString() ?? '-',
        ];
      }).toList();
      await ReportPdfService.printReport(
        title: isAr ? 'تقرير المواقع اليومي' : 'Daily Location Report',
        subtitle:
            '${isAr ? 'الموظف' : 'Employee'}: ${_reportData!['employee']?['name'] ?? ''} | ${_formatDate(_selectedDate)}',
        headers: isAr
            ? ['#', 'العنوان / الموقع', 'الوقت']
            : ['#', 'Address / Location', 'Time'],
        rows: rows,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'خطأ في الطباعة: $e' : 'Print error: $e'),
          ),
        );
      }
    }
    if (mounted) setState(() => _printing = false);
  }

  Future<void> _exportExcel() async {
    if (_reportData == null) return;
    setState(() => _exporting = true);
    try {
      final points = List<Map<String, dynamic>>.from(
        (_reportData!['points'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );
      final empName = _reportData!['employee']?['name']?.toString() ?? '';
      final dateStr =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      await ReportExcelService.exportLocationReport(
        points: points,
        employeeName: empName,
        date: dateStr,
        isAr: isAr,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(isAr ? 'خطأ في التصدير: $e' : 'Export error: $e'),
          ),
        );
      }
    }
    if (mounted) setState(() => _exporting = false);
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF4A148C),
          foregroundColor: Colors.white,
          title: Text(
            isAr ? 'تقرير المواقع اليومي' : 'Daily Location Report',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            if (_reportData != null) ...[
              _exporting
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: _exportExcel,
                      icon: const Icon(Icons.table_chart_outlined),
                      tooltip: isAr ? 'تصدير Excel' : 'Export Excel',
                    ),
              _printing
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: _printPdf,
                      icon: const Icon(Icons.print),
                      tooltip: isAr ? 'طباعة PDF' : 'Print PDF',
                    ),
            ],
          ],
        ),
        body: Column(
          children: [
            // ── Filter Bar ──
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  // ── Employee Dropdown ──
                  // Using InputDecorator + DropdownButton to avoid
                  // deprecated 'value' warning in DropdownButtonFormField
                  _loadingEmployees
                      ? const Center(child: CircularProgressIndicator())
                      : InputDecorator(
                          decoration: InputDecoration(
                            labelText:
                                isAr ? 'اختر الموظف' : 'Select Employee',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            prefixIcon: const Icon(Icons.person),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Map<String, dynamic>>(
                              value: _selectedEmployee,
                              isExpanded: true,
                              hint: Text(
                                isAr ? 'اختر الموظف' : 'Select Employee',
                                style: const TextStyle(fontSize: 13),
                              ),
                              items: _employees.map((emp) {
                                return DropdownMenuItem<Map<String, dynamic>>(
                                  value: emp,
                                  child: Text(
                                    emp['full_name']?.toString() ?? '',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedEmployee = val),
                            ),
                          ),
                        ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // ── Date Picker ──
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                  color: Color(0xFF4A148C),
                                ),
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
                      // ── Search Button ──
                      ElevatedButton.icon(
                        onPressed: _loadingReport ? null : _loadReport,
                        icon: const Icon(Icons.search, color: Colors.white),
                        label: Text(
                          isAr ? 'بحث' : 'Search',
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A148C),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Body ──
            Expanded(
              child: _loadingReport
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildError()
                      : _reportData == null
                          ? _buildEmptyState()
                          : _buildReport(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadReport,
            child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on_outlined,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            isAr
                ? 'اختر موظفاً وتاريخاً للبحث'
                : 'Select an employee and date to search',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReport() {
    final points = _reportData!['points'] as List? ?? [];
    final empName = _reportData!['employee']?['name']?.toString() ?? '';
    final total = _reportData!['total_points'] ?? 0;

    return Column(
      children: [
        // ── Summary Card ──
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF4A148C),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.person, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      empName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      _formatDate(_selectedDate),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$total ${isAr ? 'نقطة' : 'points'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Points List ──
        Expanded(
          child: points.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        isAr
                            ? 'لا توجد بيانات موقع لهذا اليوم'
                            : 'No location data for this day',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: points.length,
                  itemBuilder: (context, i) {
                    final point = points[i];
                    final address =
                        point['address']?.toString().isNotEmpty == true
                            ? point['address']
                            : (isAr
                                ? 'موقع غير معروف'
                                : 'Unknown location');
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
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
                              color: const Color(0xFF4A148C)
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Color(0xFF4A148C),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  address,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 12,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      point['recorded_at']?.toString() ??
                                          '-',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFF4A148C),
                            size: 20,
                          ),
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
