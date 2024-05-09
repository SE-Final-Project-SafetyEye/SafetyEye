import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:safety_eye_app/providers/auth_provider.dart';
import 'package:safety_eye_app/providers/ioc_provider.dart';
import 'package:safety_eye_app/providers/settings_provider.dart';
import 'package:safety_eye_app/providers/permissions_provider.dart';
import 'package:safety_eye_app/providers/sensors_provider.dart';
import 'package:safety_eye_app/providers/signatures_provider.dart';
import 'package:safety_eye_app/views/screens/auth_screen.dart';
import 'package:safety_eye_app/views/screens/home_screen.dart';
import 'package:speech_to_text/speech_recognition_event.dart';
import 'package:speech_to_text/speech_to_text_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  List<CameraDescription> cameras = await availableCameras();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => IocContainerProvider())
    ],
    builder: (context, child) {
      final iocProvider =
          Provider.of<IocContainerProvider>(context, listen: false);
      return MultiProvider(providers: [
        ChangeNotifierProvider(
            create: (context) =>
                iocProvider.container.get<AuthenticationProvider>()),
        ChangeNotifierProvider(
            create: (context) =>
                iocProvider.container.get<PermissionsProvider>()),
        ChangeNotifierProvider(
            create: (context) => iocProvider.container.get<SensorsProvider>()),
        ChangeNotifierProvider(create: (context) {
          return iocProvider.container.get<SettingsProvider>();
        }),
        ChangeNotifierProvider(
            create: (context) =>
                iocProvider.container.get<SignaturesProvider>()),
        ChangeNotifierProvider(
            create: (context) =>
                iocProvider.container.get<SpeechToTextProvider>()),
      ], child: const MyApp());
    },
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  void initSpeechProvider(SpeechToTextProvider speechProvider) async {
    var available = await speechProvider.initialize();
    StreamSubscription<SpeechRecognitionEvent> _subscription;
    _subscription = speechProvider.stream.listen((recognitionEvent) {
      if (recognitionEvent.eventType == SpeechRecognitionEventType.partialRecognitionEvent )  {
        print("I heard partial: ${recognitionEvent.recognitionResult?.recognizedWords}");
      }
      if (recognitionEvent.eventType == SpeechRecognitionEventType.finalRecognitionEvent )  {
        print("I heard: ${recognitionEvent.recognitionResult?.recognizedWords}");
      }
    });
    if (available) speechProvider.listen();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider =
        Provider.of<AuthenticationProvider>(context, listen: true);
    final permissionsProvider =
        Provider.of<PermissionsProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final speechProvider =
        Provider.of<SpeechToTextProvider>(context, listen: false);
    initSpeechProvider(speechProvider);

    return FutureBuilder(
        future: permissionsProvider.init(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
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
                    ? const AuthScreen()
                    : HomeScreen(settingsProvider),
                routes: {
                  "/home": (context) => HomeScreen(settingsProvider),
                  "/auth": (context) => const AuthScreen(),
                });
          } else {
            return const CircularProgressIndicator();
          }
        });
  }
}
