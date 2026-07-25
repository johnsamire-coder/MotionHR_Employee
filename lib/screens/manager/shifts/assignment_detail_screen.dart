import 'package:flutter/material.dart';
import '../../../services/shifts_service.dart';
import '../../../services/employee_management_service.dart';

const Color kAssignColor = Color(0xFF6A1B9A);

class AssignmentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> assignment;

  const AssignmentDetailScreen({super.key, required this.assignment});

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  List<Map<String, dynamic>> _allEmployees = [];
  bool _loading = true;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  Set<int> _excludedIds = {};

  @override
  void initState() {
    super.initState();
    _initExcluded();
    _loadEmployees();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _initExcluded() {
    final excluded = widget.assignment['excluded_employees'] as List? ?? [];
    _excludedIds = excluded.map<int>((e) => e['id'] as int).toSet();
  }

  Future<void> _loadEmployees() async {
    try {
      final emps = await EmployeeManagementService.getEmployeesSimple();
      final type = widget.assignment['assignment_type']?.toString();
      final targetId = widget.assignment['target_id'] as int?;

      List<Map<String, dynamic>> filtered;
      if (type == 'employee') {
        filtered = emps.where((e) => e['id'] == targetId).toList();
      } else if (type == 'department') {
        filtered = emps.where((e) => e['department_id'] == targetId).toList();
      } else if (type == 'branch') {
        filtered = emps.where((e) => e['branch_id'] == targetId).toList();
      } else {
        filtered = emps;
      }

      if (mounted) {
        setState(() {
          _allEmployees = filtered;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredEmployees {
    if (_searchQuery.isEmpty) return _allEmployees;
    return _allEmployees.where((e) {
      final name = (e['full_name'] ?? '').toString().toLowerCase();
      final nat = (e['national_id'] ?? '').toString().toLowerCase();
      final phone = (e['phone'] ?? '').toString().toLowerCase();
      final code = (e['employee_code'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) ||
          nat.contains(_searchQuery) ||
          phone.contains(_searchQuery) ||
          code.contains(_searchQuery);
    }).toList();
  }

  Future<void> _toggleExclude(Map<String, dynamic> emp) async {
    final wasExcluded = _excludedIds.contains(emp['id']);
    final action = wasExcluded
        ? (isAr ? 'إرجاع الموظف للتعيين' : 'Include employee back?')
        : (isAr ? 'استثناء الموظف من التعيين' : 'Exclude employee from assignment?');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(emp['full_name']?.toString() ?? ''),
          content: Text(action),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(isAr ? 'تراجع' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: wasExcluded ? kAssignColor : Colors.red,
              ),
              child: Text(
                wasExcluded ? (isAr ? 'إرجاع' : 'Include') : (isAr ? 'استثناء' : 'Exclude'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirm != true) return;

    final newExcluded = Set<int>.from(_excludedIds);
    if (wasExcluded) {
      newExcluded.remove(emp['id']);
    } else {
      newExcluded.add(emp['id']);
    }

    try {
      final success = await ShiftsService.updateAssignment(
        widget.assignment['id'] as int,
        {'excluded_employee_ids': newExcluded.toList()},
      );
      if (success && mounted) {
        setState(() => _excludedIds = newExcluded);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wasExcluded
                  ? (isAr ? 'تم إرجاع الموظف' : 'Employee included')
                  : (isAr ? 'تم استثناء الموظف' : 'Employee excluded'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _typeLabel() {
    final type = widget.assignment['assignment_type']?.toString();
    if (isAr) {
      switch (type) {
        case 'employee': return 'موظف';
        case 'department': return 'قسم';
        case 'branch': return 'فرع';
        case 'company': return 'شركة';
        default: return type ?? '';
      }
    } else {
      switch (type) {
        case 'employee': return 'Employee';
        case 'department': return 'Department';
        case 'branch': return 'Branch';
        case 'company': return 'Company';
        default: return type ?? '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _allEmployees.where((e) => !_excludedIds.contains(e['id'])).length;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            isAr ? 'تفاصيل التعيين' : 'Assignment Details',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: kAssignColor,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: kAssignColor.withValues(alpha: 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule, color: kAssignColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.assignment['shift_name']?.toString() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: kAssignColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _typeLabel(),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.assignment['target_name']?.toString() ?? '',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${isAr ? 'من' : 'From'}: ${widget.assignment['start_date'] ?? '-'}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      if (widget.assignment['end_date'] != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          '${isAr ? 'إلى' : 'To'}: ${widget.assignment['end_date']}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                  if (widget.assignment['assignment_type'] != 'employee') ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kAssignColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.people, size: 14, color: Colors.green[700]),
                          const SizedBox(width: 4),
                          Text(
                            '${isAr ? "الفعّالون" : "Active"}: $activeCount',
                            style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.bold),
                          ),
                          if (_excludedIds.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.person_off, size: 14, color: Colors.red[700]),
                            const SizedBox(width: 4),
                            Text(
                              '${isAr ? "المستثنون" : "Excluded"}: ${_excludedIds.length}',
                              style: TextStyle(fontSize: 12, color: Colors.red[700], fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.assignment['assignment_type'] != 'employee')
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: isAr
                        ? 'بحث بالاسم / الرقم القومي / التليفون / الكود'
                        : 'Search name / national ID / phone / code',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    isDense: true,
                  ),
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kAssignColor))
                  : _filteredEmployees.isEmpty
                      ? Center(
                          child: Text(
                            isAr ? 'لا يوجد موظفون' : 'No employees',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _filteredEmployees.length,
                          itemBuilder: (_, i) => _buildEmpCard(_filteredEmployees[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpCard(Map<String, dynamic> emp) {
    final isExcluded = _excludedIds.contains(emp['id']);
    final isEmployeeType = widget.assignment['assignment_type'] == 'employee';
    final name = (emp['full_name'] ?? '').toString();
    final dept = (emp['department'] ?? '').toString();
    final branch = (emp['branch'] ?? '').toString();
    final jobTitle = (emp['job_title'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: isExcluded ? Colors.red.withValues(alpha: 0.05) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isExcluded
            ? BorderSide(color: Colors.red.withValues(alpha: 0.3))
            : BorderSide.none,
      ),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: isExcluded
              ? Colors.red.withValues(alpha: 0.15)
              : kAssignColor.withValues(alpha: 0.15),
          child: Text(
            name.isNotEmpty ? name[0] : '?',
            style: TextStyle(
              color: isExcluded ? Colors.red : kAssignColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            decoration: isExcluded ? TextDecoration.lineThrough : null,
            color: isExcluded ? Colors.red[700] : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (jobTitle.isNotEmpty)
              Text(jobTitle, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            if (dept.isNotEmpty || branch.isNotEmpty)
              Text(
                [if (dept.isNotEmpty) dept, if (branch.isNotEmpty) branch].join(' | '),
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
          ],
        ),
        trailing: isEmployeeType
            ? null
            : TextButton.icon(
                onPressed: () => _toggleExclude(emp),
                icon: Icon(
                  isExcluded ? Icons.person_add : Icons.person_off,
                  size: 16,
                  color: isExcluded ? kAssignColor : Colors.red,
                ),
                label: Text(
                  isExcluded ? (isAr ? 'إرجاع' : 'Include') : (isAr ? 'استثناء' : 'Exclude'),
                  style: TextStyle(
                    color: isExcluded ? kAssignColor : Colors.red,
                    fontSize: 11,
                  ),
                ),
              ),
      ),
    );
  }
}
