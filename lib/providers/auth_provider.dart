import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
//import '../core/api_error.dart';
class AuthProvider extends ChangeNotifier {
  bool loading = false;
  String? error;
  Map<String, dynamic>? user;

  bool get isAdmin => user?['role'] == 'admin';

  Future<bool> login(String email, String password) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final res = await ApiClient.dio.post('/login', data: {
        'email': email,
        'password': password,
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', res.data['token']);
      user = res.data['user'];
      return true;
    } on DioException catch (e) {
        error = e.response?.statusCode == 401
            ? 'Wrong email or password'
            : 'Cannot connect to server';
        return false;
      } finally {
        loading = false;
        notifyListeners();
      }
    }
  void setUser(Map<String, dynamic> u){
    user = u;
    notifyListeners();
  }
  Future<void> logout() async {
    try {
      await ApiClient.dio.post('/logout');
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    user = null;
    notifyListeners();
  }
}