import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tv_oberwil/components/details_edit_page.dart';
import 'package:tv_oberwil/components/misc.dart';
import 'package:tv_oberwil/components/paginated_list_page.dart';
import 'package:tv_oberwil/utils.dart';

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
        DetailsTab(
          Tab(text: "Infos", icon: Icon(Icons.info_outline)),
          DetailsTabType.details,
          [
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
              DetailsEditProperty(
                "genders",
                "Geschlecht",
                DetailsEditPropertyType.selection,
                data: {"women": "Damen", "men": "Herren", "mixed": "Gemischt"},
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
        DetailsTab(
          Tab(text: "Spieler", icon: Icon(Icons.diversity_3)),
          DetailsTabType.list,
          PaginatedListPage(
            showBackButton: false,
            actionsInSearchBar: true,
            searchFields: ["search_first", "search_last"],
            query: FirebaseFirestore.instance
                .collection("teams")
                .doc(uid)
                .collection("team_members"),
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
                context.push("./../team/$uid/team_members/${doc.id}");
              },
            ),
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

Widget getPositionPill(role) {
  switch (role) {
    case "forward":
      return getPill("Stürmer", Colors.lightBlueAccent, true);
    case "center":
      return getPill("Center", Colors.greenAccent, false);
    case "defense":
      return getPill("Verteidigung", Colors.amberAccent, false);
    case "keeper":
      return getPill("Torhüter", Colors.redAccent, true);
    default:
      return getPill("Keine", Colors.grey, true);
  }
}

Widget getRolePill(role) {
  switch (role) {
    case "player":
      return getPill("Spieler", Colors.grey, true);
    case "no_licence":
      return getPill("Keine Lizenz", Colors.amberAccent, true);
    case "coach":
      return getPill("Trainer", Colors.green, true);
    case "assistant_coach":
      return getPill("Assistentstrainer", Colors.greenAccent, false);
    default:
      return getPill("Keine", Colors.grey, true);
  }
}
