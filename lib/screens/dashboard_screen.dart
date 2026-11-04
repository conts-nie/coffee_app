import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'order_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? data;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await ApiClient.dio.get('/dashboard/today');
      data = Map<String, dynamic>.from(res.data);
    } catch (e) {
      error = 'Failed to load dashboard';
    }
    if (mounted) setState(() => loading = false);
  }

  double _d(dynamic v) => double.tryParse(v.toString()) ?? 0;
  String _two(int n) => n.toString().padLeft(2, '0');
  String _time(String iso) {
    final d = DateTime.parse(iso).toLocal();
    return '${_two(d.hour)}:${_two(d.minute)}';
  }

  Widget _stat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFF7F2EC),
              child: Icon(icon, color: brown),
            ),
            const SizedBox(height: 12),
            Text(value,
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: darkBrown)),
            Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _chart(List top) {
    if (top.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text('No sales yet today')),
      );
    }
    final maxQty =
        top.map((e) => _d(e['qty_sold'])).reduce((a, b) => a > b ? a : b);

    return Column(
      children: top.map<Widget>((e) {
        final qty = _d(e['qty_sold']);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(e['product_name'].toString(),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text('${qty.toInt()} sold',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: maxQty == 0 ? 0 : qty / maxQty,
                  minHeight: 10,
                  color: brown,
                  backgroundColor: const Color(0xFFF1E9E0),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _table(List recent) {
    if (recent.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text('No transactions yet today')),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 22,
        horizontalMargin: 0,
        headingRowHeight: 40,
        columns: const [
          DataColumn(label: Text('Order')),
          DataColumn(label: Text('Time')),
          DataColumn(label: Text('Pay')),
          DataColumn(label: Text('Total'), numeric: true),
        ],
        rows: recent.map<DataRow>((o) {
          final short = o['order_number'].toString().split('-').last;
          return DataRow(cells: [
            DataCell(Text('#$short')),
            DataCell(Text(_time(o['created_at']))),
            DataCell(Text(o['payment_method'].toString().toUpperCase())),
            DataCell(Text('\$${_d(o['total']).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold))),
          ]);
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: cream,
      
      appBar: AppBar(
        backgroundColor: brown,
        foregroundColor: Colors.white,
        title: const Text('Dashboard'),
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   backgroundColor: brown,
      //   foregroundColor: Colors.white,
      //   icon: const Icon(Icons.add_shopping_cart),
      //   label: const Text('New order'),
      //   onPressed: () async {
      //     await Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (_) => const HomeScreen()),
      //     );
      //     load();
      //   },
      // ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error!),
                      TextButton(onPressed: load, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      Text(
                        'Hello, ${auth.user?['name'] ?? ''}',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text("Today's summary · ${data!['date']}",
                          style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _stat('Products sold', '${data!['items_sold']}',
                              Icons.local_cafe),
                          const SizedBox(width: 12),
                          _stat('Orders today', '${data!['orders_count']}',
                              Icons.receipt_long),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _card(
                        title: 'Top sellers today',
                        child: _chart(data!['top_products'] as List),
                      ),
                      const SizedBox(height: 16),
                      _card(title: 'Recent transactions',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _table(data!['recent'] as List),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const OrdersScreen()),
                                ),
                                child: const Text('View all'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}