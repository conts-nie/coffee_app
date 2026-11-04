import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api_client.dart';
import '../core/api_error.dart';
import '../models/models.dart';
import 'home_screen.dart' show brown, cream;

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});
  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  List<Product> products = [];
  List<MenuCategory> cats = [];
  bool loading = true;
  String? error;
  String search = '';

  @override
  void initState() {
    super.initState();
    load();
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    try {
      final res = await Future.wait([
        ApiClient.dio.get('/products'),
        ApiClient.dio.get('/categories'),
      ]);
      products = (res[0].data as List).map((e) => Product.fromJson(e)).toList();
      cats = (res[1].data as List).map((e) => MenuCategory.fromJson(e)).toList();
    } catch (e) {
      error = 'Failed to load products';
    }
    if (mounted) setState(() => loading = false);
  }

  String catName(int id) => cats
      .firstWhere((c) => c.id == id,
          orElse: () => MenuCategory(id: 0, name: '-'))
      .name;

  Widget _ph() => Container(
        color: const Color(0xFFF7F2EC),
        child: const Icon(Icons.coffee, color: brown),
      );

  Future<void> form({Product? p}) async {
    if (cats.isEmpty) {
      _snack('Create a category first');
      return;
    }
    final nameCtrl = TextEditingController(text: p?.name ?? '');
    final priceCtrl = TextEditingController(
        text: p == null ? '' : p.price.toStringAsFixed(2));
    int? catId = p?.categoryId ?? cats.first.id;
    bool available = p?.isAvailable ?? true;
    Uint8List? pickedBytes;
    String? pickedName;
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          Future<void> pick() async {
            final x = await ImagePicker().pickImage(
              source: ImageSource.gallery,
              maxWidth: 900,
              imageQuality: 80,
            );
            if (x == null) return;
            final bytes = await x.readAsBytes();
            setS(() {
              pickedBytes = bytes;
              pickedName = x.name;
            });
          }

          Widget preview() {
            Widget child;
            if (pickedBytes != null) {
              child = Image.memory(pickedBytes!, fit: BoxFit.cover);
            } else if (p?.imageUrl != null) {
              child = Image.network(
                p!.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => _ph(),
              );
            } else {
              child = _ph();
            }
            return ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(width: 120, height: 120, child: child),
            );
          }

          return AlertDialog(
            title: Text(p == null ? 'Add product' : 'Edit product'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    preview(),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: pick,
                      icon: const Icon(Icons.photo_library),
                      label: Text(pickedBytes == null && p?.imageUrl == null
                          ? 'Add photo'
                          : 'Change photo'),),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter a name'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Price (\$)'),
                      validator: (v) {
                        final n = double.tryParse((v ?? '').trim());
                        return (n == null || n < 0)
                            ? 'Enter a valid price'
                            : null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: catId,
                      decoration:
                          const InputDecoration(labelText: 'Category'),
                      items: cats
                          .map((c) => DropdownMenuItem(
                              value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: (v) => setS(() => catId = v),
                      validator: (v) =>
                          v == null ? 'Choose a category' : null,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Available'),
                      value: available,
                      onChanged: (v) => setS(() => available = v),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: brown),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(ctx, true);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (saved != true) return;

    final body = FormData.fromMap({
      'name': nameCtrl.text.trim(),
      'price': priceCtrl.text.trim(),
      'category_id': catId.toString(),
      'is_available': available ? '1' : '0',
      if (p != null) '_method': 'PUT',
      if (pickedBytes != null)
        'image': MultipartFile.fromBytes(
          pickedBytes!,
          filename: pickedName ?? 'photo.jpg',
        ),
    });

    try {
      await ApiClient.dio
          .post(p == null ? '/products' : '/products/${p.id}', data: body);
      await load(silent: true);
    } catch (e) {
      _snack(apiError(e));
    }
  }

  Future<void> toggle(Product p, bool v) async {
    try {
      await ApiClient.dio.put('/products/${p.id}', data: {'is_available': v});
      await load(silent: true);
    } catch (e) {
      _snack(apiError(e));
    }
  }

  Future<void> remove(Product p) async {
    if (!await confirmDelete(context, p.name)) return;
    try {
      await ApiClient.dio.delete('/products/${p.id}');
      await load(silent: true);
    } catch (e) {
      _snack(apiError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = products
        .where((p) => p.name.toLowerCase().contains(search.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: brown,
        foregroundColor: Colors.white,
        title: const Text('Menu'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: brown,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
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
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: TextField(
                        onChanged: (v) => setState(() => search = v),
                        decoration: InputDecoration(
                          hintText: 'Search products...',
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
                    Expanded(
                      child: list.isEmpty
                          ? const Center(child: Text('No products'))
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 90),
                              itemCount: list.length,
                              itemBuilder: (_, i) {
                                final p = list[i];
                                return Card(
                                  elevation: 0,
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  child: ListTile(
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: SizedBox(
                                        width: 48,
                                        height: 48,
                                        child: p.imageUrl == null
                                            ? _ph()
                                            : Image.network(
                                                p.imageUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) =>
                                                    _ph(),
                                              ),
                                      ),
                                    ),
                                    title: Text(p.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                        '${catName(p.categoryId)} · \$${p.price.toStringAsFixed(2)}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Switch(
                                          value: p.isAvailable,
                                          onChanged: (v) => toggle(p, v),
                                        ),
                                        PopupMenuButton<String>(
                                          onSelected: (v) {
                                            if (v == 'edit') {
                                              form(p: p);
                                            } else {
                                              remove(p);
                                            }
                                          },
                                          itemBuilder: (_) => const [
                                            PopupMenuItem(
                                                value: 'edit',
                                                child: Text('Edit')),
                                            PopupMenuItem(
                                                value: 'delete',
                                                child: Text('Delete')),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                )
    );
  }
}