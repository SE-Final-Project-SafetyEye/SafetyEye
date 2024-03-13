import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:safety_eye_app/poc/uploadVideo/backend_integration_screen.dart';
import 'package:safety_eye_app/poc/semi_app/NavigatAppPage.dart';
import 'provider/SpeechScreen.dart';
import 'provider/CompressScreen.dart';
import 'DigitalSignitureScreen.dart';
import 'LoginRegisterPage.dart';
import 'Location.dart';

class MyHomePage extends StatelessWidget {
  final String title;
  final List<CameraDescription> cameras;

  const MyHomePage({Key? key, required this.title, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to SafetyEye!',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            const PocButtonWidget(title: "Login/Register", page: LoginRegisterPage()),
            const PocButtonWidget(title: "Text to speech", page: SpeechScreen()),
            const PocButtonWidget(title: "compression", page: CompressScreen()),
            const PocButtonWidget(title: "Accelerometer", page: AccelerometerScreen()),
            const PocButtonWidget(title: "Key Generation", page: DigitalSignatureScreen()),
            PocButtonWidget(title: "semi App", page: NavigateAppPage(cameras: cameras)),
            const PocButtonWidget(title: "backend Integration", page: BackendIntegrationScreen())
          ],
        ),
      ),
    );
  }
}

class PocButtonWidget extends StatelessWidget {
  final String title;
  final Widget page;

  const PocButtonWidget({Key? key, required this.title, required this.page}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Text(title),
    );
  }
}
