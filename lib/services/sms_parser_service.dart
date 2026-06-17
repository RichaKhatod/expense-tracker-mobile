import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import '../models/parsed_transaction.dart';

class SmsParserService {
  static final SmsQuery _query = SmsQuery();

  // Amount: Rs. 500.00 / Rs 500 / INR 500 / ₹500
  static final _amountRe = RegExp(
    r'(?:rs\.?\s*|inr\s*|₹\s*)(\d+(?:,\d+)*(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  // Debit keywords
  static final _debitRe = RegExp(
    r'\b(?:debited?|spent|withdrawn|deducted)\b',
    caseSensitive: false,
  );

  // Skip if only credited (no debit)
  static final _creditOnlyRe = RegExp(
    r'\bcredited\b',
    caseSensitive: false,
  );

  // Merchant: "at Amazon", "to Swiggy", "towards Zomato"
  static final _merchantRe = RegExp(
    r"(?:at|to|towards)\s+([A-Za-z0-9][A-Za-z0-9\s\-&'.]{1,30}?)(?:\s+on\b|\s+via\b|\s+ref\b|\.|,|\s*$)",
    caseSensitive: false,
  );

  // UPI: UPI/Swiggy or UPI:merchant@upi
  static final _upiRe = RegExp(
    r'upi[:/]\s*(?:\w+/)?([A-Za-z0-9\s\-&]{2,25})(?:@|\s|$)',
    caseSensitive: false,
  );

  // Date: 31-05-26 / 31/05/2026
  static final _dateRe = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})');

  // ── Public API ─────────────────────────────────────────────────────────────

  static Future<List<ParsedTransaction>> scanInbox({int daysBack = 30}) async {
    final cutoff = DateTime.now().subtract(Duration(days: daysBack));
    final messages = await _query.querySms(
      kinds: [SmsQueryKind.inbox],
      count: 500,
    );

    final results = <ParsedTransaction>[];
    for (final sms in messages) {
      if (sms.date != null && sms.date!.isBefore(cutoff)) continue;
      final parsed = _parse(sms);
      if (parsed != null) results.add(parsed);
    }
    // newest first
    results.sort((a, b) => b.date.compareTo(a.date));
    return results;
  }

  // ── Parsing ────────────────────────────────────────────────────────────────

  static ParsedTransaction? _parse(SmsMessage sms) {
    final body = sms.body ?? '';
    if (body.isEmpty) return null;

    if (!_debitRe.hasMatch(body)) return null;
    if (_creditOnlyRe.hasMatch(body) && !_debitRe.hasMatch(body)) return null;

    final amount = _extractAmount(body);
    if (amount == null || amount <= 0) return null;

    return ParsedTransaction(
      amount: amount,
      description: _extractMerchant(body),
      date: _extractDate(body) ?? (sms.date ?? DateTime.now()),
      rawSms: body,
      sender: sms.address ?? '',
    );
  }

  static double? _extractAmount(String body) {
    final m = _amountRe.firstMatch(body.toLowerCase());
    if (m == null) return null;
    return double.tryParse(m.group(1)!.replaceAll(',', ''));
  }

  static String _extractMerchant(String body) {
    final upi = _upiRe.firstMatch(body);
    if (upi != null) {
      final name = upi.group(1)!.trim();
      if (name.isNotEmpty && name.length > 2) return _titleCase(name);
    }
    final m = _merchantRe.firstMatch(body);
    if (m != null) {
      final name = m.group(1)!.trim();
      if (name.isNotEmpty) return _titleCase(name);
    }
    return 'Bank Transaction';
  }

  static DateTime? _extractDate(String body) {
    final m = _dateRe.firstMatch(body);
    if (m == null) return null;
    try {
      final day = int.parse(m.group(1)!);
      final month = int.parse(m.group(2)!);
      var year = int.parse(m.group(3)!);
      if (year < 100) year += 2000;
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  static String _titleCase(String s) =>
      s.split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
}
