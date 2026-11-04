import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/menu_provider.dart';
import '../screens/cart_screen.dart';
import '../widgets/app_drawer.dart';
import 'order_screen.dart';


const brown = Color(0xFF6F4E37);
const darkBrown = Color(0xFF3E2723);
const cream = Color(0xFFFFF8F0);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuProvider>().load();
    });
  }
  Widget _placeholder(IconData icon) => Container(
      color: const Color(0xFFF7F2EC),
      child: Icon(icon, size: 48, color: brown),
    );

  IconData iconFor(String category) {
    final c = category.toLowerCase();
    if (c.contains('tea')) return Icons.emoji_food_beverage;
    if (c.contains('bakery')) return Icons.bakery_dining;
    return Icons.coffee;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final menu = context.watch<MenuProvider>();
    final cart = context.watch<CartProvider>();

    String catName(int id) => menu.categories
        .firstWhere((c) => c.id == id,
            orElse: () => MenuCategory(id: 0, name: ''))
        .name;

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: brown,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('POS Coffee',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              '${auth.user?['name'] ?? ''} · ${auth.user?['role'] ?? ''}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdersScreen()),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: menu.setSearch,
              decoration: InputDecoration(
                hintText: 'Search menu...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Category chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip('All', menu.selectedCategoryId == null,
                    () => menu.selectCategory(null)),
                ...menu.categories.map((c) => _chip(
                      c.name,
                      menu.selectedCategoryId == c.id,
                      () => menu.selectCategory(c.id),
                    )),
              ],
            ),
          ),

          // Product grid
          Expanded(
            child: menu.loading
                ? const Center(child: CircularProgressIndicator())
                : menu.error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(menu.error!),
                            TextButton(
                                onPressed: menu.load,child: const Text('Retry')),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: menu.filtered.length,
                        itemBuilder: (_, i) {
                          final p = menu.filtered[i];
                          return _productCard(
                              p, cart, iconFor(catName(p.categoryId)));
                        },
                      ),
          ),
        ],
      ),

      // Cart bar
     bottomNavigationBar: cart.count == 0
          ? null
          : SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: darkBrown,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart, color: Colors.white),
                      const SizedBox(width: 10),
                      Text('${cart.count} items · View cart',
                          style: const TextStyle(color: Colors.white)),
                      const Spacer(),
                      Text(
                        '\$${cart.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: brown,
        labelStyle: TextStyle(color: selected ? Colors.white : darkBrown),
        backgroundColor: Colors.white,
        showCheckmark: false,
        side: BorderSide.none,
      ),
    );
  }

  Widget _productCard(Product p, CartProvider cart, IconData icon) {
    final qty = cart.qtyOf(p.id);
    return Opacity(
      opacity: p.isAvailable ? 1 : 0.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: p.isAvailable ? () => cart.add(p) : null,
        child: Container(
          padding: const EdgeInsets.all(14),
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
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: double.infinity,
                    child: p.imageUrl == null
                        ? _placeholder(icon)
                        : Image.network(
                            p.imageUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (c, child, progress) =>
                                progress == null ? child : _placeholder(icon),
                            errorBuilder: (c, e, s) => _placeholder(icon),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)), const SizedBox(height: 4),
              Row(
                children: [
                  Text('\$${p.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: brown, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (!p.isAvailable)
                    const Text('Sold out',
                        style: TextStyle(color: Colors.red, fontSize: 12))
                  else if (qty > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: brown,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('x$qty',
                          style: const TextStyle(color: Colors.white)),
                    )
                  else
                    const Icon(Icons.add_circle, color: brown),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}