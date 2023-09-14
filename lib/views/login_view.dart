import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as devtools show log;

import 'package:notes/constants/routes.dart';

import '../utilities/show_error_dialog.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}


class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;
  bool passwordVisible = false;

@override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    passwordVisible = true;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Column(
        children: [
        TextField(
          controller: _email,
          enableSuggestions: false,
          autocorrect: false,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
          hintText: 'Enter Your Email here'
          ),
        ),
        TextField(
          controller: _password,
          obscureText: passwordVisible,
          enableSuggestions: false,
          autocorrect: false,
          keyboardType: TextInputType.visiblePassword,
          decoration: InputDecoration(
            hintText: 'Enter Your Password here',
            suffixIcon: IconButton(
              icon: Icon(passwordVisible
                        ? Icons.visibility
                        : Icons.visibility_off),
              onPressed: () {
                setState(() {
                  passwordVisible = !passwordVisible;
                });
              },
            )
          ),
        ),
        TextButton(
          onPressed: () async {
            final email = _email.text;
            final password = _password.text;
            try {
              await FirebaseAuth.instance.signInWithEmailAndPassword(
                email: email, password: password);
              Navigator.of(context).pushNamedAndRemoveUntil(
                notesRoute, (route) => false);
            } on FirebaseAuthException catch (e) {
              if (e.code == 'INVALID_LOGIN_CREDENTIALS') {
                await showErrorDialog(
                  context,
                  'Invalid Login Credentials');
              } else {
                await showErrorDialog(
                  context,
                  'Error: ${e.code}');
            }
              } catch (e) {
                await showErrorDialog(
                  context,
                  'Error: ${e.toString()}');
              }
            },
            child: const Text('Login')),

            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  registerRoute,
                  (route) => false
                  );
              },
                child: const Text('New User? Register Here!'))
        ],
      ),
    ); 
  }
}

