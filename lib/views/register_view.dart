import 'package:flutter/material.dart';
import 'package:notes/constants/routes.dart';
import 'package:notes/services/auth/auth_exceptions.dart';
import 'package:notes/services/auth/auth_service.dart';
import 'package:notes/utilities/show_error_dialog.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {

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
        title: const Text('Register'),
        backgroundColor: Theme.of(context).primaryColor,
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
            hintText: 'Input Your Password here',
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
              await AuthService.firebase().createUser(
                email: email, 
                password: password);
                AuthService.firebase().sendEmailVerifiation();
                Navigator.of(context).pushNamed(verifyEmailRoute);
            } on WeakPasswordAuthException {
                await showErrorDialog(
                  context,
                  'Password must be atleast 6 characters long');
            } on EmailAlreadyInUseAuthException {
                await showErrorDialog(
                  context,
                  'Email already in use');
            } on InvalidEmailAuthException {
                await showErrorDialog(
                  context,
                  'Invalid Email');
            } on GenericAuthException {
                await showErrorDialog(
                  context,
                  'Failed to register!');
            }
            },
            child: const Text('Register')),

            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                      loginRoute,
                      (route) => false
                      );
              },
              child: const Text('Already Registered? Login here!'),
              )
        ],
      ),
    ); 
  }
}