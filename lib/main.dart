import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:safety_eye_app/providers/auth_provider.dart';
import 'package:safety_eye_app/providers/permissions_provider.dart';
import 'package:safety_eye_app/providers/sensors_provider.dart';
import 'package:safety_eye_app/views/screens/auth_screen.dart';
import 'package:safety_eye_app/views/screens/home_screen.dart';
import 'poc/poc_selection_screen.dart';
import 'poc/provider/CompressProvider.dart';
import 'poc/provider/SpeechProvider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  List<CameraDescription> cameras = await availableCameras();
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (context) => AuthenticationProvider()),
    ChangeNotifierProvider(create: (context) => PermissionsProvider()),
    ChangeNotifierProvider(create: (context) => SensorsProvider())
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthenticationProvider>(context, listen: true);
    final permissionsProvider = Provider.of<PermissionsProvider>(context, listen: false);

    return FutureBuilder(
        future: permissionsProvider.init(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return MaterialApp(
                title: 'SafetyEye',
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.deepPurple),
                ),
                home: authProvider.isSignedIn() ? const HomeScreen() : const AuthScreen(),
                routes: {
                  "/home": (context) => const HomeScreen(),
                  "/auth": (context) => const AuthScreen(),
                });
          } else {
            return const CircularProgressIndicator();
          }
        });
  }
}
