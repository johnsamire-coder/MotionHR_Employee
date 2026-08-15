import 'package:flutter/material.dart';
import '../../services/hierarchy_service.dart';

class HierarchyTreeScreen extends StatefulWidget {
  const HierarchyTreeScreen({super.key});

  @override
  State<HierarchyTreeScreen> createState() => _HierarchyTreeScreenState();
}

class _HierarchyTreeScreenState extends State<HierarchyTreeScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;
  final Set<int> _expanded = {};
  String _search = '';
  final _searchCtrl = TextEditingController();

  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await HierarchyService.getHierarchyTree();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
        // فتح الطبقة الأولى تلقائياً
        final root = data['root'] as List<dynamic>? ?? [];
        for (final r in root) {
          _expanded.add(r['id'] as int);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _toggle(int id) {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
      } else {
        _expanded.add(id);
      }
    });
  }

  void _expandAll() {
    if (_data == null) return;
    final all = <int>{};
    void collect(List<dynamic> nodes) {
      for (final n in nodes) {
        all.add(n['id'] as int);
        collect((n['children'] as List<dynamic>?) ?? []);
      }
    }
    collect(_data!['root'] as List<dynamic>);
    setState(() => _expanded.addAll(all));
  }

  void _collapseAll() {
    setState(() => _expanded.clear());
  }

  bool _matchesSearch(Map<String, dynamic> node) {
    if (_search.isEmpty) return true;
    final name = (isAr ? node['name_ar'] : node['name_en']) as String? ?? '';
    final code = node['employee_code'] as String? ?? '';
    final q = _search.toLowerCase();
    if (name.toLowerCase().contains(q) || code.toLowerCase().contains(q)) return true;
    final children = (node['children'] as List<dynamic>?) ?? [];
    return children.any((c) => _matchesSearch(c as Map<String, dynamic>));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C3FC5),
        foregroundColor: Colors.white,
        title: Text(isAr ? 'الهيكل التنظيمي' : 'Organization Chart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.unfold_more),
            tooltip: isAr ? 'توسيع الكل' : 'Expand All',
            onPressed: _expandAll,
          ),
          IconButton(
            icon: const Icon(Icons.unfold_less),
            tooltip: isAr ? 'طي الكل' : 'Collapse All',
            onPressed: _collapseAll,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Stats + Search
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.grey.shade50,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _statCard(
                                  Icons.business,
                                  isAr ? 'الشركة' : 'Company',
                                  _data?['company_name'] ?? '',
                                  Colors.deepPurple,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _statCard(
                                  Icons.people,
                                  isAr ? 'الموظفين' : 'Employees',
                                  '${_data?['total_employees'] ?? 0}',
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _search = v),
                            decoration: InputDecoration(
                              hintText: isAr ? 'ابحث بالاسم أو الكود...' : 'Search...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tree
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.all(12),
                          children: [
                            ...((_data?['root'] as List<dynamic>? ?? [])
                                .map((n) => _buildNode(n as Map<String, dynamic>, 0))
                                .toList()),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.7))),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNode(Map<String, dynamic> node, int level) {
    if (!_matchesSearch(node)) return const SizedBox.shrink();

    final id = node['id'] as int;
    final name = (isAr ? node['name_ar'] : node['name_en']) as String? ?? '';
    final job = (isAr ? node['job_title_ar'] : node['job_title_en']) as String? ?? '';
    final code = node['employee_code'] as String? ?? '';
    final dept = node['department'] as String? ?? '';
    final role = node['role'] as String? ?? 'employee';
    final teamSize = node['team_size'] as int? ?? 0;
    final children = (node['children'] as List<dynamic>?) ?? [];
    final hasChildren = children.isNotEmpty;
    final isExpanded = _expanded.contains(id);

    final isOwner = role == 'company_admin' || role == 'super_admin' || role == 'owner';
    final isManager = role == 'manager' || hasChildren;

    final cardColor = isOwner
        ? Colors.amber.shade50
        : isManager
            ? const Color(0xFFEDE7F6)
            : Colors.grey.shade50;

    final borderColor = isOwner
        ? Colors.amber.shade300
        : isManager
            ? Colors.deepPurple.shade200
            : Colors.grey.shade300;

    final iconColor = isOwner
        ? Colors.amber.shade700
        : isManager
            ? Colors.deepPurple
            : Colors.blueGrey;

    return Padding(
      padding: EdgeInsets.only(
        right: isAr ? (level * 24.0) : 0,
        left: isAr ? 0 : (level * 24.0),
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Row(
              children: [
                if (hasChildren)
                  InkWell(
                    onTap: () => _toggle(id),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        isExpanded ? Icons.expand_more : Icons.chevron_right,
                        size: 20,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 28),

                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: isOwner
                        ? Icon(Icons.workspace_premium, color: iconColor, size: 20)
                        : isManager
                            ? Icon(Icons.badge, color: iconColor, size: 18)
                            : Text(
                                name.isNotEmpty ? name[0] : 'U',
                                style: TextStyle(
                                  color: iconColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                  ),
                ),
                const SizedBox(width: 10),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (isOwner)
                            _badge(isAr ? 'صاحب الشركة' : 'Owner', Colors.amber.shade700),
                          if (!isOwner && isManager)
                            _badge(isAr ? 'مدير' : 'Manager', Colors.deepPurple),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [code, job, dept].where((s) => s.isNotEmpty).join(' • '),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Team count
                if (hasChildren)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.group, size: 12, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text(
                          '$teamSize',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Children
          if (hasChildren && isExpanded) ...[
            const SizedBox(height: 6),
            ...children.map((c) => _buildNode(c as Map<String, dynamic>, level + 1)),
          ],
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
