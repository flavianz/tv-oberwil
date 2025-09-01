import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tv_oberwil/components/paginated_list_page.dart';
import 'package:tv_oberwil/utils.dart';

import '../../components/paginated_list.dart';

class TeamsScreen extends StatelessWidget {
  final bool refresh;

  const TeamsScreen({super.key, this.refresh = false});

  @override
  Widget build(BuildContext context) {
    return PaginatedListPage(
      query: FirebaseFirestore.instance.collection("teams"),
      collectionKey: "teams",
      title: "Teams",
      searchFields: ["search_name"],
      tableOptions: TableOptions((doc) {
        context.push("/admin/team/${doc.id}");
      }),
      actions: [
        FilledButton.icon(
          onPressed:
              () => context.push("./../team/${generateFirestoreKey()}/create"),
          label: Text("Neu"),
          icon: Icon(Icons.add),
        ),
      ],
      defaultOrderData: OrderData(
        TextDataField("search_name", "Nachname", true, false),
        false,
      ),
    );
  }
}
