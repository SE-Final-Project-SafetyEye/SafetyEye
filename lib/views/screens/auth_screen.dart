import 'dart:developer';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:provider/provider.dart';
import 'package:safety_eye_app/providers/auth_provider.dart';
import 'package:sign_in_button/sign_in_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKeySignUp = GlobalKey<FormState>();
  final _formKeySignIn = GlobalKey<FormState>();
  bool _obscurePassword = true;
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
                    await authProvider.signUpWithEmailAndPassword(
                      _emailController.value.text,
                      _passwordController.value.text);
                    Navigator.of(context).popAndPushNamed('/home');
                  }, child: Text(buttonText)),
                  SignInButton(Buttons.google,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                      onPressed: () async {
                    await authProvider.signInWithGoogle();
                    Navigator.of(context).popAndPushNamed('/home');

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
              Navigator.of(context).popAndPushNamed('/home');
            }, child: Text(buttonText)),
            SignInButton(Buttons.google,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                onPressed: () async {
                  await authProvider.signInWithGoogle();
                  Navigator.of(context).popAndPushNamed('/home');

                }),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticationForm(GlobalKey<FormState> formKey, String buttonText,
      void Function(String email, String password) signUpFunction, void Function() signInGoogle) {
    return Center(
      child: Form(
        key: formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "email"),
              validator: (String? value) {
                if (EmailValidator.validate(value ?? "")) {
                  return null;
                }
                return "Please enter a valid email";
              },
            ),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              validator: (String? value) {
                if (value!.isEmpty) {
                  return "Please enter a password";
                }
                return null;
              },
              decoration: InputDecoration(
                  labelText: "password",
                  suffixIcon: InkWell(
                    onTapDown: (tapDownDetails) {
                      setState(() {
                        _obscurePassword = false;
                      });
                    },
                    onTapUp: (tapUpDetails) {
                      setState(() {
                        _obscurePassword = true;
                      });
                    },
                  )),
            ),
            ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    signUpFunction(_emailController.value.text, _passwordController.value.text);
                  }
                },
                child: Text(buttonText)),
            SignInButton(Buttons.google,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                onPressed: () async {
              signInGoogle();
            }),
          ],
        ),
      ),
    );
  }

  Widget _signUpForm() {
    return Container();
  }

  Widget _signInForm() {
    return Container();
  }
}
