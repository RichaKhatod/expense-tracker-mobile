class Expense {
  final int? id;
  final double amount;
  final String? description;
  final String? dateOfExpense;
  final int? category;
  final String? categoryName;
  final String source;
  final String? rawSms;
  final String? createdAt;

  Expense({
    this.id,
    required this.amount,
    this.description,
    this.dateOfExpense,
    this.category,
    this.categoryName,
    this.source = 'manual',
    this.rawSms,
    this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'],
        amount: double.parse(json['amount'].toString()),
        description: json['description'],
        dateOfExpense: json['date_of_expense'],
        category: json['category'],
        categoryName: json['category_name'],
        source: json['source'] ?? 'manual',
        rawSms: json['raw_sms'],
        createdAt: json['created_at'],
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'amount': amount,
        if (description != null) 'description': description,
        if (dateOfExpense != null) 'date_of_expense': dateOfExpense,
        if (category != null) 'category': category,
        'source': source,
        if (rawSms != null) 'raw_sms': rawSms,
      };
}
