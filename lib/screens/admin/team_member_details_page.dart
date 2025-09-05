import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tv_oberwil/components/details_edit_page.dart';

class TeamMemberDetailsPage extends StatelessWidget {
  final String teamId;
  final String teamMemberId;
  final bool created;

  const TeamMemberDetailsPage({
    super.key,
    required this.teamId,
    required this.teamMemberId,
    this.created = false,
  });

  @override
  Widget build(BuildContext context) {
    return DetailsEditPage(
      doc: FirebaseFirestore.instance
          .collection("teams")
          .doc(teamId)
          .collection("team_members")
          .doc(teamMemberId),
      created: created,
      tabs: [
        DetailsTabType(null, [
          /*[
            DetailsEditProperty(
              "first",
              "Vorname",
              TextPropertyType(isSearchable: true),
            ),
            DetailsEditProperty(
              "last",
              "Nachname",
              TextPropertyType(isSearchable: true),
            ),
            DetailsEditProperty(
              "roles",
              "Rollen",
              MultiSelectPropertyType((str) => getRolePill(str), {
                "player": "Spieler",
                "no_licence": "Keine Lizenz",
                "coach": "Trainer",
                "assistant_coach": "Assistentstrainer",
                "none": "Keine",
              }),
            ),
            DetailsEditProperty(
              "positions",
              "Positionen",
              MultiSelectPropertyType((str) => getPositionPill(str), {
                "forward": "Stürmer",
                "center": "Center",
                "defense": "Verteidigung",
                "keeper": "Torhüter",
                "none": "Keine",
              }),
            ),
          ],*/
        ]),
      ],
      titleKey: "first",
    );
  }
}
