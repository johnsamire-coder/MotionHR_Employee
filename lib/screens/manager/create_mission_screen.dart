import 'package:flutter/material.dart';
import '../../services/missions_service.dart';
import '../../services/employee_management_service.dart';
import 'package:motionhr_employee/l10n/l10n.dart';

class CreateMissionScreen extends StatefulWidget {
  const CreateMissionScreen({super.key});
  @override
  State<CreateMissionScreen> createState() => _CreateMissionScreenState();
}

class _CreateMissionScreenState extends State<CreateMissionScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _loadingEmployees = true;
  List<dynamic> _employees = [];

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _clientNameCtrl = TextEditingController();
  final _clientPhoneCtrl = TextEditingController();
  final _clientCompanyCtrl = TextEditingController();
  final _clientEmailCtrl = TextEditingController();

  String _priority = 'normal';
  DateTime? _startTime;
  DateTime? _endTime;
  List<Map<String, dynamic>> _selectedAssignees = [];

  Map<String, String> get _priorityLabels => {
        'normal': isAr ? 'عادي' : 'Normal',
        'high': isAr ? 'عالي' : 'High',
        'urgent': isAr ? 'عاجل' : 'Urgent',
      };

  final Map<String, Color> _priorityColors = {
    'normal': Colors.blue,
    'high': Colors.orange,
    'urgent': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _clientNameCtrl.dispose();
    _clientPhoneCtrl.dispose();
    _clientCompanyCtrl.dispose();
    _clientEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    try {
      final result = await EmployeeManagementService.getEmployeesSimple();
      setState(() {
        _employees = result;
        _loadingEmployees = false;
      });
    } catch (_) {
      setState(() => _loadingEmployees = false);
    }
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    final dt = DateTime(
        date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startTime = dt;
      } else {
        _endTime = dt;
      }
    });
  }

  void _showAddAssigneeDialog() {
    String? selectedEmployeeId;
    String selectedRole = 'lead';
    bool isLead = _selectedAssignees.isEmpty;

    final availableEmployees = _employees.where((e) {
      final id = e['id'].toString();
      return !_selectedAssignees
          .any((a) => a['employee_id'].toString() == id);
    }).toList();

    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(isAr ? 'إضافة مشارك' : 'Add Participant'),
          content: StatefulBuilder(
            builder: (ctx, setDialogState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: isAr ? 'اختر الموظف' : 'Select Employee',
                  ),
                  items: availableEmployees
                      .map<DropdownMenuItem<String>>((e) {
                    return DropdownMenuItem<String>(
                      value: e['id'].toString(),
                      child: Text(
                          e['full_name_ar'] ?? e['username'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedEmployeeId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: isAr ? 'الدور' : 'Role',
                  ),
                  items: [
                    DropdownMenuItem(
                        value: 'lead',
                        child: Text(context.l10n.missionLead)),
                    DropdownMenuItem(
                        value: 'assistant',
                        child: Text(context.l10n.assistant)),
                    DropdownMenuItem(
                        value: 'manager',
                        child: Text(
                            isAr ? 'مدير مرافق' : 'Accompanied Manager')),
                    DropdownMenuItem(
                        value: 'trainee',
                        child:
                            Text(isAr ? 'متدرب' : 'Trainee')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => selectedRole = v!),
                ),
                if (_selectedAssignees.isNotEmpty)
                  CheckboxListTile(
                    title: Text(context.l10n.missionLead),
                    value: isLead,
                    onChanged: (v) =>
                        setDialogState(() => isLead = v!),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.cancel),
            ),
            ElevatedButton(
              onPressed: selectedEmployeeId == null
                  ? null
                  : () {
                      final emp = _employees.firstWhere(
                        (e) =>
                            e['id'].toString() == selectedEmployeeId,
                      );
                      setState(() {
                        _selectedAssignees.add({
                          'employee_id':
                              int.parse(selectedEmployeeId!),
                          'employee_name': emp['full_name_ar'] ??
                              emp['username'],
                          'role': selectedRole,
                          'is_lead': isLead ||
                              _selectedAssignees.isEmpty,
                        });
                      });
                      Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C3FC5),
              ),
              child: Text(context.l10n.add,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr
            ? 'يرجى تحديد وقت البدء والانتهاء'
            : 'Please set start and end time'),
      ));
      return;
    }
    if (_selectedAssignees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr
            ? 'يرجى إضافة موظف واحد على الأقل'
            : 'Please add at least one employee'),
      ));
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await MissionsService.createMission(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        priority: _priority,
        plannedStartTime: _startTime!.toIso8601String(),
        plannedEndTime: _endTime!.toIso8601String(),
        locationName: _locationCtrl.text.trim(),
        clientName: _clientNameCtrl.text.trim(),
        clientPhone: _clientPhoneCtrl.text.trim(),
        clientCompany: _clientCompanyCtrl.text.trim(),
        clientEmail: _clientEmailCtrl.text.trim(),
        assignees: _selectedAssignees
            .map((a) => {
                  'employee_id': a['employee_id'],
                  'role': a['role'],
                  'is_lead': a['is_lead'],
                })
            .toList(),
      );
      if (!mounted) return;
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr
              ? '✅ تم إنشاء المهمة بنجاح'
              : '✅ Mission created successfully'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['error'] ??
              (isAr ? 'حدث خطأ' : 'An error occurred')),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              isAr ? 'حدث خطأ في الاتصال' : 'Connection error'),
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            isAr ? 'إنشاء مهمة جديدة' : 'Create New Mission',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF6C3FC5),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF6C3FC5)))
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _sectionCard(
                      title: isAr ? 'بيانات المهمة' : 'Mission Info',
                      icon: Icons.assignment,
                      children: [
                        TextFormField(
                          controller: _titleCtrl,
                          decoration: InputDecoration(
                            labelText: isAr
                                ? 'عنوان المهمة *'
                                : 'Mission Title *',
                            prefixIcon: const Icon(Icons.title),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? (isAr
                                  ? 'العنوان مطلوب'
                                  : 'Title is required')
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: context.l10n.missionDetails,
                            prefixIcon:
                                const Icon(Icons.description),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children:
                              _priorityLabels.entries.map((entry) {
                            final isSelected =
                                _priority == entry.key;
                            final color =
                                _priorityColors[entry.key]!;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _priority = entry.key),
                                child: Container(
                                  margin:
                                      const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color.withOpacity(0.15)
                                        : Colors.grey.shade100,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? color
                                          : Colors.grey.shade300,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.flag,
                                          color: color, size: 20),
                                      const SizedBox(height: 4),
                                      Text(
                                        entry.value,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: color,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _sectionCard(
                      title: isAr ? 'التوقيت' : 'Timing',
                      icon: Icons.schedule,
                      children: [
                        _timePicker(
                          label:
                              isAr ? 'وقت البدء' : 'Start Time',
                          value: _startTime,
                          onTap: () =>
                              _pickDateTime(isStart: true),
                        ),
                        const SizedBox(height: 12),
                        _timePicker(
                          label: isAr
                              ? 'وقت الانتهاء'
                              : 'End Time',
                          value: _endTime,
                          onTap: () =>
                              _pickDateTime(isStart: false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _sectionCard(
                      title: isAr
                          ? 'الموقع والعميل'
                          : 'Location & Client',
                      icon: Icons.location_on,
                      children: [
                        TextFormField(
                          controller: _locationCtrl,
                          decoration: InputDecoration(
                            labelText: isAr
                                ? 'اسم الموقع / العنوان'
                                : 'Location / Address',
                            prefixIcon:
                                const Icon(Icons.place),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _clientNameCtrl,
                          decoration: InputDecoration(
                            labelText: context.l10n.clientName,
                            prefixIcon:
                                const Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _clientPhoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: context.l10n.clientPhone,
                            prefixIcon:
                                const Icon(Icons.phone),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _clientCompanyCtrl,
                          decoration: InputDecoration(
                            labelText: isAr
                                ? 'شركة العميل'
                                : 'Client Company',
                            prefixIcon:
                                const Icon(Icons.business),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _clientEmailCtrl,
                          keyboardType:
                              TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: isAr
                                ? 'إيميل العميل'
                                : 'Client Email',
                            prefixIcon:
                                const Icon(Icons.email),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _sectionCard(
                      title: isAr ? 'المشاركون' : 'Participants',
                      icon: Icons.group,
                      children: [
                        if (_loadingEmployees)
                          const Center(
                              child: CircularProgressIndicator())
                        else ...[
                          ..._selectedAssignees.map((a) => ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(
                                          0xFF6C3FC5)
                                      .withOpacity(0.15),
                                  child: const Icon(Icons.person,
                                      color: Color(0xFF6C3FC5)),
                                ),
                                title:
                                    Text(a['employee_name'] ?? ''),
                                subtitle:
                                    Text(_roleLabel(a['role'])),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (a['is_lead'] == true)
                                      const Icon(Icons.star,
                                          color: Colors.amber,
                                          size: 18),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle,
                                          color: Colors.red),
                                      onPressed: () => setState(() =>
                                          _selectedAssignees
                                              .remove(a)),
                                    ),
                                  ],
                                ),
                              )),
                          TextButton.icon(
                            onPressed: _employees.isNotEmpty
                                ? _showAddAssigneeDialog
                                : null,
                            icon: const Icon(Icons.add,
                                color: Color(0xFF6C3FC5)),
                            label: Text(
                              isAr
                                  ? 'إضافة مشارك'
                                  : 'Add Participant',
                              style: const TextStyle(
                                  color: Color(0xFF6C3FC5)),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C3FC5),
                        padding: const EdgeInsets.symmetric(
                            vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
                      ),
                      child: Text(
                        isAr ? 'إنشاء المهمة' : 'Create Mission',
                        style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon,
                  color: const Color(0xFF6C3FC5), size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF6C3FC5))),
            ]),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _timePicker({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          const Icon(Icons.access_time,
              color: Color(0xFF6C3FC5)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value == null
                  ? label
                  : '${value.day}/${value.month}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: value == null
                    ? Colors.grey
                    : Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
          const Icon(Icons.arrow_drop_down,
              color: Colors.grey),
        ]),
      ),
    );
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'lead':
        return context.l10n.missionLead;
      case 'assistant':
        return context.l10n.assistant;
      case 'manager':
        return isAr ? 'مدير مرافق' : 'Accompanied Manager';
      case 'trainee':
        return isAr ? 'متدرب' : 'Trainee';
      default:
        return role ?? '';
    }
  }
}