import 'package:flutter/material.dart';
import '../../../services/payroll_run_service.dart';
import '../../../services/language_service.dart';

class PayrollBonusPenaltyScreen extends StatefulWidget {
  final int runId;
  final int employeeId;
  final String employeeName;

  const PayrollBonusPenaltyScreen({
    super.key,
    required this.runId,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<PayrollBonusPenaltyScreen> createState() => _PayrollBonusPenaltyScreenState();
}

class _PayrollBonusPenaltyScreenState extends State<PayrollBonusPenaltyScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _submitting = false;
  String _type = 'bonus';
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  bool get _isAr => LanguageService.currentLanguage == 'ar';

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await PayrollRunService.getBonusesPenalties(
      runId: widget.runId,
      employeeId: widget.employeeId,
    );
    if (!mounted) return;
    setState(() {
      _items = (result['adjustments'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _loading = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final result = await PayrollRunService.addAdjustment(
      runId: widget.runId,
      employeeId: widget.employeeId,
      type: _type,
      amount: double.tryParse(_amountCtrl.text.trim()) ?? 0,
      reason: _reasonCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    final ar = _isAr;
    if (result['success'] == true || result['id'] != null) {
      _amountCtrl.clear();
      _reasonCtrl.clear();
      _showSnack(ar ? 'تمت الاضافة' : 'Added successfully');
      _load();
    } else {
      _showSnack(ar ? 'فشلت العملية' : 'Operation failed', error: true);
    }
  }

  Future<void> _delete(int id) async {
    final ar = _isAr;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ar ? 'حذف؟' : 'Delete?'),
        content: Text(ar ? 'هل تريد حذف هذا البند؟' : 'Delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ar ? 'الغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ar ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final result = await PayrollRunService.deleteAdjustment(id);
    if (!mounted) return;
    if (result['success'] == true) {
      _showSnack(ar ? 'تم الحذف' : 'Deleted');
      _load();
    } else {
      _showSnack(ar ? 'فشل الحذف' : 'Delete failed', error: true);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : Colors.green,
    ));
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'bonus': return Colors.green;
      case 'penalty': return Colors.red;
      case 'installment': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _typeLabel(String type, bool ar) {
    if (ar) {
      switch (type) {
        case 'bonus': return 'مكافاة';
        case 'penalty': return 'خصم';
        case 'installment': return 'قسط';
        default: return type;
      }
    }
    switch (type) {
      case 'bonus': return 'Bonus';
      case 'penalty': return 'Penalty';
      case 'installment': return 'Installment';
      default: return type;
    }
  }

  Widget _typeChip(String type, String label, Color color) {
    final selected = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ar = _isAr;
    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(ar
              ? 'مكافات وخصومات - ${widget.employeeName}'
              : 'Bonuses & Penalties - ${widget.employeeName}'),
          centerTitle: true,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  Card(
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ar ? 'اضافة بند جديد' : 'Add New Item',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _typeChip('bonus', ar ? 'مكافاة' : 'Bonus', Colors.green),
                                const SizedBox(width: 8),
                                _typeChip('penalty', ar ? 'خصم' : 'Penalty', Colors.red),
                                const SizedBox(width: 8),
                                _typeChip('installment', ar ? 'قسط' : 'Installment', Colors.orange),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _amountCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: ar ? 'المبلغ' : 'Amount',
                                prefixIcon: const Icon(Icons.attach_money),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return ar ? 'ادخل المبلغ' : 'Enter amount';
                                if (double.tryParse(v) == null) return ar ? 'رقم غير صالح' : 'Invalid number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _reasonCtrl,
                              decoration: InputDecoration(
                                labelText: ar ? 'السبب' : 'Reason',
                                prefixIcon: const Icon(Icons.notes),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? (ar ? 'ادخل السبب' : 'Enter reason')
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _submitting ? null : _submit,
                                icon: _submitting
                                    ? const SizedBox(
                                        width: 18, height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.add),
                                label: Text(ar ? 'اضافة' : 'Add'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_items.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        ar ? 'البنود الحالية' : 'Current Items',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    ..._items.map((item) {
                      final type = item['type'] as String? ?? 'bonus';
                      final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
                      final reason = item['reason'] as String? ?? '';
                      final id = item['id'] as int? ?? 0;
                      final color = _typeColor(type);
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _typeLabel(type, ar),
                              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          title: Text(reason, style: const TextStyle(fontSize: 14)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${amount.toStringAsFixed(0)} ${ar ? 'ج.م' : 'EGP'}',
                                style: TextStyle(color: color, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                onPressed: () => _delete(id),
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 32),
                  ] else
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          ar ? 'لا توجد بنود مضافة' : 'No items added',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
