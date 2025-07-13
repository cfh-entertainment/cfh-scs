// lib/screens/rules/rule_form_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/rule.dart';
import '../../services/rule_service.dart';

class RuleFormScreen extends StatefulWidget {
  final String ip;
  final Rule? rule; // null = neu
  const RuleFormScreen({Key? key, required this.ip, this.rule}) : super(key: key);

  @override
  _RuleFormScreenState createState() => _RuleFormScreenState();
}

class _RuleFormScreenState extends State<RuleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late RuleService _service;
  late TextEditingController _deviceIdCtrl;
  late TextEditingController _pinIdCtrl;
  late TextEditingController _conditionCtrl;
  late TextEditingController _actionCtrl;
  late TextEditingController _scheduleCtrl;
  String _type = 'timeAndThreshold';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final baseUrl = 'http://${widget.ip}:3000/api/v1';
    _service = RuleService(baseUrl);
    _deviceIdCtrl    = TextEditingController(text: widget.rule?.deviceId.toString());
    _pinIdCtrl       = TextEditingController(text: widget.rule?.pinId.toString());
    _conditionCtrl   = TextEditingController(text: widget.rule != null
        ? widget.rule!.conditionJson.toString() : '{}');
    _actionCtrl      = TextEditingController(text: widget.rule != null
        ? widget.rule!.actionJson.toString() : '{}');
    _scheduleCtrl    = TextEditingController(text: widget.rule != null
        ? widget.rule!.scheduleJson.toString() : '{}');
    _type            = widget.rule?.type ?? 'timeAndThreshold';
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; });

    final deviceId     = int.parse(_deviceIdCtrl.text.trim());
    final pinId        = int.parse(_pinIdCtrl.text.trim());
    final condition    = Map<String,dynamic>.from(
                          Uri.decodeComponent(_conditionCtrl.text).isEmpty
                            ? {} 
                            : (jsonDecode(_conditionCtrl.text) as Map)
                        );
    final action       = Map<String,dynamic>.from(
                          jsonDecode(_actionCtrl.text) as Map
                        );
    final schedule     = Map<String,dynamic>.from(
                          jsonDecode(_scheduleCtrl.text) as Map
                        );

    if (widget.rule == null) {
      await _service.createRule(
        deviceId:      deviceId,
        pinId:         pinId,
        conditionJson: condition,
        actionJson:    action,
        scheduleJson:  schedule,
        type:          _type,
      );
    } else {
      await _service.updateRule(
        id:             widget.rule!.id,
        conditionJson:  condition,
        actionJson:     action,
        scheduleJson:   schedule,
        type:           _type,
      );
    }

    setState(() { _loading = false; });
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _deviceIdCtrl.dispose();
    _pinIdCtrl.dispose();
    _conditionCtrl.dispose();
    _actionCtrl.dispose();
    _scheduleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.rule == null;
    return Scaffold(
      appBar: AppBar(title: Text(isNew ? 'Neue Regel' : 'Regel bearbeiten')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _deviceIdCtrl,
                  decoration: const InputDecoration(labelText: 'deviceId'),
                  validator: (v) => v==null||v.isEmpty ? 'Bitte ID' : null,
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _pinIdCtrl,
                  decoration: const InputDecoration(labelText: 'pinId'),
                  validator: (v) => v==null||v.isEmpty ? 'Bitte Pin' : null,
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _conditionCtrl,
                  decoration: const InputDecoration(labelText: 'conditionJson'),
                  validator: (v) => v==null||v.isEmpty ? 'Bitte JSON' : null,
                  maxLines: 3,
                ),
                TextFormField(
                  controller: _actionCtrl,
                  decoration: const InputDecoration(labelText: 'actionJson'),
                  validator: (v) => v==null||v.isEmpty ? 'Bitte JSON' : null,
                  maxLines: 3,
                ),
                TextFormField(
                  controller: _scheduleCtrl,
                  decoration: const InputDecoration(labelText: 'scheduleJson'),
                  maxLines: 3,
                ),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(labelText: 'Typ'),
                  items: const [
                    DropdownMenuItem(
                      value: 'timeAndThreshold',
                      child: Text('timeAndThreshold'),
                    ),
                    DropdownMenuItem(
                      value: 'thresholdOnly',
                      child: Text('thresholdOnly'),
                    ),
                  ],
                  onChanged: (v) => setState(() { _type = v!; }),
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
      ),
    );
  }
}
