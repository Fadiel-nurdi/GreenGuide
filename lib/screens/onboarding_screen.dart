import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/Images/Logo.png',
              width: 110,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            Text(
              'GreenGuide',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Panduan cerdas dari alam untuk alam.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            /// Tombol utama (User)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/home'),
                child: const Text('Mulai'),
              ),
            ),

            const SizedBox(height: 12),

            /// Tombol Login Admin
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/admin-login');
              },
              child: const Text(
                'Login sebagai Admin',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
