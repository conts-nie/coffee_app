import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/api_error.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart' show brown, cream;

class Employee {
  final int id;
  final String name;
  final String email;
  final String role;
  final bool isActive;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
  });

  factory Employee.fromJson(Map<String, dynamic> j) => Employee(
        id: j['id'],
        name: j['name'],
        email: j['email'],
        role: j['role'],
        isActive: j['is_active'] == true || j['is_active'] == 1,
      );
}

class ManageEmployeesScreen extends StatefulWidget {
  const ManageEmployeesScreen({super.key});
  @override
  State<ManageEmployeesScreen> createState() => _ManageEmployeesScreenState();
}

class _ManageEmployeesScreenState extends State<ManageEmployeesScreen> {
  List<Employee> employees = [];
  bool loading = true;
  String? error;

  int get myId => (context.read<AuthProvider>().user?['id'] ?? 0) as int;

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
      final res = await ApiClient.dio.get('/users');
      employees =
          (res.data as List).map((e) => Employee.fromJson(e)).toList();
    } catch (e) {
      error = 'Failed to load employees';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> form({Employee? e}) async {
    final isSelf = e != null && e.id == myId;
    final nameCtrl = TextEditingController(text: e?.name ?? '');
    final emailCtrl = TextEditingController(text: e?.email ?? '');
    final passCtrl = TextEditingController();
    String role = e?.role ?? 'cashier';
    bool active = e?.isActive ?? true;
    bool hide = true;
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(e == null ? 'Add employee' : 'Edit employee'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter a name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passCtrl,
                    obscureText: hide,
                    decoration: InputDecoration(
                      labelText: e == null
                          ? 'Password'
                          : 'New password (optional)',
                      helperText:
                          e == null ? null : 'Leave blank to keep current',
                      suffixIcon: IconButton(
                        icon: Icon(
                            hide ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setS(() => hide = !hide),
                      ),
                    ),validator: (v) {
                      final t = v ?? '';
                      if (e == null && t.length < 6) {
                        return 'At least 6 characters';
                      }
                      if (e != null && t.isNotEmpty && t.length < 6) {
                        return 'At least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const [
                      DropdownMenuItem(
                          value: 'cashier', child: Text('Cashier')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged:
                        isSelf ? null : (v) => setS(() => role = v ?? role),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Account active'),
                    value: active,
                    onChanged: isSelf ? null : (v) => setS(() => active = v),
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
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    final data = {
      'name': nameCtrl.text.trim(),
      'email': emailCtrl.text.trim(),
      'role': role,
      'is_active': active,
      if (passCtrl.text.isNotEmpty) 'password': passCtrl.text,
    };

    try {
      if (e == null) {
        await ApiClient.dio.post('/users', data: data);
      } else {
        await ApiClient.dio.put('/users/${e.id}', data: data);
      }
      await load(silent: true);
    } catch (err) {
      _snack(apiError(err));
    }
  }

  Future<void> toggle(Employee e, bool v) async {
    try {
      await ApiClient.dio.put('/users/${e.id}', data: {'is_active': v});
      await load(silent: true);
    } catch (err) {
      _snack(apiError(err));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: brown,
        foregroundColor: Colors.white,
        title: const Text('Employees'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: brown,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add employee'),
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
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: employees.length,
                    itemBuilder: (_, i) {
                      final e = employees[i];
                      final isSelf = e.id == myId;
                      return Opacity(
                        opacity: e.isActive ? 1 : 0.55,
                        child: Card(
                          elevation: 0,
                          color: Colors.white,shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          child: ListTile(
                            onTap: () => form(e: e),
                            leading: CircleAvatar(
                              backgroundColor: brown,
                              foregroundColor: Colors.white,
                              child: Text(e.name.isEmpty
                                  ? '?'
                                  : e.name[0].toUpperCase()),
                            ),
                            title: Text(
                              isSelf ? '${e.name} (you)' : e.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                                '${e.email}\n${e.role.toUpperCase()}${e.isActive ? '' : ' · DISABLED'}'),
                            isThreeLine: true,
                            trailing: Switch(
                              value: e.isActive,
                              onChanged: isSelf ? null : (v) => toggle(e, v),
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
