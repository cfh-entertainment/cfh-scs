import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const SmartControlApp());
}

class SmartControlApp extends StatelessWidget {
  const SmartControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Control System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const LoginScreen(),
    );
  }
}
