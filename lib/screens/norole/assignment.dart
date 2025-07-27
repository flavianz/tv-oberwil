import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class Assignment extends StatefulWidget {
  const Assignment({super.key});

  @override
  State<Assignment> createState() => _AssignmentState();
}

class _AssignmentState extends State<Assignment> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            TextField(controller: controller),
            FilledButton(
              onPressed: () {
                FirebaseFunctions.instanceFor(region: "europe-west3")
                    .httpsCallable("assignUserToMember")
                    .call({"cipher": controller.text});
              },
              child: Text("Get"),
            ),
          ],
        ),
      ),
    );
  }
}
