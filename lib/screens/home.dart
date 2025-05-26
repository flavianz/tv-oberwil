import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String nickname =
        FirebaseAuth.instance.currentUser?.displayName ?? "not logged in";
    return Center(
      child: Column(
        children: [
          Text(nickname),
          TextButton(
            child: Text("Sign out"),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }
}
