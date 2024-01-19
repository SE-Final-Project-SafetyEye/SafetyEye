import 'package:flutter/material.dart';
import 'package:safrt_eye_app/poc/Location.dart';
import 'package:safrt_eye_app/poc/SecondPage.dart';
import 'package:safrt_eye_app/poc/camera.dart';
import 'package:safrt_eye_app/poc/voice_recognition.dart';

import './LoginRegisterPage.dart';
import 'VideoPlayer.dart';

class MyHomePage extends StatelessWidget {
  final String title;

  const MyHomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to SafetyEye!',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            PocButtonWidget(title: "Login/Register", page: LoginRegisterPage()),
            PocButtonWidget(title: "Camera", page: CameraHomeScreen()),
            PocButtonWidget(title: "Text to speech", page: SpeechScreen()),
            PocButtonWidget(title: "compression", page: SecondPage(userEmail: "")),
            PocButtonWidget(title: "Accelerometer", page: AccelerometerScreen()),
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