import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:safety_eye_app/providers/auth_provider.dart';
import 'package:safety_eye_app/providers/settings_provider.dart';
import 'package:safety_eye_app/views/screens/auth_screen.dart';
import 'package:safety_eye_app/views/screens/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  List<CameraDescription> cameras = await availableCameras();
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (context) => AuthenticationProvider()),
    ChangeNotifierProvider(create: (context) => SettingsProvider())
  ], child: MyApp(cameras: cameras)));
}

class MyApp extends StatelessWidget {
  List<CameraDescription> cameras;

  MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    final authProvider =
        Provider.of<AuthenticationProvider>(context, listen: true);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    return MaterialApp(
        title: 'SafetyEye',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue, secondary: Colors.blue),
          textTheme: const TextTheme(
            bodySmall: TextStyle(fontSize: 12.0),
          ),
        ),
        home: !authProvider.isSignedIn()
            ? AuthScreen()
            : HomeScreen(settingsProvider),
        routes: {
          "/home": (context) => HomeScreen(settingsProvider),
          "/auth": (context) => AuthScreen(),
        });
  }
}
