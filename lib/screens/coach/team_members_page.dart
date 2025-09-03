import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tv_oberwil/components/collection_list_page.dart';

import '../../components/collection_list_widget.dart';

class CoachTeamMembersPage extends StatelessWidget {
  final String teamId;

  const CoachTeamMembersPage({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    return CollectionListPage(
      title: "Teammitglieder",
      searchFields: ["search_first", "search_last"],
      query: FirebaseFirestore.instance
          .collection("teams")
          .doc(teamId)
          .collection("team_members"),
      collectionKey: "teams/$teamId/team_members",
      tableOptions: TableOptions((doc) {
        context.push("./team_member/${doc.id}");
      }),
      defaultOrderData: OrderData(
        TextDataField("search_last", "Nachname", true, false),
        false,
      ),
    );
  }
}
