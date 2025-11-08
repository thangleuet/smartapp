import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:phonekit_manager/screen/home.dart';
import 'package:phonekit_manager/screen/login.dart';

class Main_Page extends StatelessWidget {
  const Main_Page({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final user = snapshot.data;
            final String? email = user?.email;
            return Home(email!, "");
          } else {
            return LogIN_Screen();
          }
        },
      ),
    );
  }
}
