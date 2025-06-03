import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userStreamProvider = StreamProvider.family<
  DocumentSnapshot<Map<String, dynamic>>,
  String
>((ref, uid) {
  return FirebaseFirestore.instance.collection('members').doc(uid).snapshots();
});

class MemberDetailsScreen extends ConsumerWidget {
  final String uid;

  const MemberDetailsScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTablet = MediaQuery.of(context).size.aspectRatio > 1;

    final memberData = ref.watch(userStreamProvider(uid));

    if (memberData.isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (memberData.hasError) {
      return Center(child: Text("An error occurred loading your data"));
    }
    DateTime birthdate = DateTime.fromMillisecondsSinceEpoch(
      (memberData.value?["birthdate"] as Timestamp).millisecondsSinceEpoch,
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 35 : 0,
        vertical: 15,
      ),
      child: Scaffold(
        appBar: AppBar(
          actionsPadding: EdgeInsets.symmetric(horizontal: 12),
          title: Text(
            "${memberData.value?["last"]}, ${memberData.value!["first"]}",
          ),
          actions: [
            IconButton(onPressed: () {}, icon: Icon(Icons.edit)),
            IconButton(onPressed: () {}, icon: Icon(Icons.delete)),
          ],
        ),
        body: Column(
          children: [
            Text(
              "Birthdate: ${birthdate.day}. ${birthdate.month}. ${birthdate.year}",
            ),
          ],
        ),
      ),
    );
  }
}
