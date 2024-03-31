import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:safety_eye_app/poc/AuthProvider.dart';
import 'package:safety_eye_app/poc/semi_app/InAppFoldersListProvider.dart';
import 'package:safety_eye_app/poc/semi_app/VideoListProvider.dart';
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
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  List<CameraDescription> cameras;
  MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SpeechProvider()),
        ChangeNotifierProvider(create: (context) => CompressProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VideoFolderProvider()),
        ChangeNotifierProvider(create: (_)=> VideoListProvider())
      ],
      child: MaterialApp(
        title: 'SafetyEye',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.deepPurple),
        ),
        home: MyHomePage(cameras: cameras, title: 'SafetyEye',),
      ),
    );
  }
}












