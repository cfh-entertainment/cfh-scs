// lib/screens/users/user_form_screen.dart

import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';

class UserFormScreen extends StatefulWidget {
  final String ip;
  final User? user; // null = neu
  const UserFormScreen({Key? key, required this.ip, this.user}) : super(key: key);

  @override
  _UserFormScreenState createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late UserService _service;
  late TextEditingController _usernameCtrl;
  final TextEditingController _passwordCtrl = TextEditingController();
  String _role = 'user';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final baseUrl = 'http://${widget.ip}:3000/api/v1';
    _service = UserService(baseUrl);
    _usernameCtrl = TextEditingController(text: widget.user?.username);
    _role = widget.user?.role ?? 'user';
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; });

    if (widget.user == null) {
      // neu
      await _service.createUser(
        _usernameCtrl.text.trim(),
        _passwordCtrl.text,
        _role,
      );
    } else {
      // update (Passwort ggf. leer lassen)
      await _service.updateUser(
        widget.user!.id,
        password: _passwordCtrl.text.isEmpty ? null : _passwordCtrl.text,
        role: _role,
      );
    }
    setState(() { _loading = false; });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.user == null;
    return Scaffold(
      appBar: AppBar(title: Text(isNew ? 'Neuer User' : 'User bearbeiten')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) => v==null||v.isEmpty ? 'Bitte eingeben' : null,
                enabled: isNew, // beim Edit Username nicht änderbar
              ),
              TextFormField(
                controller: _passwordCtrl,
                decoration: InputDecoration(
                  labelText: isNew ? 'Passwort' : 'Neues Passwort (leer = unverändert)'
                ),
                obscureText: true,
                validator: (v) {
                  if (isNew && (v==null||v.isEmpty)) return 'Bitte Passwort';
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Rolle'),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'user',  child: Text('User')),
                  DropdownMenuItem(value: 'viewer',child: Text('Viewer')),
                ],
                onChanged: (v) => setState(() { _role = v!; }),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                  ? const CircularProgressIndicator()
                  : Text(isNew ? 'Anlegen' : 'Speichern'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
