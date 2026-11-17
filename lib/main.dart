import 'package:flutter/material.dart';

import 'controllers/calculadora_controller.dart';
import 'views/calculadora_page.dart';

void main() => runApp(CalculadoraApp(controller: CalculadoraController()));

class CalculadoraApp extends StatelessWidget {
  const CalculadoraApp({super.key, required this.controller});

  final CalculadoraController controller;

  @override
  Widget build(BuildContext context) {
    const semente = Color(0xFF0B7A5A);
    return MaterialApp(
      title: 'Investir ou empreender',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: semente,
        brightness: Brightness.light,
      ),
      home: CalculadoraPage(controller: controller),
    );
  }
}
