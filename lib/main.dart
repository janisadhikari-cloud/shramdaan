import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // CORRECTED
import 'firebase_options.dart';
import 'features/auth/screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("App connected to Firebase Project ID: ${Firebase.app().options.projectId}");

  runApp(const ShramDaanApp());
}

class ShramDaanApp extends StatelessWidget {
  const ShramDaanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shram Daan',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthGate(),
    );
  }
}