import 'package:flutter/foundation.dart' hide Category;
import '../models/expense.dart';
import '../models/category.dart';
import '../services/api_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Expense> _expenses = [];
  List<Category> _categories = [];
  Map<String, dynamic> _summary = {};
  bool _loading = false;
  String? _error;

  List<Expense> get expenses => _expenses;
  List<Category> get categories => _categories;
  Map<String, dynamic> get summary => _summary;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadExpenses({String? month}) async {
    _setLoading(true);
    try {
      _expenses = await _api.getExpenses(month: month);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _api.getCategories();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadSummary({String? month}) async {
    try {
      _summary = await _api.getMonthlySummary(month: month);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> addExpense(Expense expense) async {
    try {
      final created = await _api.createExpense(expense);
      _expenses.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> bulkAddExpenses(List<Expense> expenses) async {
    try {
      final created = await _api.bulkCreate(expenses);
      _expenses.insertAll(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(int id) async {
    try {
      await _api.deleteExpense(id);
      _expenses.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
