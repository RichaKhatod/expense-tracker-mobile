class ParsedTransaction {
  final double amount;
  final String description;
  final DateTime date;
  final String rawSms;
  final String sender;
  bool isSelected;

  ParsedTransaction({
    required this.amount,
    required this.description,
    required this.date,
    required this.rawSms,
    required this.sender,
    this.isSelected = true,
  });
}
