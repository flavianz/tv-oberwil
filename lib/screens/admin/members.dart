import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tv_oberwil/components/paginated_list.dart';
import 'package:tv_oberwil/components/paginated_list_page.dart';

import '../../utils.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PaginatedListPage(
      query: FirebaseFirestore.instance.collection("members"),
      collectionKey: "members",
      searchFields: ["search_last", "search_first", "search_middle"],
      title: "Mitglieder",
      tableOptions: TableOptions((doc) {
        context.push("/admin/member/${doc.id}");
      }),
      actions: [
        FilledButton.icon(
          onPressed: () {
            context.push("/admin/member/${generateFirestoreKey()}?create=true");
          },
          icon: Icon(Icons.add),
          label: Text("Neu"),
        ),
      ],
      defaultOrderData: OrderData(
        TextDataField("search_last", "Nachname", true, false),
        false,
      ),
    );
  }
}
