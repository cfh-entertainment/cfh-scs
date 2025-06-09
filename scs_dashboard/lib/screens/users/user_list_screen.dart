// lib/screens/users/user_list_screen.dart

import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';
import 'user_form_screen.dart';

class UserListScreen extends StatefulWidget {
  final String ip;
  const UserListScreen({Key? key, required this.ip}) : super(key: key);

  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late UserService _service;
  List<User> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final baseUrl = 'http://${widget.ip}:3000/api/v1';
    _service = UserService(baseUrl);
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final list = await _service.fetchUsers();
    setState(() {
      _users = list;
      _loading = false;
    });
  }

  void _onAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserFormScreen(ip: widget.ip),
      ),
    );
    _loadUsers();
  }

  void _onEdit(User user) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserFormScreen(ip: widget.ip, user: user),
      ),
    );
    _loadUsers();
  }

  void _onDelete(int id) async {
    await _service.deleteUser(id);
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User-Verwaltung')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (ctx, i) {
                final u = _users[i];
                return ListTile(
                  title: Text(u.username),
                  subtitle: Text(u.role),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _onEdit(u),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _onDelete(u.id),
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
