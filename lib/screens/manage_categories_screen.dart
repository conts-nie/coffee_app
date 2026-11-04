import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/api_error.dart';
import '../models/models.dart';
import 'home_screen.dart' show brown, cream;

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});
  @override
  State<ManageCategoriesScreen> createState() =>
      _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  List<MenuCategory> cats = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await ApiClient.dio.get('/categories');
      cats = (res.data as List).map((e) => MenuCategory.fromJson(e)).toList();
    } catch (e) {
      error = 'Failed to load categories';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> form({MenuCategory? c}) async {
    final ctrl = TextEditingController(text: c?.name ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(c == null ? 'Add category' : 'Edit category'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Category name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: brown),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final name = ctrl.text.trim();
    if (saved != true || name.isEmpty) return;
    try {
      if (c == null) {
        await ApiClient.dio.post('/categories', data: {'name': name});
      } else {
        await ApiClient.dio.put('/categories/${c.id}', data: {'name': name});
      }
      await load();
    } catch (e) {
      _snack(apiError(e));
    }
  }

  Future<void> remove(MenuCategory c) async {
    if (!await confirmDelete(context, c.name)) return;
    try {
      await ApiClient.dio.delete('/categories/${c.id}');
      await load();
    } catch (e) {
      _snack(apiError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: brown,
        foregroundColor: Colors.white,
        title: const Text('Categories'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: brown,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add category'),
        onPressed: () => form(),
      ),
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
              : cats.isEmpty
                  ? const Center(child: Text('No categories yet'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                      itemCount: cats.length,
                      itemBuilder: (_, i) {
                        final c = cats[i];
                        return Card(
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          child: ListTile(leading: const CircleAvatar(
                              backgroundColor: Color(0xFFF7F2EC),
                              child: Icon(Icons.category, color: brown),
                            ),
                            title: Text(c.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: brown),
                                  onPressed: () => form(c: c),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => remove(c),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}