import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tv_oberwil/components/details_edit_page.dart';
import 'package:tv_oberwil/components/input_boxes.dart';

import '../../components/misc.dart';

class TeamMemberDetails extends StatelessWidget {
  final String teamId;
  final String teamMemberId;
  final bool created;

  const TeamMemberDetails({
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
        DetailsTab(null, DetailsTabType.details, [
          [
            DetailsEditProperty(
              "first",
              "Vorname",
              DetailsEditPropertyType.text,
              readOnly: true,
            ),
            DetailsEditProperty(
              "last",
              "Nachname",
              DetailsEditPropertyType.text,
              readOnly: true,
            ),
            DetailsEditProperty(
              "roles",
              "Rollen",
              DetailsEditPropertyType.multiSelect,
              data: MultiSelectInputBoxData((str) => getRolePill(str), {
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
              DetailsEditPropertyType.multiSelect,
              data: MultiSelectInputBoxData((str) => getPositionPill(str), {
                "forward": "Stürmer",
                "center": "Center",
                "defense": "Verteidigung",
                "keeper": "Torhüter",
                "none": "Keine",
              }),
            ),
          ],
        ]),
      ],
      titleKey: "first",
    );
  }
}
