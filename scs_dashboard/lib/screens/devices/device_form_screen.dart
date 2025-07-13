import 'package:flutter/material.dart';
import '../../models/device.dart';
import '../../services/device_service.dart';

class DeviceFormScreen extends StatefulWidget {
  final String ip;
  final Device? device;
  const DeviceFormScreen({Key? key, required this.ip, this.device}) : super(key: key);

  @override
  _DeviceFormScreenState createState() => _DeviceFormScreenState();
}

class _DeviceFormScreenState extends State<DeviceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late DeviceService _service;
  late TextEditingController _deviceIdCtrl;
  late TextEditingController _typeCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final baseUrl = 'http://${widget.ip}:3000/api/v1';
    _service = DeviceService(baseUrl);
    _deviceIdCtrl = TextEditingController(text: widget.device?.deviceId);
    _typeCtrl     = TextEditingController(text: widget.device?.type);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; });

    if (widget.device == null) {
      await _service.createDevice(
        _deviceIdCtrl.text.trim(),
        _typeCtrl.text.trim(),
      );
    } else {
      await _service.updateDevice(
        widget.device!.id,
        deviceId: _deviceIdCtrl.text.trim(),
        type:     _typeCtrl.text.trim(),
      );
    }

    setState(() { _loading = false; });
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _deviceIdCtrl.dispose();
    _typeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.device == null;
    return Scaffold(
      appBar: AppBar(title: Text(isNew ? 'Neues Gerät' : 'Gerät bearbeiten')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _deviceIdCtrl,
                decoration: const InputDecoration(labelText: 'deviceId'),
                validator: (v) => v == null || v.isEmpty ? 'Bitte eingeben' : null,
              ),
              TextFormField(
                controller: _typeCtrl,
                decoration: const InputDecoration(labelText: 'type'),
                validator: (v) => v == null || v.isEmpty ? 'Bitte eingeben' : null,
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
