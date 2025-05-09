// lib/app.dart
import 'package:flutter/material.dart';
import 'ui/layout/app_scaffold.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GreenWay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFECF2FE),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          background: Color(0xFFECF2FE), // 👈 forcer ici aussi
          surface: Colors.white, // 👈 pour les cartes/dialogues
        ),
        useMaterial3: true,
        navigationBarTheme: const NavigationBarThemeData(
          labelTextStyle: MaterialStatePropertyAll(
            TextStyle(fontSize: 9), // 👈 3 pt de moins
          ),
          iconTheme: MaterialStatePropertyAll(
            IconThemeData(size: 18), // 👈 plus petit que 24
          ),
        ),
      ),
      home: const AppScaffold(), // écran de départ temporaire
    );
  }
}
