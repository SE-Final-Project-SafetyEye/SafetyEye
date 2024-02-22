import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import 'AuthProvider.dart';
import 'semi_app/NavigatAppPage.dart';

class LoginRegisterPage extends StatefulWidget {
  const LoginRegisterPage({super.key});

  @override
  State<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage> {
  late final TextEditingController _email;
  late final TextEditingController _password;
  final Logger _log = Logger();

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(50),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 50),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 30),
                  title: Text(
                    'Hello, Welcome!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  subtitle: Text(
                    'Please, Log-in or Register for moving on',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white54,
                        ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildTextField(_email, 'Enter your email', Icons.email_outlined),
                const SizedBox(height: 16.0),
                buildTextField(_password, 'Enter your password', Icons.lock_clock_outlined, isPassword: true),
                const SizedBox(height: 16.0),
                buildElevatedButton(
                  'Register',
                  () {
                    final email = _email.text;
                    final password = _password.text;
                    authProvider.signUpWithEmailAndPassword(email, password).then((_) {
                      Navigator.pop(context);
                      showSnackBar(context, 'Successfully registered');
                    }).catchError((error) {
                      showSnackBar(context, "Failed to register to app");
                      _log.e(error);
                    });
                  },
                ),
                const SizedBox(height: 8.0),
                buildElevatedButton(
                  'Login',
                  () {
                    final email = _email.text;
                    final password = _password.text;
                    authProvider.signInWithEmailAndPassword(email, password).then((_) {
                      showSnackBar(context, 'Successfully logged in');
                      Navigator.pop(context);
                    }).catchError((error) {
                      showSnackBar(context, "Failed to login");
                      _log.e(error);
                    });
                  },
                ),
                const SizedBox(height: 16.0),
                buildElevatedButton(
                    'Sign with Google',
                    () => authProvider.signInWithGoogle().then((_) {
                          showSnackBar(context, "Successfully signed in");
                          Navigator.pop(context);
                        }).catchError((error) {
                          showSnackBar(context, "Failed to sign in with Google");
                          _log.e(error);
                        })),
              ],
            ),
          ),
          const SizedBox(height: 20),
          buildElevatedButton("sign out", () {
            authProvider.signOut().then((_) {
              showSnackBar(context, "signed out");
              Navigator.pop(context);
            }).catchError((error) {
              showSnackBar(context, "failed to sign out");
              _log.e(error);
            });
          }),
        ],
      ),
    );
  }

  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget buildTextField(TextEditingController controller, String hintText, IconData prefixIcon,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      enableSuggestions: false,
      autocorrect: false,
      keyboardType: isPassword ? TextInputType.visiblePassword : TextInputType.emailAddress,
      decoration: InputDecoration(
        prefixIcon: Icon(prefixIcon),
        hintText: hintText,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  Widget buildElevatedButton(String label, void Function() onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        shadowColor: Colors.grey.withOpacity(0.5),
        elevation: 5,
      ),
      child: Text(label),
    );
  }

  void showAlertDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
