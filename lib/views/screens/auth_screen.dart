import 'dart:developer';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:safety_eye_app/providers/auth_provider.dart';
import 'package:sign_in_button/sign_in_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final Logger _logger = Logger();
  bool _obscurePassword = false;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthenticationProvider>(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text("Safety Eye"),
            bottom: const TabBar(tabs: [
              Column(
                children: [
                  Icon(Icons.create),
                  Text("Sign up"),
                ],
              ),
              Column(
                children: [
                  Icon(Icons.person),
                  Text("Sign in"),
                ],
              )
            ]),
          ),
          body: Center(
            child: TabBarView(children: [
              buildSignUpForm(authProvider, "Sign Up"),
              buildSignInForm(authProvider, "Sign In"),
            ]),
          )),
    );
  }

  Widget buildSignUpForm(AuthenticationProvider authProvider, String buttonText) {
    return Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: "email"),
                  ),
                  TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: const InputDecoration(
                        labelText: "password",)
                  ),
                  ElevatedButton(onPressed: () async {
                    _logger.i("sign up with email: ${_emailController.value.text} and password: ${_passwordController.value}");
                    await authProvider.signUpWithEmailAndPassword(
                      _emailController.value.text,
                      _passwordController.value.text);
                  }, child: Text(buttonText)),
                  SignInButton(Buttons.google,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                      onPressed: () {
                    authProvider.signInWithGoogle();

                  }),
                ],
              ),
            ),
          );
  }
  Widget buildSignInForm(AuthenticationProvider authProvider, String buttonText) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "email"),
            ),
            TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: const InputDecoration(
                  labelText: "password",)
            ),
            ElevatedButton(onPressed: () async {
              await authProvider.signInWithEmailAndPassword(
                  _emailController.value.text,
                  _passwordController.value.text);
            }, child: Text(buttonText)),
            SignInButton(Buttons.google,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                onPressed: () {
                  authProvider.signInWithGoogle();

                }),
          ],
        ),
      ),
    );
  }

}
