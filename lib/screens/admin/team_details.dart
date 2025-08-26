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

  const TeamDetailsScreen({super.key, required this.uid, this.created = false});

  @override
  Widget build(BuildContext context) {
    return DetailsEditPage(
      doc: FirebaseFirestore.instance.collection("teams").doc(uid),
      created: created,
      tabs: [
        DetailsTab(
          Tab(text: "Infos", icon: Icon(Icons.info_outline)),
          DetailsTabType.details,
          [
            [
              DetailsEditProperty(
                "name",
                "Name",
                TextPropertyType(isSearchable: true),
              ),
              DetailsEditProperty(
                "plays_in_league",
                "Spielt in Liga",
                BoolPropertyType(),
              ),
              DetailsEditProperty(
                "genders",
                "Geschlecht",
                SelectionPropertyType({
                  "women": "Damen",
                  "men": "Herren",
                  "mixed": "Gemischt",
                  "null": "Keine Angabe",
                }),
              ),
            ],
            [
              DetailsEditProperty(
                "type",
                "Teamart",
                SelectionPropertyType({
                  "juniors": "Junioren",
                  "active": "Aktive",
                  "fun": "Plausch",
                  "null": "Keine Angabe",
                }),
              ),
              DetailsEditProperty(
                "sport_type",
                "Sportart",
                SelectionPropertyType({
                  "floorball": "Unihockey",
                  "volleyball": "Volleyball",
                  "riege": "Riege",
                  "null": "Keine Angabe",
                }),
              ),
            ],
          ],
        ),
        DetailsTab(
          Tab(text: "Mitglieder", icon: Icon(Icons.diversity_3)),
          DetailsTabType.list,
          PaginatedListPage(
            showBackButton: false,
            actionsInSearchBar: true,
            searchFields: ["search_first", "search_last"],
            query: FirebaseFirestore.instance
                .collection("teams")
                .doc(uid)
                .collection("team_members"),
            collectionKey: "teams/$uid/team_members",
            filters: [
              ChipFilter("roles", "Rollen", Icons.person_outline, {
                "player": "Spieler",
                "no_licence": "Keine Lizenz",
                "coach": "Trainer",
                "assistant_coach": "Assistentstrainer",
                "null": "Keine",
              }, isList: true),
              ChipFilter("positions", "Positionen", Icons.location_searching, {
                "forward": "Stürmer",
                "center": "Center",
                "defense": "Verteidigung",
                "keeper": "Torhüter",
                "null": "Keine",
              }, isList: true),
            ],
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
                context.push("./../team/$uid/team_member/${doc.id}");
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
