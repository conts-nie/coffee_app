import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'home_screen.dart' show brown, darkBrown, cream;
import '../core/pdf_service.dart';
import '../models/models.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final discountCtrl = TextEditingController();

  @override
  void dispose() {
    discountCtrl.dispose();
    super.dispose();
  }

  Future<void> placeOrder() async {
    final cart = context.read<CartProvider>();
    final order = await cart.checkout();
    if (!mounted) return;

    if (order != null) {
      final receipt = Order.fromJson(order);
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 64),
              SizedBox(height: 8),
              Text('Order placed!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(order['order_number'].toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Total: \$${order['total']}',
                  style: const TextStyle(fontSize: 18, color: brown)),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () => PdfService.printReceipt(receipt),
              icon: const Icon(Icons.print),
              label: const Text('Print receipt'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: brown),
              onPressed: () => Navigator.pop(context),
              child: const Text('New order'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } else if (cart.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(cart.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: brown,
        foregroundColor: Colors.white,
        title: const Text('Your order'),
      ),
      body: cart.items.isEmpty
          ? const Center(child: Text('Cart is empty'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...cart.items.map((i) => Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(i.product.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                      '\$${i.product.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: brown),
                              onPressed: () => cart.decrease(i.product),
                            ),
                            Text('${i.qty}',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle,
                                  color: brown),
                              onPressed: () => cart.add(i.product),
                            ),
                            SizedBox(
                              width: 60,
                              child: Text(
                                '\$${(i.product.price * i.qty).toStringAsFixed(2)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 16),
                TextField(
                  controller: discountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Discount (%)',
                    suffixText: '%',
                    prefixIcon: const Icon(Icons.percent, color: brown),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) =>
                      cart.setDiscountPercent(double.tryParse(v) ?? 0),
                ),
                const SizedBox(height: 16),
                const Text('Payment method',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'cash',
                          label: Text('Cash'),
                          icon: Icon(Icons.payments)),
                      ButtonSegment(
                          value: 'khqr',
                          label: Text('KHQR'),
                          icon: Icon(Icons.qr_code)),
                    ],
                    selected: {cart.paymentMethod},
                    onSelectionChanged: (s) => cart.setPayment(s.first),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: cart.items.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _row('Subtotal', cart.subtotal),
                    if (cart.discount > 0) _row(
                      'Discount(${cart.discountPercent % 1 == 0 ? cart.discountPercent.toStringAsFixed(0)
                        :cart.discountPercent.toStringAsFixed(1)}%)', 
                      -cart.discount),
                    const Divider(),
                    _row('Total', cart.total, bold: true),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: darkBrown,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: cart.submitting ? null : placeOrder,
                        child: cart.submitting
                            ? const SizedBox(height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Text('Place order',
                                style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _row(String label, double value, {bool bold = false}) {
    final style = TextStyle(
      fontSize: bold ? 18 : 14,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
    final text = value < 0
        ? '-\$${(-value).toStringAsFixed(2)}'
        : '\$${value.toStringAsFixed(2)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(text, style: style)],
      ),
    );
  }
}