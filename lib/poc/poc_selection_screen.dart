import 'package:flutter/material.dart';
import 'package:safrt_eye_app/poc/DigitalSignitureScreen.dart';
import 'package:safrt_eye_app/poc/Location.dart';
import 'package:safrt_eye_app/poc/SecondPage.dart';
import 'package:safrt_eye_app/poc/camera.dart';
import 'package:safrt_eye_app/poc/voice_recognition.dart';

import './LoginRegisterPage.dart';
import 'VideoPlayer.dart';
import 'inAppCamera.dart';

class MyHomePage extends StatelessWidget {
  final String title;

  const MyHomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body:  Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to SafetyEye!',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            const PocButtonWidget(title: "Login/Register", page: LoginRegisterPage()),
            const PocButtonWidget(title: "CameraDefaultAppAndGalleryAccessHomeScreen", page: CameraDefaultAppAndGalleryAccessHomeScreen()),
            const PocButtonWidget(title: "InAppCameraScreen", page: InAppCameraScreen()),
            const PocButtonWidget(title: "Text to speech", page: SpeechScreen()),
            const PocButtonWidget(title: "compression", page: SecondPage(userEmail: "")),
            const PocButtonWidget(title: "Accelerometer", page: AccelerometerScreen()),
            PocButtonWidget(title: "Key Generation", page: DigitalSignatureScreen())
          ],
        ),
      ),
    );
  }
}

class PocButtonWidget extends StatelessWidget {
  final String title;
  final Widget page;

  const PocButtonWidget({super.key, required this.title, required this.page});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Navigate to the login/register page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Text(title),
    );
  }
}