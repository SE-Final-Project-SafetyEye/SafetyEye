

import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:safety_eye_app/providers/auth_provider.dart';
import 'package:safety_eye_app/providers/chunks_provider.dart';
import 'package:safety_eye_app/providers/ioc_provider.dart';
import 'package:safety_eye_app/providers/journeys_provider.dart';
import 'package:safety_eye_app/providers/settings_provider.dart';
import 'package:safety_eye_app/providers/permissions_provider.dart';
import 'package:safety_eye_app/providers/sensors_provider.dart';
import 'package:safety_eye_app/providers/signatures_provider.dart';
import 'package:safety_eye_app/providers/video_recording_provider.dart';
import 'package:safety_eye_app/views/screens/auth_screen.dart';
import 'package:safety_eye_app/views/screens/home_screen.dart';
import 'package:speech_to_text/speech_to_text_provider.dart';
import 'environment_config.dart';
import 'firebase_options.dart';
import 'package:flutter_exit_app/flutter_exit_app.dart';
import 'package:permission_handler/permission_handler.dart';


void main() async {
  log(EnvironmentConfig.BACKEND_URL);
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  List<CameraDescription> cameras = await availableCameras();
  runApp(MultiProvider(
    providers: [ChangeNotifierProvider(create: (context) => IocContainerProvider())],
    builder: (context, child) {
      final iocProvider = Provider.of<IocContainerProvider>(context, listen: false);
      return MultiProvider(providers: [
        ChangeNotifierProvider(create: (context) => iocProvider.container.get<AuthenticationProvider>()),
        ChangeNotifierProvider(create: (context) => iocProvider.container.get<PermissionsProvider>()),
        ChangeNotifierProvider(create: (context) => iocProvider.container.get<SensorsProvider>()),
        ChangeNotifierProvider(create: (context) {
          return iocProvider.container.get<SettingsProvider>();
        }),
        ChangeNotifierProvider(create: (context) => iocProvider.container.get<SignaturesProvider>()),
        ChangeNotifierProvider(create: (context) => iocProvider.container.get<SpeechToTextProvider>()),
        ChangeNotifierProvider(create: (context) => iocProvider.container.get<VideoRecordingProvider>()),
        ChangeNotifierProvider(create: (context) => iocProvider.container.get<ChunksProvider>()),
        ChangeNotifierProvider(create: (context) => iocProvider.container.get<JourneysProvider>()),
      ], child: const MyApp());
    },
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthenticationProvider>(context, listen: true);
    final permissionsProvider = Provider.of<PermissionsProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final journeysProvider = Provider.of<JourneysProvider>(context, listen: false);
    final video = Provider.of<VideoRecordingProvider>(context, listen: false);

    return FutureBuilder(
      future: permissionsProvider.init(),
      builder: (context, snapshot) {
        if(snapshot.hasData && snapshot.data == false){
          return const MaterialApp(
            home: AlertNoPermissions(),
          );
        }
        return StreamBuilder(
            stream: authProvider.currentUserStream,
            builder: (context, AsyncSnapshot<User?> snapshot) {
              if (snapshot.connectionState != ConnectionState.active) {
                return const Center(child: CircularProgressIndicator());
              }
              final widgetToStart = snapshot.data == null
                  ? const AuthScreen()
                  : HomeScreen(
                      settingsProvider: settingsProvider,
                      journeysProvider: journeysProvider,
                      videoRecordingProvider: video);
              return MaterialApp(
                  title: 'SafetyEye',
                  theme: ThemeData(
                    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, secondary: Colors.blue),
                    textTheme: const TextTheme(
                      bodySmall: TextStyle(fontSize: 12.0),
                    ),
                  ),
                  home: widgetToStart,
                  routes: {
                    "/home": (context) => HomeScreen(
                        settingsProvider: settingsProvider,
                        journeysProvider: journeysProvider,
                        videoRecordingProvider: video),
                    "/auth": (context) => const AuthScreen(),
                  });
            });
      },
    );
  }
}


class AlertNoPermissions extends StatelessWidget {
  const AlertNoPermissions({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Permission error"),
      content: const Text(
          "SafetyEye demands all the requested permissions for its correct functionality."),
      actions: [
        TextButton(
          child: const Text("OK"),
          onPressed: () {
            openAppSettings();
            if (Theme.of(context).platform != TargetPlatform.iOS) {
              //FlutterExitApp.exitApp(iosForceExit: true);
              FlutterExitApp.exitApp();
            }
          },
        ),
      ],
    );
  }
}