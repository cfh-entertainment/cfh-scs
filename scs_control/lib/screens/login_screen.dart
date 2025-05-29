import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _domainController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  List<String> knownDomains = [];
  String? selectedDomain;

  @override
  void initState() {
    super.initState();
    _loadDomains();
  }

  Future<void> _loadDomains() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      knownDomains = prefs.getStringList('knownDomains') ?? [];
    });
  }

  Future<void> _saveDomain(String domain) async {
    final prefs = await SharedPreferences.getInstance();
    if (!knownDomains.contains(domain)) {
      knownDomains.add(domain);
      await prefs.setStringList('knownDomains', knownDomains);
    }
  }

  void _login() {
    final domain = _domainController.text.trim();
    if (domain.isEmpty) return;

    _saveDomain(domain);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardScreen(serverIp: domain),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Control System')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButton<String>(
              hint: const Text('Bekannte Server wählen'),
              value: selectedDomain,
              items: knownDomains
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedDomain = value;
                  _domainController.text = value!;
                });
              },
            ),
            TextField(
              controller: _domainController,
              decoration: const InputDecoration(labelText: 'Server IP / Domain'),
            ),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Benutzername'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Passwort'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
