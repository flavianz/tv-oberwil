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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Mit Mitglied verbinden"),
          bottom: TabBar(
            tabs: [
              Tab(text: "Mit Code", icon: Icon(Icons.pin)),
              Tab(text: "Mit QR-Code", icon: Icon(Icons.qr_code)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
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
            Center(),
          ],
        ),
      ),
    );
  }
}
