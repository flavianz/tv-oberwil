import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final usersStreamProvider = StreamProvider<List<dynamic>>((ref) {
  return FirebaseFirestore.instance.collection('members').snapshots().map((
    snapshot,
  ) {
    return snapshot.docs.map((doc) => doc.data()).toList();
  });
});

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(usersStreamProvider);

    if (data.isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (data.hasError) {
      return Center(child: Text("An error has occurred"));
    }

    return Container(
      padding: EdgeInsets.all(10),
      child: Column(
        children: [
          AppBar(
            title: Text("Mitglieder"),
            actions: [
              FilledButton.icon(
                onPressed: () {},
                icon: Icon(Icons.add),
                label: Text("Mitglied hinzufügen"),
                style: FilledButton.styleFrom(minimumSize: Size(10, 55)),
              ),
            ],
          ),
          Expanded(
            child: DataTable(
              rows:
                  data.value!.map((member) {
                    return DataRow(
                      cells: [
                        DataCell(Text("${member["first"]} ${member["last"]}")),
                        DataCell(
                          Row(
                            children:
                                (member["roles"] as List).cast<String>().map((
                                  role,
                                ) {
                                  return Text(role);
                                }).toList(),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
              columns: [
                DataColumn(label: Text("Name")),
                DataColumn(label: Text("Rollen")),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
