import 'package:flutter/material.dart';

import 'LoginRegisterPage.dart';

class MyHomePage extends StatelessWidget {
  final String title;

  const MyHomePage({Key? key, required this.title}) : super(key: key);

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
            ElevatedButton(
              onPressed: () {
                // Navigate to the login/register page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginRegisterPage()),
                );
              },
              child: const Text('Login/Register'),
            )
          ],
        ),
      ),
    );
  }
}