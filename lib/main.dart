import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'theme.dart';
import 'app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Firebase init
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Firestore offline cache
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );


  runApp(
    const ProviderScope(
      child: GreenGuideApp(),
    ),
  );
}

class GreenGuideApp extends StatelessWidget {
  const GreenGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GreenGuide',
      debugShowCheckedModeBanner: false,

      // 🌿 Theme global
      theme: buildTheme(),

      // 🧭 CENTRAL ROUTER (WAJIB)
      onGenerateRoute: onGenerateRoute,

      // ✅ ROOT APLIKASI (NETRAL)
      initialRoute: '/welcome',

      // ❌ JANGAN pakai routes:{}
      // ❌ JANGAN pakai home:
    );
  }
}
