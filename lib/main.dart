import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const GESFieldLogApp());
}

class GESFieldLogApp extends StatelessWidget {
  const GESFieldLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GES Field Log',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}