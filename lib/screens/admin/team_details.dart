import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tv_oberwil/components/details_edit_page.dart';
import 'package:tv_oberwil/components/paginated_list_page.dart';

class TeamDetailsScreen extends StatelessWidget {
  final String uid;
  final bool created;

  const TeamDetailsScreen({
    super.key,
    required this.uid,
    required this.created,
  });

  @override
  Widget build(BuildContext context) {
    return DetailsEditPage(
      doc: FirebaseFirestore.instance.collection("teams").doc(uid),
      tabs: [
        (
          tab: Tab(text: "Infos", icon: Icon(Icons.info_outline)),
          type: DetailsTabType.details,
          data: [
            [
              DetailsEditProperty(
                "name",
                "Name",
                DetailsEditPropertyType.text,
                data: true,
              ),
              DetailsEditProperty(
                "plays_in_league",
                "Spielt in Liga",
                DetailsEditPropertyType.bool,
              ),
            ],
            [
              DetailsEditProperty(
                "type",
                "Teamart",
                DetailsEditPropertyType.selection,
                data: {
                  "juniors": "Junioren",
                  "active": "Aktive",
                  "fun": "Plausch",
                  "none": "Keine",
                },
              ),
              DetailsEditProperty(
                "sport_type",
                "Sportart",
                DetailsEditPropertyType.selection,
                data: {
                  "floorball": "Unihockey",
                  "volleyball": "Volleyball",
                  "riege": "Riege",
                  "none": "Keine",
                },
              ),
            ],
          ],
        ),
        (
          tab: Tab(text: "Spieler", icon: Icon(Icons.diversity_3)),
          type: DetailsTabType.list,
          data: PaginatedListPage(
            showBackButton: false,
            actionsInSearchBar: true,
            searchFields: ["search_first", "search_last"],
            query: FirebaseFirestore.instance
                .collection("teams")
                .doc(uid)
                .collection("players"),
            tableOptions: TableOptions([
              TableColumn("last", "Nachname", (data) => Text(data), 1),
              TableColumn("first", "Vorname", (data) => Text(data), 1),
              TableColumn("position", "Position", (data) => Text(data), 1),
              TableColumn("roles", "Rolle", (data) => Text(data[0]), 1),
            ], (_) {}),
            actions: [
              FilledButton.icon(
                onPressed: () {},
                label: Text("Hinzufügen"),
                icon: Icon(Icons.add),
              ),
            ],
          ),
        ),
      ],
      titleKey: "name",
    );
  }
}
