import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tv_oberwil/components/details_edit_page.dart';
import 'package:tv_oberwil/components/misc.dart';
import 'package:tv_oberwil/components/paginated_list_page.dart';
import 'package:tv_oberwil/utils.dart';

import '../../components/paginated_list.dart';

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
        DetailsTabType(Tab(text: "Infos", icon: Icon(Icons.info_outline)), [
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
        ]),
        CustomTabType(
          Tab(text: "Mitglieder", icon: Icon(Icons.diversity_3)),
          PaginatedListPage(
            showBackButton: false,
            actionsInSearchBar: true,
            searchFields: ["search_first", "search_last"],
            query: FirebaseFirestore.instance
                .collection("teams")
                .doc(uid)
                .collection("team_members"),
            collectionKey: "teams/$uid/team_members",
            tableOptions: TableOptions(
              [
                TableColumn(
                  "last",
                  "Nachname",
                  (data) => Text(data),
                  1,
                  OrderPropertyType.text,
                ),
                TableColumn(
                  "first",
                  "Vorname",
                  (data) => Text(data),
                  1,
                  OrderPropertyType.text,
                ),
                TableColumn(
                  "roles",
                  "Rolle",
                  (data) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            castList(data).map((role) {
                              return getRolePill(role);
                            }).toList(),
                      ),
                    );
                  },
                  1,
                  OrderPropertyType.text,
                ),
                TableColumn(
                  "positions",
                  "Position",
                  (data) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            castList(data).map((role) {
                              return getPositionPill(role);
                            }).toList(),
                      ),
                    );
                  },
                  1,
                  OrderPropertyType.text,
                ),
              ],
              (doc) {
                context.push("./../team/$uid/team_member/${doc.id}");
              },
            ),
            actions: [
              IconButton.filled(onPressed: () {}, icon: Icon(Icons.add)),
            ],
            defaultOrderData: OrderData(
              TextDataField("search_last", "Nachname", true, false),
              false,
            ),
          ),
        ),
      ],
      titleKey: "name",
    );
  }
}
