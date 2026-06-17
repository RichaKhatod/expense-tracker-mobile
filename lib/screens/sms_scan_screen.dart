import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../models/parsed_transaction.dart';
import '../providers/expense_provider.dart';
import '../services/sms_parser_service.dart';
import 'add_expense_screen.dart';

class SmsScanScreen extends StatefulWidget {
  const SmsScanScreen({super.key});

  @override
  State<SmsScanScreen> createState() => _SmsScanScreenState();
}

class _SmsScanScreenState extends State<SmsScanScreen> {
  List<ParsedTransaction> _transactions = [];
  bool _scanning = false;
  bool _hasPermission = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndScan();
  }

  Future<void> _checkPermissionAndScan() async {
    final status = await Permission.sms.status;
    if (status.isGranted) {
      setState(() => _hasPermission = true);
      await _scan();
    } else {
      setState(() => _hasPermission = false);
    }
  }

  Future<void> _requestPermissionAndScan() async {
    final status = await Permission.sms.request();
    if (status.isGranted) {
      setState(() => _hasPermission = true);
      await _scan();
    } else {
      setState(() => _error = 'SMS permission denied. Cannot scan messages.');
    }
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _error = null;
    });
    try {
      final results = await SmsParserService.scanInbox(daysBack: 30);
      setState(() => _transactions = results);
    } catch (e) {
      setState(() => _error = 'Failed to read SMS: $e');
    } finally {
      setState(() => _scanning = false);
    }
  }

  Future<void> _addSelected() async {
    final selected = _transactions.where((t) => t.isSelected).toList();
    if (selected.isEmpty) return;

    final expenses = selected.map((t) => Expense(
          amount: t.amount,
          description: t.description,
          dateOfExpense: t.date.toIso8601String().split('T').first,
          source: 'sms',
          rawSms: t.rawSms,
        )).toList();

    final ok = await context.read<ExpenseProvider>().bulkAddExpenses(expenses);
    if (mounted) {
      if (ok) {
        setState(() => _transactions.removeWhere((t) => t.isSelected));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${expenses.length} expense${expenses.length > 1 ? 's' : ''}'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add expenses'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Scan Bank SMS'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          if (_hasPermission)
            IconButton(icon: const Icon(Icons.refresh), onPressed: _scanning ? null : _scan),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _transactions.any((t) => t.isSelected)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _addSelected,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Add Selected (${_transactions.where((t) => t.isSelected).length})',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (!_hasPermission) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sms_outlined, size: 72, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('SMS Permission Required', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'This app needs to read your SMS inbox to automatically detect bank transaction messages.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _requestPermissionAndScan,
                icon: const Icon(Icons.lock_open),
                label: const Text('Grant Permission'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (_scanning) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Scanning SMS inbox...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }

    if (_transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No bank transactions found in last 30 days', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text('${_transactions.length} transaction${_transactions.length > 1 ? 's' : ''} found', style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() {
                  for (final t in _transactions) t.isSelected = true;
                }),
                child: const Text('Select All'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _transactions.length,
            itemBuilder: (ctx, i) {
              final tx = _transactions[i];
              return _TransactionCard(
                transaction: tx,
                onToggle: () => setState(() => tx.isSelected = !tx.isSelected),
                onEdit: () async {
                  final added = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => AddExpenseScreen(
                      prefilledAmount: tx.amount,
                      prefilledDescription: tx.description,
                      prefilledDate: tx.date.toIso8601String().split('T').first,
                      rawSms: tx.rawSms,
                    )),
                  );
                  if (added == true) {
                    setState(() => _transactions.removeAt(i));
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final ParsedTransaction transaction;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  const _TransactionCard({required this.transaction, required this.onToggle, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: transaction.isSelected
            ? const BorderSide(color: Color(0xFF1565C0), width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Checkbox(
                value: transaction.isSelected,
                onChanged: (_) => onToggle(),
                activeColor: const Color(0xFF1565C0),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(transaction.description, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      '${transaction.sender} • ${transaction.date.toIso8601String().split('T').first}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    Text(
                      transaction.rawSms,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${transaction.amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC62828)),
                  ),
                  TextButton(
                    onPressed: onEdit,
                    style: TextButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 4)),
                    child: const Text('Edit', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
