import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../services/auth_service.dart';
import 'expenses_screen.dart';
import 'sms_scan_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    _DashboardTab(),
    ExpensesScreen(),
    SmsScanScreen(),
  ];

  Future<void> _logout() async {
    await AuthService().clearTokens();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Expenses'),
          NavigationDestination(icon: Icon(Icons.sms_outlined), selectedIcon: Icon(Icons.sms), label: 'Scan SMS'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().clearTokens();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (_, provider, __) {
          final summary = provider.summary;
          final total = summary['total'] ?? 0;
          final count = summary['count'] ?? 0;
          final byCategory = summary['by_category'] as List? ?? [];

          return RefreshIndicator(
            onRefresh: () => provider.loadSummary(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryCard(total: total.toDouble(), count: count),
                const SizedBox(height: 16),
                if (byCategory.isNotEmpty) ...[
                  const Text('By Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...byCategory.map((c) => _CategoryRow(
                        name: c['category__category_name'] ?? 'Uncategorized',
                        total: double.parse(c['total'].toString()),
                        overallTotal: total.toDouble(),
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double total;
  final int count;

  const _SummaryCard({required this.total, required this.count});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthName = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][now.month - 1];
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF1565C0),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$monthName ${now.year}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('$count expense${count != 1 ? 's' : ''} this month', style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String name;
  final double total;
  final double overallTotal;

  const _CategoryRow({required this.name, required this.total, required this.overallTotal});

  @override
  Widget build(BuildContext context) {
    final pct = overallTotal > 0 ? total / overallTotal : 0.0;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC62828))),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.grey[200],
              color: const Color(0xFF1565C0),
              minHeight: 6,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}
