import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverCtrl = TextEditingController(
    text: '192.168.178.25'
  );
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  //final _auth = AuthService();
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Login', style: TextStyle(fontSize: 24)),
                    const SizedBox(height: 16),
                    // 1) Server-Adresse eingeben
                    TextFormField(
                      controller: _serverCtrl,
                      decoration: InputDecoration(
                        labelText: 'Server-Adresse',
                      ),
                      validator: (v) =>
                        v == null || v.isEmpty
                          ? 'Bitte Server-Adresse eingeben'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Username'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Bitte ausfüllen' : null,
                    ),
                    TextFormField(
                      controller: _passwordCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Passwort'),
                      obscureText: true,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Bitte ausfüllen' : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const CircularProgressIndicator()
                          : const Text('Einloggen'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    // 3) AuthService mit dem eingegebenen Server-Endpunkt initialisieren
    final ip = _serverCtrl.text.trim();
    final baseUrl = 'http://$ip:3000/api/v1';
    final auth = AuthService(baseUrl);
    final success = await auth.login(
      _usernameCtrl.text.trim(),
      _passwordCtrl.text,
    );
    setState(() {
      _loading = false;
    });
    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(ip: _serverCtrl.text.trim()),
        ),
      );
    } else {
      setState(() {
        _error = 'Login fehlgeschlagen';
      });
    }
  }
}
