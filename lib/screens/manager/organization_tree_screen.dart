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
    setState(() { _loading = true; _error = null; });
    try {
      final data = await EmployeeManagementService.getOrganizationTree();
      setState(() { _treeData = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
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
          title: Text('الهيكل التنظيمي', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(onPressed: _loadTree, icon: Icon(Icons.refresh)),
          ],
        ),
        body: _loading
            ? Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center),
                        SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadTree, child: Text(context.l10n.retry)),
                      ],
                    ),
                  )
                : _buildTree(),
      ),
    );
  }

  Widget _buildTree() {
    final branches = _treeData?['branches'] as List? ?? [];
    if (branches.isEmpty) {
      return Center(child: Text(context.l10n.noData));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: branches.length,
      itemBuilder: (context, i) => _buildBranchCard(branches[i]),
    );
  }

  Widget _buildBranchCard(Map<String, dynamic> branch) {
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
              color: const Color(0xFF4A148C).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.business, color: Color(0xFF4A148C)),
          ),
          title: Text(
            branch['name'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF4A148C)),
          ),
          subtitle: Text(
            '${branch['departments_count'] ?? 0} إدارة • ${branch['employees_count'] ?? 0} موظف',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          children: [
            for (var dept in (branch['departments'] as List? ?? []))
              _buildDepartmentTile(dept),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentTile(Map<String, dynamic> dept) {
    return Container(
      margin: const EdgeInsets.only(right: 16, left: 8, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.15)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.apartment, color: Colors.blue, size: 20),
          ),
          title: Text(
            dept['name'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            '${dept['managers_count'] ?? 0} مدير • ${dept['employees_count'] ?? 0} موظف',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          children: [
            for (var manager in (dept['managers'] as List? ?? []))
              _buildManagerTile(manager),
          ],
        ),
      ),
    );
  }

  Widget _buildManagerTile(Map<String, dynamic> manager) {
    final subordinates = manager['subordinates'] as List? ?? [];
    return Container(
      margin: const EdgeInsets.only(right: 24, left: 8, bottom: 4, top: 2),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.green.withValues(alpha: 0.15),
            child: Icon(Icons.manage_accounts, color: Colors.green, size: 18),
          ),
          title: Text(
            manager['name'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          subtitle: Text(
            '${manager['job_title'] ?? ''} • ${subordinates.length} موظف',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          children: subordinates.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(context.l10n.noEmployees, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  )
                ]
              : [
                  for (var emp in subordinates)
                    _buildEmployeeTile(emp),
                ],
        ),
      ),
    );
  }

  Widget _buildEmployeeTile(Map<String, dynamic> emp) {
    return Container(
      margin: const EdgeInsets.only(right: 32, left: 8, bottom: 3, top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.orange.withValues(alpha: 0.15),
            child: Icon(Icons.person, color: Colors.orange, size: 16),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emp['name'] ?? '',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  emp['job_title'] ?? '',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: emp['status'] == 'active'
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              emp['status'] == 'active' ? context.l10n.active : 'غير نشط',
              style: TextStyle(
                fontSize: 10,
                color: emp['status'] == 'active' ? Colors.green : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}