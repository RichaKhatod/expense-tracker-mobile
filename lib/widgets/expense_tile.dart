import 'package:flutter/material.dart';
import '../models/expense.dart';

class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onDelete;

  const ExpenseTile({super.key, required this.expense, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: expense.source == 'sms'
              ? const Color(0xFF1565C0).withOpacity(0.1)
              : const Color(0xFF43A047).withOpacity(0.1),
          child: Icon(
            expense.source == 'sms' ? Icons.sms_outlined : Icons.edit_outlined,
            color: expense.source == 'sms' ? const Color(0xFF1565C0) : const Color(0xFF43A047),
          ),
        ),
        title: Text(
          expense.description ?? 'Expense',
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (expense.categoryName != null)
              Text(expense.categoryName!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            Text(
              expense.dateOfExpense ?? '',
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${expense.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFFC62828),
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
