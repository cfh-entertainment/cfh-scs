// lib/screens/rules/rule_list_screen.dart

import 'package:flutter/material.dart';
import '../../models/rule.dart';
import '../../services/rule_service.dart';
import 'rule_form_screen.dart';

class RuleListScreen extends StatefulWidget {
  final String ip;
  const RuleListScreen({Key? key, required this.ip}) : super(key: key);

  @override
  _RuleListScreenState createState() => _RuleListScreenState();
}

class _RuleListScreenState extends State<RuleListScreen> {
  late RuleService _service;
  List<Rule> _rules = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final baseUrl = 'http://${widget.ip}:3000/api/v1';
    _service = RuleService(baseUrl);
    _loadRules();
  }

  Future<void> _loadRules() async {
    final list = await _service.fetchRules();
    setState(() {
      _rules = list;
      _loading = false;
    });
  }

  void _onAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RuleFormScreen(ip: widget.ip),
      ),
    );
    _loadRules();
  }

  void _onEdit(Rule rule) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RuleFormScreen(ip: widget.ip, rule: rule),
      ),
    );
    _loadRules();
  }

  void _onDelete(int id) async {
    await _service.deleteRule(id);
    _loadRules();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Regel-Verwaltung')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _rules.length,
              itemBuilder: (ctx, i) {
                final r = _rules[i];
                return ListTile(
                  title: Text('Gerät ${r.deviceId}, Pin ${r.pinId}'),
                  subtitle: Text('Typ: ${r.type}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _onEdit(r),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _onDelete(r.id),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAdd,
        child: const Icon(Icons.add),
      ),
    );
  }
}
