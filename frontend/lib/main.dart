import 'package:flutter/material.dart';
import 'package:frontend/screens/tipo_acesso_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,

        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),

        scaffoldBackgroundColor: const Color(0xFF1A0933),

        primaryColor: const Color(0xFF8E24AA),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9C27B0),
            foregroundColor: Colors.white,

            minimumSize: const Size(250, 55),
            elevation: 8,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),

        cardTheme: CardThemeData(
          elevation: 8,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,

          fillColor: Colors.white10,

          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),

      title: 'Momentz',

      home: const TipoAcessoScreen(),
    );
  }
}
