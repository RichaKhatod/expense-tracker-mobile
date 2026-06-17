import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  final double? prefilledAmount;
  final String? prefilledDescription;
  final String? prefilledDate;
  final String? rawSms;

  const AddExpenseScreen({
    super.key,
    this.prefilledAmount,
    this.prefilledDescription,
    this.prefilledDate,
    this.rawSms,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _dateCtrl;
  int? _selectedCategory;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: widget.prefilledAmount?.toStringAsFixed(2) ?? '');
    _descCtrl = TextEditingController(text: widget.prefilledDescription ?? '');
    _dateCtrl = TextEditingController(
      text: widget.prefilledDate ?? DateTime.now().toIso8601String().split('T').first,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadCategories();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateCtrl.text) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dateCtrl.text = picked.toIso8601String().split('T').first;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final expense = Expense(
      amount: double.parse(_amountCtrl.text),
      description: _descCtrl.text.trim(),
      dateOfExpense: _dateCtrl.text,
      category: _selectedCategory,
      source: widget.rawSms != null ? 'sms' : 'manual',
      rawSms: widget.rawSms,
    );

    final ok = await context.read<ExpenseProvider>().addExpense(expense);
    if (mounted) {
      setState(() => _loading = false);
      if (ok) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save expense'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.rawSms != null ? 'Confirm SMS Expense' : 'Add Expense'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (widget.rawSms != null)
              Card(
                color: const Color(0xFFE3F2FD),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.sms, size: 16, color: Color(0xFF1565C0)),
                        SizedBox(width: 6),
                        Text('Detected from SMS', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1565C0))),
                      ]),
                      const SizedBox(height: 6),
                      Text(widget.rawSms!, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                    ],
                  ),
                ),
              ),
            if (widget.rawSms != null) const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount (₹)',
                          prefixIcon: Icon(Icons.currency_rupee),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) return 'Enter a valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Description / Merchant',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _dateCtrl,
                        readOnly: true,
                        onTap: _pickDate,
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Consumer<ExpenseProvider>(
                        builder: (_, provider, __) {
                          return DropdownButtonFormField<int>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Category (optional)',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('None')),
                              ...provider.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.categoryName))),
                            ],
                            onChanged: (v) => setState(() => _selectedCategory = v),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _loading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Save Expense', style: TextStyle(fontSize: 16, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
