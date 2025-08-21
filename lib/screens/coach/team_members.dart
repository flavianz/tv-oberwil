import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tv_oberwil/components/paginated_list_page.dart';

import '../../components/misc.dart';
import '../../utils.dart';

class CoachTeamMembers extends StatelessWidget {
  final String teamId;

  const CoachTeamMembers({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    return PaginatedListPage(
      title: "Teammitglieder",
      searchFields: ["search_first", "search_last"],
      query: FirebaseFirestore.instance
          .collection("teams")
          .doc(teamId)
          .collection("team_members"),
      collectionKey: "teams/$teamId/team_members",
      tableOptions: TableOptions(
        [
          TableColumn("last", "Nachname", (data) => Text(data), 1),
          TableColumn("first", "Vorname", (data) => Text(data), 1),
          TableColumn("roles", "Rolle", (data) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    castList(data).map((role) {
                      return getRolePill(role);
                    }).toList(),
              ),
            );
          }, 1),
          TableColumn("positions", "Position", (data) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    castList(data).map((role) {
                      return getPositionPill(role);
                    }).toList(),
              ),
            );
          }, 1),
        ],
        (doc) {
          context.push("./team_member/${doc.id}");
        },
      ),
    );
  }
}
