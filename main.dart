import 'package:flutter/material.dart';
import 'iniciarSesion.dart';
import 'home_screen.dart';
import 'crearCuenta.dart';
import 'profile_screen.dart';
import 'ChatbotScreen.dart';
import 'chatbot_settings_screen.dart';
import 'admin_video_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App de Gaming',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF6B2E9C),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B2E9C),
          primary: const Color(0xFF6B2E9C),
          secondary: const Color(0xFF9B59B6),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6B2E9C),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6B2E9C),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      home: const Login(),
      routes: {
        '/login': (context) => const Login(),
        '/home': (context) => const HomeScreen(),
        '/register': (context) => const CrearCuenta(),
        '/profile': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          return ProfileScreen(userData: args as Map<String, dynamic>);
        },
        '/admin': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          return AdminVideoManager(userData: args as Map<String, dynamic>);
        },
      },
    );
  }
}