import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const PrismoSuperAdminApp());
}

class PrismoSuperAdminApp extends StatelessWidget {
  const PrismoSuperAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prismo Super Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0a0a0f),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFe94560),
          secondary: Color(0xFF0f3460),
          surface: Color(0xFF1a1a2e),
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
