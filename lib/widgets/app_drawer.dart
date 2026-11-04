import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../screens/dashboard_screen.dart';
import '../screens/home_screen.dart' show brown, darkBrown;
import '../screens/login_screen.dart';
import '../screens/placeholder_screen.dart';
import '../providers/menu_provider.dart';
import '../screens/manage_categories_screen.dart';
import '../screens/manage_product_screen.dart';
import '../screens/employees_screen.dart';
import '../screens/report_screen.dart';
import '../screens/setting_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _open(BuildContext context, String title) async {
    final nav = Navigator.of(context);
    final menu = context.read<MenuProvider>();
    nav.pop(); // close the drawer

    final Widget page;
    switch (title) {
      case 'Dashboard':
        page = const DashboardScreen();
        break;
      case 'Menu':
        page = const ManageProductsScreen();
        break;
      case 'Categories':
        page = const ManageCategoriesScreen();
        break;
      case 'Employees':
        page = const ManageEmployeesScreen();
        break;
      case 'Report':
        page = const ReportScreen();
        break;
      case 'Settings':
      page = const SettingsScreen();
      break;
      default:
        page = PlaceholderScreen(title: title);
    }
    await nav.push(MaterialPageRoute(builder: (_) => page));
    menu.load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;
    final name = (auth.user?['name'] ?? '').toString();
    final role = (auth.user?['role'] ?? '').toString();

    Widget tile(String title, IconData icon, {bool adminOnly = false}) {
      final locked = adminOnly && !isAdmin;
      return ListTile(
        dense: true,
        enabled: !locked,
        minLeadingWidth: 0,
        horizontalTitleGap: 8,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Icon(icon, size: 20),
        title: Text(title, style: const TextStyle(fontSize: 13)),
        trailing: locked
            ? const Icon(Icons.lock, size: 14, color: Colors.grey)
            : null,
        onTap: locked ? null : () => _open(context, title),
      );
    }

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.4,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [darkBrown, brown],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Text(
                      name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  Text(role,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  tile('Dashboard', Icons.dashboard),
                  tile('Menu', Icons.restaurant_menu, adminOnly: true),
                  tile('Categories', Icons.category, adminOnly: true),
                  tile('Employees', Icons.people, adminOnly: true),
                  tile('Settings', Icons.settings, adminOnly: true),
                  tile('Report', Icons.assessment),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              dense: true,
              minLeadingWidth: 0,
              horizontalTitleGap: 8,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              leading:
                  const Icon(Icons.logout, size: 20, color: Colors.red),
              title: const Text('Sign out',
                  style: TextStyle(color: Colors.red, fontSize: 13)),
              onTap: () async {
                final nav = Navigator.of(context);
                context.read<CartProvider>().clear();
                await context.read<AuthProvider>().logout();
                nav.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}