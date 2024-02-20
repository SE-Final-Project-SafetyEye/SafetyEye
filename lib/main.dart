import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:safrt_eye_app/poc/poc_selection_screen.dart';
import 'package:safrt_eye_app/poc/provider/CompressProvider.dart';
import 'package:safrt_eye_app/poc/provider/SpeechProvider.dart';
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
    return MultiProvider(providers: [ChangeNotifierProvider(create: (context)=>SpeechProvider()),ChangeNotifierProvider(create: (context)=>CompressProvider())],child: MaterialApp(
      title: 'SafetyEye',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.deepPurple),
      ),
      home: MyHomePage(title: "safetyEye",cameras: cameras),
    ),);
  }
}












