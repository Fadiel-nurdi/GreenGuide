import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6E9),
      body: Center(
        child: SizedBox(
          width: 140, // 👈 kecilkan di sini (100-200)
          child: Image.asset(
            'assets/Images/LoadingTA.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}