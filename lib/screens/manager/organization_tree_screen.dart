import 'package:flutter/material.dart';
import '../../services/employee_management_service.dart';
import 'package:motionhr_employee/l10n/l10n.dart';

class OrganizationTreeScreen extends StatefulWidget {
  const OrganizationTreeScreen({super.key});

  @override
  State<OrganizationTreeScreen> createState() => _OrganizationTreeScreenState();
}

class _OrganizationTreeScreenState extends State<OrganizationTreeScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _treeData;

  @override
  void initState() {
    super.initState();
    _loadTree();
  }

  Future<void> _loadTree() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await EmployeeManagementService.getOrganizationTree();
      setState(() {
        _treeData = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
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
          backgroundColor: const Color(0xFF4A148C),
          foregroundColor: Colors.white,
          title: Text(
            isAr ? 'الهيكل التنظيمي' : 'Organization Tree',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(onPressed: _loadTree, icon: const Icon(Icons.refresh)),
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
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadTree,
                          child: Text(context.l10n.retry),
                        ),
                      ],
                    ),
                  )
                : _buildTree(),
      ),
    );
  }

  Widget _buildTree() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final branches = _treeData?['branches'] as List? ?? [];
    if (branches.isEmpty) {
      return Center(child: Text(context.l10n.noData));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: branches.length,
      itemBuilder: (context, i) => _buildBranchCard(branches[i], isAr),
    );
  }

  Widget _buildBranchCard(Map<String, dynamic> branch, bool isAr) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4A148C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.business, color: Color(0xFF4A148C)),
          ),
          title: Text(
            branch['name'] ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF4A148C),
            ),
          ),
          subtitle: Text(
            isAr
                ? '${branch['departments_count'] ?? 0} إدارة • ${branch['employees_count'] ?? 0} موظف'
                : '${branch['departments_count'] ?? 0} Departments • ${branch['employees_count'] ?? 0} Employees',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          children: [
            for (var dept in (branch['departments'] as List? ?? []))
              _buildDepartmentTile(dept, isAr),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentTile(Map<String, dynamic> dept, bool isAr) {
    return Container(
      margin: const EdgeInsets.only(right: 16, left: 8, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.purple.withOpacity(0.15)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.apartment, color: Colors.blue, size: 20),
          ),
          title: Text(
            dept['name'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            isAr
                ? '${dept['managers_count'] ?? 0} مدير • ${dept['employees_count'] ?? 0} موظف'
                : '${dept['managers_count'] ?? 0} Managers • ${dept['employees_count'] ?? 0} Employees',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          children: [
            for (var manager in (dept['managers'] as List? ?? []))
              _buildManagerTile(manager, isAr),
          ],
        ),
      ),
    );
  }

  Widget _buildManagerTile(Map<String, dynamic> manager, bool isAr) {
    final subordinates = manager['subordinates'] as List? ?? [];
    return Container(
      margin: const EdgeInsets.only(right: 24, left: 8, bottom: 4, top: 2),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.green.withOpacity(0.15),
            child: const Icon(Icons.manage_accounts,
                color: Colors.green, size: 18),
          ),
          title: Text(
            manager['name'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          subtitle: Text(
            isAr
                ? '${manager['job_title'] ?? ''} • ${subordinates.length} موظف'
                : '${manager['job_title'] ?? ''} • ${subordinates.length} Employees',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          children: subordinates.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      context.l10n.noEmployees,
                      style: TextStyle(
                          color: Colors.grey[500], fontSize: 12),
                    ),
                  )
                ]
              : [
                  for (var emp in subordinates)
                    _buildEmployeeTile(emp, isAr),
                ],
        ),
      ),
    );
  }

  Widget _buildEmployeeTile(Map<String, dynamic> emp, bool isAr) {
    final isActive = emp['status'] == 'active';
    return Container(
      margin: const EdgeInsets.only(right: 32, left: 8, bottom: 3, top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.orange.withOpacity(0.15),
            child: const Icon(Icons.person, color: Colors.orange, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emp['name'] ?? '',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  emp['job_title'] ?? '',
                  style:
                      TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isActive
                  ? context.l10n.active
                  : (isAr ? 'غير نشط' : 'Inactive'),
              style: TextStyle(
                fontSize: 10,
                color: isActive ? Colors.green : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}