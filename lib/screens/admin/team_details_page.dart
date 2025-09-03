import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tv_oberwil/components/details_edit_page.dart';
import 'package:tv_oberwil/components/collection_list_page.dart';
import 'package:tv_oberwil/utils.dart';

import '../../components/collection_list_widget.dart';

class TeamDetailsPage extends StatelessWidget {
  final String teamId;
  final bool created;

  const TeamDetailsPage({
    super.key,
    required this.teamId,
    this.created = false,
  });

  @override
  Widget build(BuildContext context) {
    final isScreenWide = MediaQuery.of(context).size.aspectRatio > 1;
    return DetailsEditPage(
      doc: FirebaseFirestore.instance.collection("teams").doc(teamId),
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
          CollectionListPage(
            showBackButton: false,
            actionsInSearchBar: true,
            searchFields: ["search_first", "search_last"],
            query: FirebaseFirestore.instance
                .collection("teams")
                .doc(teamId)
                .collection("team_members"),
            collectionKey: "teams/$teamId/team_members",
            tableOptions: TableOptions((doc) {
              context.push("./../team/$teamId/team_member/${doc.id}");
            }),
            actions: [
              IconButton.filled(
                onPressed: () async {
                  onSelect(List<DocumentSnapshot<Object?>> docs) async {
                    final batch = FirebaseFirestore.instance.batch();
                    for (final doc in docs) {
                      final data = castMap(doc.data());
                      batch.update(doc.reference, {
                        "roles.player": FieldValue.arrayUnion([teamId]),
                        "lU": FieldValue.serverTimestamp(),
                      });
                      batch.set(
                        FirebaseFirestore.instance
                            .collection("teams")
                            .doc(teamId)
                            .collection("team_members")
                            .doc(doc.id),
                        {
                          "first": data["first"],
                          "search_first": data["search_first"],
                          "last": data["last"],
                          "search_last": data["search_last"],
                          "positions": [],
                          "roles": ["player"],
                          "lU": FieldValue.serverTimestamp(),
                        },
                        SetOptions(merge: true),
                      );
                    }
                    await batch.commit();
                  }

                  if (isScreenWide) {
                    await showDialog<String>(
                      context: context,
                      builder:
                          (BuildContext context) => Dialog(
                            child: MembersSelector(
                              onSelect: onSelect,
                              confirmLabel: "Hinzufügen",
                            ),
                          ),
                    );
                  } else {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder:
                          (context) => FractionallySizedBox(
                            heightFactor: 0.7, // 90% of screen height
                            child: MembersSelector(
                              onSelect: onSelect,
                              confirmLabel: "Hinzufügen",
                            ),
                          ),
                    );
                  }
                },
                icon: Icon(Icons.add),
              ),
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

class MembersSelector extends StatefulWidget {
  final Function(List<DocumentSnapshot<Object?>>) onSelect;
  final String confirmLabel;

  const MembersSelector({
    super.key,
    required this.onSelect,
    required this.confirmLabel,
  });

  @override
  State<MembersSelector> createState() => _MembersSelectorState();
}

class _MembersSelectorState extends State<MembersSelector> {
  final List<DocumentSnapshot<Object?>> selected = [];
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: 1000, maxWidth: 800),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Expanded(
              child: CollectionListPage(
                query: FirebaseFirestore.instance.collection("members"),
                collectionKey: "members",
                defaultOrderData: OrderData(
                  TextDataField("search_last", "Nachname", false, false),
                  false,
                ),
                builder: (doc) {
                  final data = castMap(doc.data());
                  return Column(
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Checkbox(
                              value: selected.contains(doc),
                              onChanged: (newValue) {
                                if (newValue ?? true) {
                                  setState(() {
                                    selected.add(doc);
                                  });
                                } else {
                                  setState(() {
                                    selected.remove(doc);
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(child: Text(data["first"] ?? "")),
                          Expanded(child: Text(data["last"] ?? "")),
                        ],
                      ),
                      Divider(),
                    ],
                  );
                },
                searchFields: ["search_last", "search_first", "search_middle"],
              ),
            ),
            Row(
              spacing: 10,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text("Abbrechen"),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    setState(() {
                      loading = true;
                    });
                    await widget.onSelect(selected);
                    setState(() {
                      loading = false;
                    });
                    if (context.mounted) {
                      context.pop();
                    }
                  },
                  label:
                      loading
                          ? SizedBox(
                            height: 15,
                            width: 15,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                          : Text(widget.confirmLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
