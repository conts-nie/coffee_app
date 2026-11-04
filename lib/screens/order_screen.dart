import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/models.dart';
import 'home_screen.dart' show brown, darkBrown, cream;
import '../core/pdf_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> orders = [];
  bool loading = true;
  String? error;
  DateTime? date;

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
      final res = await ApiClient.dio.get('/orders', queryParameters: {
        if (date != null) 'date': date!.toIso8601String().substring(0, 10),
      });
      orders = (res.data as List).map((e) => Order.fromJson(e)).toList();
    } catch (e) {
      error = 'Failed to load orders';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: date ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      date = d;
      load();
    }
  }

  String two(int n) => n.toString().padLeft(2, '0');
  String fmt(DateTime d) =>
      '${d.year}-${two(d.month)}-${two(d.day)}  ${two(d.hour)}:${two(d.minute)}';

  void showDetail(Order o) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(o.orderNumber,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            Text(fmt(o.createdAt),
                style: TextStyle(color: Colors.grey.shade600)),
            const Divider(height: 24),
            ...o.items.map((i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(child: Text('${i.qty} x ${i.name}')),
                      Text('\$${i.lineTotal.toStringAsFixed(2)}'),
                    ],
                  ),
                )),
            const Divider(height: 24),
            _line('Subtotal', o.subtotal),
            if (o.discount > 0) _line('Discount', -o.discount),
            _line('Total', o.total, bold: true),
            const SizedBox(height: 8),
            Text('Paid by ${o.paymentMethod.toUpperCase()}'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => PdfService.saveReceipt(o),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Save PDF'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: brown),
                    onPressed: () => PdfService.printReceipt(o),
                    icon: const Icon(Icons.print),
                    label: const Text('Print receipt'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, double v, {bool bold = false}) {
    final s = TextStyle(
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        fontSize: bold ? 17 : 14);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: s),
        Text(v < 0 ? '-\$${(-v).toStringAsFixed(2)}' : '\$${v.toStringAsFixed(2)}',
            style: s),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: brown,
        foregroundColor: Colors.white,
        title: const Text('Order history'),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_month), onPressed: pickDate),
          if (date != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                date = null;
                load();
              },
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,children: [
                      Text(error!),
                      TextButton(onPressed: load, child: const Text('Retry')),
                    ],
                  ),
                )
              : orders.isEmpty
                  ? const Center(child: Text('No orders'))
                  : RefreshIndicator(
                      onRefresh: load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: orders.length,
                        itemBuilder: (_, i) {
                          final o = orders[i];
                          final cancelled = o.status == 'cancelled';
                          return Card(
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            child: ListTile(
                              onTap: () => showDetail(o),
                              leading: CircleAvatar(
                                backgroundColor: cancelled
                                    ? Colors.red.shade50
                                    : const Color(0xFFF7F2EC),
                                child: Icon(
                                  cancelled ? Icons.block : Icons.receipt_long,
                                  color: cancelled ? Colors.red : brown,
                                ),
                              ),
                              title: Text(o.orderNumber,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  '${fmt(o.createdAt)}\n${o.items.length} items · ${o.paymentMethod.toUpperCase()}'),
                              isThreeLine: true,
                              trailing: Text(
                                '\$${o.total.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: cancelled ? Colors.grey : darkBrown,
                                  decoration: cancelled
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}