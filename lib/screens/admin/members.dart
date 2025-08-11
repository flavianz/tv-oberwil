import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tv_oberwil/components/paginated_list_page.dart';

import '../../utils.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PaginatedListPage(
      builder: (doc) {
        return Text(doc.get("first"));
      },
      query: FirebaseFirestore.instance
          .collection("members")
          .orderBy("search_last"),
      searchFields: ["search_last", "search_first"],
      title: "Mitglieder",
      tableOptions: TableOptions(
        [
          TableColumn("last", "Nachname", (data) {
            return Text(data);
          }, 2),
          TableColumn("first", "Vorname", (data) {
            return Text(data);
          }, 2),
          TableColumn("user", "Ist verknüpft", (data) {
            return Text(data == null ? "Nein" : "Ja");
          }, 1),
        ],
        (doc) {
          context.push("/admin/member/${doc.id}");
        },
      ),
      actions: [
        FilledButton.icon(
          onPressed: () {
            context.push("/admin/member/${generateFirestoreKey()}?create=true");
          },
          icon: Icon(Icons.add),
          label: Text("Neu"),
        ),
      ],
    );
  }
}
