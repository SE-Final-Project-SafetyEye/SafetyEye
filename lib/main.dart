import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'poc/poc_selection_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafetyEye',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.deepPurple),
        // Other theme configurations if needed
      ),
      home: const MyHomePage(title: 'SafetyEye'),
    );
  }
}












