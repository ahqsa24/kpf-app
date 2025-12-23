import 'package:flutter/material.dart';
import 'package:kpf_app/home_screen.dart';

void main() {
  runApp(const KpfApp());
}

class KpfApp extends StatelessWidget {
  const KpfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kontak Perkasa Futures',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF009688), // androidAccentColor
          primary: const Color(0xFF009688), 
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const HomeScreen(),
    );
  }
}
