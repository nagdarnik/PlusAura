import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'main_screen.dart';

void main() {
  runApp(const PlusAuraApp());
}

class PlusAuraApp extends StatelessWidget {
  const PlusAuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlusAura',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}