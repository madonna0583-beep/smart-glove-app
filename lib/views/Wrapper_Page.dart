import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_glove_app/views/login_page.dart';
import 'package:smart_glove_app/views/main_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return LoginPage();
    } else {
      return MainPage();
    }
  }
}
