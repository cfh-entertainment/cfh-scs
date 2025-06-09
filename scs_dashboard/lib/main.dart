import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_manager.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeManager(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // Build-Methoden-Signatur exakt so belassen: nur ein Argument
  @override
  Widget build(BuildContext context) {
    // ThemeManager aus dem Provider holen
    final themeManager = Provider.of<ThemeManager>(context);

    return MaterialApp(
      title: 'SCS Dashboard',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeManager.mode,
      home: const LoginScreen(),
    );
  }
}
