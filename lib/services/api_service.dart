import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/expense.dart';
import '../models/category.dart';

class ApiService {
  // For Android emulator use 10.0.2.2; for a real device use your PC's local IP
  // e.g. http://192.168.1.5:8000/api
  static const String baseUrl = 'http://192.168.29.128:8000/api';

  final AuthService _auth = AuthService();

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final h = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _auth.getAccessToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  // ── Auth ───────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body['detail'] ?? 'Login failed');
  }

  Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'email': email, 'password': password}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 201) return body;
    // Return first validation message
    final errors = body as Map<String, dynamic>;
    final msg = errors.values.first;
    throw Exception(msg is List ? msg.first : msg.toString());
  }

  // ── Expenses ───────────────────────────────────────────────────────────────

  Future<List<Expense>> getExpenses({String? month}) async {
    final uri = Uri.parse('$baseUrl/expenses/')
        .replace(queryParameters: month != null ? {'month': month} : null);
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] as List? ?? []);
      return list.map((e) => Expense.fromJson(e)).toList();
    }
    if (res.statusCode == 401) throw Exception('Unauthorized');
    throw Exception('Failed to load expenses');
  }

  Future<Expense> createExpense(Expense expense) async {
    final res = await http.post(
      Uri.parse('$baseUrl/expenses/'),
      headers: await _headers(),
      body: jsonEncode(expense.toJson()),
    );
    if (res.statusCode == 201) return Expense.fromJson(jsonDecode(res.body));
    throw Exception('Failed to create expense: ${res.body}');
  }

  Future<List<Expense>> bulkCreate(List<Expense> expenses) async {
    final res = await http.post(
      Uri.parse('$baseUrl/expenses/bulk/'),
      headers: await _headers(),
      body: jsonEncode(expenses.map((e) => e.toJson()).toList()),
    );
    if (res.statusCode == 201) {
      return (jsonDecode(res.body) as List).map((e) => Expense.fromJson(e)).toList();
    }
    throw Exception('Failed to bulk create expenses');
  }

  Future<void> deleteExpense(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/expenses/$id/'),
      headers: await _headers(),
    );
    if (res.statusCode != 204) throw Exception('Failed to delete expense');
  }

  Future<List<Category>> getCategories() async {
    final res = await http.get(Uri.parse('$baseUrl/categories/'), headers: await _headers());
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).map((e) => Category.fromJson(e)).toList();
    }
    throw Exception('Failed to load categories');
  }

  Future<Map<String, dynamic>> getMonthlySummary({String? month}) async {
    final uri = Uri.parse('$baseUrl/summary/')
        .replace(queryParameters: month != null ? {'month': month} : null);
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load summary');
  }
}
