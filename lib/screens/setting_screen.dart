import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/api_error.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart' show brown, darkBrown, cream;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _profileKey = GlobalKey<FormState>();
  final _passKey = GlobalKey<FormState>();
  late final TextEditingController nameCtrl;
  late final TextEditingController emailCtrl;
  final currentCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  bool savingProfile = false;
  bool savingPass = false;
  bool hideCurrent = true;
  bool hideNew = true;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().user;
    nameCtrl = TextEditingController(text: (u?['name'] ?? '').toString());
    emailCtrl = TextEditingController(text: (u?['email'] ?? '').toString());
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> saveProfile() async {
    if (!_profileKey.currentState!.validate()) return;
    setState(() => savingProfile = true);
    try {
      final res = await ApiClient.dio.put('/profile', data: {
        'name': nameCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
      });
      if (!mounted) return;
      context
          .read<AuthProvider>()
          .setUser(Map<String, dynamic>.from(res.data));
      _snack('Profile updated');
    } catch (e) {
      _snack(apiError(e));
    }
    if (mounted) setState(() => savingProfile = false);
  }

  Future<void> savePassword() async {
    if (!_passKey.currentState!.validate()) return;
    setState(() => savingPass = true);
    try {
      await ApiClient.dio.put('/profile/password', data: {
        'current_password': currentCtrl.text,
        'password': newCtrl.text,
      });
      currentCtrl.clear();
      newCtrl.clear();
      confirmCtrl.clear();
      _passKey.currentState?.reset();
      _snack('Password updated');
    } catch (e) {
      _snack(apiError(e));
    }
    if (mounted) setState(() => savingPass = false);
  }

  InputDecoration _dec(String label, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: brown),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF7F2EC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );

  Widget _card(String title, IconData icon, Widget child) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(18),
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
            Row(children: [
              Icon(icon, color: brown),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 16),
            child,
          ],
        ),
      );

  Widget _button(String label, bool busy, VoidCallback onTap) => SizedBox(
        width: double.infinity,height: 48,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: brown,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: busy ? null : onTap,
          child: busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Text(label),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = (auth.user?['name'] ?? '').toString();

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: brown,
        foregroundColor: Colors.white,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const SizedBox(height: 8),
          Center(
            child: CircleAvatar(
              radius: 36,
              backgroundColor: brown,
              child: Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: const TextStyle(
                    fontSize: 30,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(name,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkBrown)),
          ),
          Center(
            child: Text((auth.user?['role'] ?? '').toString().toUpperCase(),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ),

          _card(
            'Profile',
            Icons.person,
            Form(
              key: _profileKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: _dec('Full name', Icons.badge),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter your name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _dec('Email', Icons.email),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _button('Save profile', savingProfile, saveProfile),
                ],
              ),
            ),
          ),

          _card(
            'Change password',
            Icons.lock,
            Form(
              key: _passKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: currentCtrl,
                    obscureText: hideCurrent,
                    decoration: _dec(
                      'Current password',
                      Icons.lock_outline,
                      suffix: IconButton(
                        icon: Icon(hideCurrent
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => hideCurrent = !hideCurrent),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Enter your current password'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newCtrl,obscureText: hideNew,
                    decoration: _dec(
                      'New password',
                      Icons.lock,
                      suffix: IconButton(
                        icon: Icon(hideNew
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(() => hideNew = !hideNew),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'At least 6 characters'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmCtrl,
                    obscureText: hideNew,
                    decoration:
                        _dec('Confirm new password', Icons.check_circle),
                    validator: (v) =>
                        v != newCtrl.text ? 'Passwords do not match' : null,
                  ),
                  const SizedBox(height: 16),
                  _button('Update password', savingPass, savePassword),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}