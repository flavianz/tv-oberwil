import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tv_oberwil/components/app.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberData = ref.watch(memberDataProvider);
    final String nickname = memberData.value?["first"] ?? "Unknown";
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
