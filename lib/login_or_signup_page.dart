// lib/login_or_signup_page.dart
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'signup_page.dart';

class LoginOrSignUpPage extends StatefulWidget {
  const LoginOrSignUpPage({super.key});

  @override
  State<LoginOrSignUpPage> createState() => _LoginOrSignUpPageState();
}

class _LoginOrSignUpPageState extends State<LoginOrSignUpPage> {
  // initially, show the login page
  bool showLoginPage = true;

  // toggle between login and sign up page
  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(showSignUpPage: togglePages);
    } else {
      return SignUpPage(showLoginPage: togglePages);
    }
  }
}