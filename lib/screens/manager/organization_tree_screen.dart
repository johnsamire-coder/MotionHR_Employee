import 'package:flutter/material.dart';
import '../../services/employee_management_service.dart';

const Color kOrgPrimary = Color(0xFF4A148C);
const Color kOrgBranch = Color(0xFF6A1B9A);
const Color kOrgDept = Color(0xFF1565C0);
const Color kOrgManager = Color(0xFF2E7D32);
const Color kOrgEmployee = Color(0xFFE65100);

class OrganizationTreeScreen extends StatefulWidget {
  const OrganizationTreeScreen({super.key});
  @override
  State<OrganizationTreeScreen> createState() => _OrganizationTreeScreenState();
}

class _OrganizationTreeScreenState extends State<OrganizationTreeScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _treeData;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTree();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

  // ── Search filter ──
  bool _matchesSearch(String name, String code, String jobTitle) {
    if (_searchQuery.isEmpty) return true;
    final q = _searchQuery.toLowerCase();
    return name.toLowerCase().contains(q) ||
        code.toLowerCase().contains(q) ||
        jobTitle.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          backgroundColor: kOrgPrimary,
          foregroundColor: Colors.white,
          title: Text(
            isAr ? 'الهيكل التنظيمي' : 'Organization Tree',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadTree,
              tooltip: isAr ? 'تحديث' : 'Refresh',
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _buildBody(),
      ),
    );
  }

  Widget _buildError() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadTree,
            icon: const Icon(Icons.refresh),
            label: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: kOrgPrimary,
                foregroundColor: Colors.white),
          ),
        ]),
      );

  Widget _buildBody() {
    final company = _treeData?['company'] as Map<String, dynamic>? ?? {};
    final branches = _treeData?['branches'] as List? ?? [];

    return Column(children: [
      // ── Company Summary ──
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kOrgPrimary, Color(0xFF7B1FA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.corporate_fare, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Flexible(child: Text(
              company['name'] ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 18,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            )),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _summaryChip(Icons.people,
                '${company['total_employees'] ?? 0}',
                isAr ? 'موظف' : 'Employees'),
            _summaryChip(Icons.business,
                '${branches.length}',
                isAr ? 'فرع' : 'Branches'),
            _summaryChip(Icons.apartment,
                '${branches.fold<int>(0, (s, b) => s + ((b['departments_count'] ?? 0) as int))}',
                isAr ? 'قسم' : 'Depts'),
          ]),
        ]),
      ),

      // ── Search ──
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _searchQuery = v.trim()),
          decoration: InputDecoration(
            hintText: isAr ? 'بحث عن موظف أو وظيفة...' : 'Search employee or job...',
            prefixIcon: const Icon(Icons.search, color: kOrgPrimary),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          ),
        ),
      ),

      // ── Tree ──
      Expanded(
        child: branches.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.account_tree, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(isAr ? 'لا توجد بيانات' : 'No data',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16)),
              ]))
            : RefreshIndicator(
                onRefresh: _loadTree,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: branches.length,
                  itemBuilder: (ctx, i) => _buildBranchCard(branches[i]),
                ),
              ),
      ),
    ]);
  }

  Widget _summaryChip(IconData icon, String count, String label) => Column(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(count,
                style: const TextStyle(color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ]),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]);

  // ══════════════════════════════
  // BRANCH
  // ══════════════════════════════
  Widget _buildBranchCard(Map<String, dynamic> branch) {
    final depts = branch['departments'] as List? ?? [];
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kOrgBranch.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.business, color: kOrgBranch, size: 22),
          ),
          title: Text(branch['name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold,
                  fontSize: 15, color: kOrgBranch)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(children: [
              _miniChip(Icons.apartment,
                  '${branch['departments_count'] ?? 0} ${isAr ? 'قسم' : 'depts'}',
                  kOrgDept),
              const SizedBox(width: 8),
              _miniChip(Icons.people,
                  '${branch['employees_count'] ?? 0} ${isAr ? 'موظف' : 'emps'}',
                  Colors.grey),
              if ((branch['address'] ?? '').isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(child: _miniChip(Icons.location_on,
                    branch['address'], Colors.orange)),
              ],
            ]),
          ),
          children: depts.isEmpty
              ? [_emptyState(isAr ? 'لا توجد أقسام' : 'No departments')]
              : depts.map((d) => _buildDeptTile(d)).toList(),
        ),
      ),
    );
  }

  // ══════════════════════════════
  // DEPARTMENT
  // ══════════════════════════════
  Widget _buildDeptTile(Map<String, dynamic> dept) {
    final managers = dept['managers'] as List? ?? [];
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kOrgDept.withValues(alpha: 0.2)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kOrgDept.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.apartment, color: kOrgDept, size: 20),
          ),
          title: Text(dept['name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w700,
                  fontSize: 14, color: kOrgDept)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Row(children: [
              _miniChip(Icons.manage_accounts,
                  '${dept['managers_count'] ?? 0} ${isAr ? 'مدير' : 'mgrs'}',
                  kOrgManager),
              const SizedBox(width: 8),
              _miniChip(Icons.people,
                  '${dept['employees_count'] ?? 0} ${isAr ? 'موظف' : 'emps'}',
                  Colors.grey),
            ]),
          ),
          children: managers.isEmpty
              ? [_emptyState(isAr ? 'لا يوجد موظفون' : 'No employees')]
              : managers.map((m) => _buildManagerTile(m)).toList(),
        ),
      ),
    );
  }

  // ══════════════════════════════
  // MANAGER
  // ══════════════════════════════
  Widget _buildManagerTile(Map<String, dynamic> manager) {
    final subs = manager['subordinates'] as List? ?? [];
    final name = manager['name'] ?? '';
    final code = manager['employee_code'] ?? '';
    final jobTitle = manager['job_title'] ?? '';

    // Search filter
    bool managerMatches = _matchesSearch(name, code, jobTitle);
    final filteredSubs = _searchQuery.isEmpty
        ? subs
        : subs.where((s) => _matchesSearch(
            s['name'] ?? '', s['employee_code'] ?? '', s['job_title'] ?? '')).toList();

    if (_searchQuery.isNotEmpty && !managerMatches && filteredSubs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kOrgManager.withValues(alpha: 0.25)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _searchQuery.isNotEmpty,
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: kOrgManager.withValues(alpha: 0.15),
            child: const Icon(Icons.manage_accounts, color: kOrgManager, size: 20),
          ),
          title: Text(name,
              style: const TextStyle(fontWeight: FontWeight.w700,
                  fontSize: 13, color: kOrgManager)),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (jobTitle.isNotEmpty)
              Text(jobTitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[700])),
            if (code.isNotEmpty)
              Text(code,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ]),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: kOrgManager.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${filteredSubs.length} ${isAr ? 'موظف' : 'emps'}',
                style: const TextStyle(fontSize: 11, color: kOrgManager,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ]),
          children: filteredSubs.isEmpty
              ? [_emptyState(isAr ? 'لا يوجد موظفون مباشرون' : 'No direct reports')]
              : filteredSubs.map((e) => _buildEmployeeTile(e)).toList(),
        ),
      ),
    );
  }

  // ══════════════════════════════
  // EMPLOYEE
  // ══════════════════════════════
  Widget _buildEmployeeTile(Map<String, dynamic> emp) {
    final isActive = emp['status'] == 'active';
    final name = emp['name'] ?? '';
    final code = emp['employee_code'] ?? '';
    final jobTitle = emp['job_title'] ?? '';

    if (_searchQuery.isNotEmpty && !_matchesSearch(name, code, jobTitle)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 8, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        )],
      ),
      child: Row(children: [
        // Avatar
        CircleAvatar(
          radius: 16,
          backgroundColor: kOrgEmployee.withValues(alpha: 0.12),
          child: Text(
            name.isNotEmpty ? name[0] : '?',
            style: const TextStyle(color: kOrgEmployee, fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
        ),
        const SizedBox(width: 10),
        // Info
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          if (jobTitle.isNotEmpty)
            Text(jobTitle,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          if (code.isNotEmpty)
            Text(code,
                style: TextStyle(fontSize: 10, color: Colors.grey[400])),
        ])),
        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            isActive
                ? (isAr ? 'نشط' : 'Active')
                : (isAr ? 'غير نشط' : 'Inactive'),
            style: TextStyle(
              fontSize: 10,
              color: isActive ? Colors.green[700] : Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ]),
    );
  }

  // ══════════════════════════════
  // HELPERS
  // ══════════════════════════════
  Widget _miniChip(IconData icon, String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Flexible(child: Text(label,
              style: TextStyle(fontSize: 11, color: color),
              overflow: TextOverflow.ellipsis)),
        ],
      );

  Widget _emptyState(String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Text(msg, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ]),
      );
}
