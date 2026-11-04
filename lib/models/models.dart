class MenuCategory {
  final int id;
  final String name;
  MenuCategory({required this.id, required this.name});

  factory MenuCategory.fromJson(Map<String, dynamic> j) =>
      MenuCategory(id: j['id'], name: j['name']);
}

class Product {
  final String ? imageUrl;
  final int id;
  final int categoryId;
  final String name;
  final double price;
  final bool isAvailable;

  Product({
    this.imageUrl,
    required this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    required this.isAvailable,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        imageUrl: j['image_url'],

        id: j['id'],
        categoryId: j['category_id'],
        name: j['name'],
        // Laravel sends decimals as strings like “2.00”
        price: double.parse(j['price'].toString()),
        isAvailable: j['is_available'] == true || j['is_available'] == 1,
      );
}

class CartItem {
  final Product product;
  int qty;
  CartItem(this.product, this.qty);
}
class OrderItem {
  final String name;
  final double unitPrice;
  final int qty;
  final double lineTotal;

  OrderItem({
    required this.name,
    required this.unitPrice,
    required this.qty,
    required this.lineTotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        name: j['product_name'],
        unitPrice: double.parse(j['unit_price'].toString()),
        qty: j['quantity'],
        lineTotal: double.parse(j['line_total'].toString()),
      );
}

class Order {
  final int id;
  final String orderNumber;
  final double subtotal;
  final double discount;
  final double total;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;
  final String ? cashier;

  final List<OrderItem> items;

  Order({
    required this.id,
    required this.orderNumber,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    required this.cashier,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'],
        orderNumber: j['order_number'],
        subtotal: double.parse(j['subtotal'].toString()),
        discount: double.parse(j['discount'].toString()),
        total: double.parse(j['total'].toString()),
        paymentMethod: j['payment_method'],
        status: j['status'],
        createdAt: DateTime.parse(j['created_at']).toLocal(),
        cashier: j['user'] is Map ? j['user']['name'] ?.toString():null,
        items: (j['items'] as List? ?? [])
            .map((e) => OrderItem.fromJson(e))
            .toList(),
      );
}