import 'package:flutter/material.dart' ;
import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/models.dart';
class MenuProvider extends ChangeNotifier {
  List<MenuCategory> categories = [];
  List<Product> products = [];
  int? selectedCategoryId;
  String search = '';
  bool loading = false;
  String? error;

  List<Product> get filtered => products.where((p) {
        final okCat =
            selectedCategoryId == null || p.categoryId == selectedCategoryId;
        final okSearch =
            p.name.toLowerCase().contains(search.toLowerCase());
        return okCat && okSearch;
      }).toList();

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final res = await Future.wait([
        ApiClient.dio.get('/categories'),
        ApiClient.dio.get('/products'),
      ]);
      categories = (res[0].data as List)
          .map((e) => MenuCategory.fromJson(e))
          .toList();
      products =
          (res[1].data as List).map((e) => Product.fromJson(e)).toList();
    } catch (e, st) {
      debugPrint('MENU ERROR: $e');
      debugPrint('$st');
      error = 'Failed to load menu: $e';
    }
    loading = false;
    notifyListeners();
  }

  void selectCategory(int? id) {
    selectedCategoryId = id;
    notifyListeners();
  }

  void setSearch(String v) {
    search = v;
    notifyListeners();
  }
}