import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tv_oberwil/components/paginated_list.dart';
import 'package:tv_oberwil/firestore_providers/paginated_list_proivder.dart';
import 'package:tv_oberwil/utils.dart';

import '../../components/app.dart';
import '../../components/misc.dart';
import '../../firestore_providers/basic_providers.dart';

class PlayerEventDetails extends ConsumerWidget {
  final String teamId;
  final String eventId;
  final bool isCoach;

  const PlayerEventDetails({
    super.key,
    required this.teamId,
    required this.eventId,
    this.isCoach = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isScreenWide = MediaQuery.of(context).size.aspectRatio > 1;

    final eventDoc = ref.watch(
      realtimeDocProvider(
        FirebaseFirestore.instance
            .collection("teams")
            .doc(teamId)
            .collection("events")
            .doc(eventId),
      ),
    );

    if (eventDoc.isLoading || !eventDoc.hasValue) {
      return Center(child: CircularProgressIndicator());
    }

    if (eventDoc.hasError) {
      return Center(
        child: SelectableText("An error occurred: ${eventDoc.error}"),
      );
    }

    final recEventsProvider = ref.watch(
      getCollectionProvider(
        "teams/$teamId/r_events",
        FirebaseFirestore.instance
            .collection("teams")
            .doc(teamId)
            .collection("r_events"),
      ),
    );
    if (recEventsProvider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (recEventsProvider.hasError || !recEventsProvider.hasValue) {
      return Center(child: Text("${recEventsProvider.error}"));
    }

    final recEvents = <String, Map<String, dynamic>>{
      for (var doc in recEventsProvider.value!) doc.id: castMap(doc.data()),
    };

    final eventData = castMap(eventDoc.value?.data());

    dynamic getValue(String key, {dynamic defaultV}) {
      if (eventData["r"] != null && eventData[key] == null) {
        dynamic value = recEvents[eventData["r"]]?[key];
        final edits = List<Map<String, dynamic>>.of(
          castList(recEvents[eventData["r"]]?["edits"]).map((e) => castMap(e)),
        )..sort(
          (a, b) => castDateTime(a["time"]).compareTo(castDateTime(b["time"])),
        );

        for (dynamic edit in edits) {
          final after = castDateTime(edit["after"]);
          final date = castDateTime(eventData["date"]);
          if (after.millisecondsSinceEpoch <= date.millisecondsSinceEpoch ||
              isSameDay(after, date)) {
            value = edit["fields"]?[key] ?? value;
          }
        }

        return value ?? defaultV;
      }
      return eventData[key] ?? defaultV;
    }

    final date = castDateTime(getValue("date"));
    final meetDate = castDateTime(getValue("meet"));
    final startDate = castDateTime(getValue("start"));
    final endDate = castDateTime(getValue("end"));

    final localMemberUid = ref.watch(userDataProvider).value?["member"];
    final presence = castMap(eventData["presence"]);

    final isLateToVote =
        DateTime.now().isAfter(
          DateTime(
            date.year,
            date.month,
            date.day,
            startDate.hour,
            startDate.minute,
          ),
        ) &&
        !isCoach;

    void cancel(memberId) {
      if (isLateToVote) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Du bist zu spät!')));
        return;
      }
      showStringInputDialog(
        title: "Abmelden",
        hintText: "Gib einen Grund an",
        context: context,
        onSubmit: (input) async {
          await FirebaseFirestore.instance
              .collection('teams')
              .doc(teamId)
              .collection("events")
              .doc(eventId)
              .update({
                'presence.$memberId': {"value": 'a', "reason": input},
                // only this key inside the map is updated
              });
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Abgemeldet!')));
          }
        },
      );
    }

    void unsure(memberId) {
      if (isLateToVote) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Du bist zu spät!')));
        return;
      }
      showStringInputDialog(
        title: "Unsicher melden",
        hintText: "Gib einen Grund an",
        context: context,
        onSubmit: (input) async {
          await FirebaseFirestore.instance
              .collection('teams')
              .doc(teamId)
              .collection("events")
              .doc(eventId)
              .update({
                'presence.$memberId': {"value": 'u', "reason": input},
                // only this key inside the map is updated
              });
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Als unsicher gemeldet!')));
          }
        },
      );
    }

    void register(memberId) {
      if (isLateToVote) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Du bist zu spät!')));
        return;
      }
      FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .collection("events")
          .doc(eventId)
          .update({
            'presence.$memberId': {"value": 'p', "reason": ""},
            // only this key inside the map is updated
          });
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Angemeldet!')));
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isScreenWide ? 35 : 0,
        vertical: 15,
      ),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Text(getValue("name", defaultV: "")),
                getValue("cancelled") == true
                    ? getPill("Abgesagt", Colors.red, true)
                    : getNearbyTimeDifference(date) != null
                    ? getPill(
                      getNearbyTimeDifference(date)!,
                      isSameDay(date, DateTime.now())
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).colorScheme.secondaryFixedDim,
                      isSameDay(date, DateTime.now()),
                    )
                    : SizedBox.shrink(),
              ],
            ),
            bottom: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.info_outline), text: "Infos"),
                Tab(icon: Icon(Icons.people_alt), text: "Teilnehmer"),
                /*Tab(icon: Icon(Icons.directions_car), text: "Mitfahren"),*/
              ],
            ),
            actions:
                isCoach
                    ? [
                      IconButton(
                        onPressed: () {
                          context.push(
                            "/coach/team/$teamId/event/$eventId/edit",
                          );
                        },
                        icon: Icon(Icons.edit),
                      ),
                    ]
                    : [],
          ),
          body: Padding(
            padding: EdgeInsets.only(top: 20),
            child: TabBarView(
              children: [
                ListView(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                getWeekday(date.weekday),
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                "${date.day}.${date.month}.",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 65,
                          child: VerticalDivider(thickness: 1, width: 30),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    "Treffen",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    "${meetDate.hour.toString().padLeft(2, '0')}:${meetDate.minute.toString().padLeft(2, '0')}",
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 55,
                                child: VerticalDivider(
                                  thickness: 0.5,
                                  width: 30,
                                ),
                              ),
                              Column(
                                children: [
                                  Text("Start", style: TextStyle(fontSize: 12)),
                                  Text(
                                    "${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}",
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 55,
                                child: VerticalDivider(
                                  thickness: 0.5,
                                  width: 30,
                                ),
                              ),
                              Column(
                                children: [
                                  Text("Ende", style: TextStyle(fontSize: 12)),
                                  Text(
                                    "${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}",
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 30,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 10,
                        children: [
                          Icon(
                            Icons.place_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          Text(
                            getValue("location", defaultV: "Keine Ortsangabe"),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 5,
                        children: [
                          Flexible(
                            fit: FlexFit.loose,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: FilledButton(
                                onPressed: () => register(localMemberUid),
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      castMap(
                                                presence[localMemberUid],
                                              )["value"] ==
                                              "p"
                                          ? Colors.green
                                          : Colors.grey,
                                  // set your desired color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      10,
                                    ), // less round corners
                                  ),
                                ),
                                child: Center(
                                  child: Wrap(
                                    spacing: 5,
                                    children: [
                                      Text("Dabei"),
                                      Text(
                                        presence.values
                                            .where(
                                              (value) =>
                                                  castMap(value)["value"] ==
                                                  "p",
                                            )
                                            .length
                                            .toString(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          Flexible(
                            fit: FlexFit.loose,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: FilledButton(
                                onPressed: () => unsure(localMemberUid),
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      castMap(
                                                presence[localMemberUid],
                                              )["value"] ==
                                              "u"
                                          ? Colors.amber
                                          : Colors.grey,
                                  // set your desired color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      10,
                                    ), // less round corners
                                  ),
                                ),
                                child: Wrap(
                                  spacing: 5,
                                  children: [
                                    Text("Unsicher"),
                                    Text(
                                      presence.values
                                          .where(
                                            (value) =>
                                                castMap(value)["value"] == "u",
                                          )
                                          .length
                                          .toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Flexible(
                            fit: FlexFit.loose,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: FilledButton(
                                onPressed: () => cancel(localMemberUid),
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      castMap(
                                                presence[localMemberUid],
                                              )["value"] ==
                                              "a"
                                          ? Colors.redAccent
                                          : Colors.grey,
                                  // set your desired color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      10,
                                    ), // less round corners
                                  ),
                                ),
                                child: Wrap(
                                  spacing: 5,
                                  children: [
                                    Text("Abwesend"),
                                    Text(
                                      presence.values
                                          .where(
                                            (value) =>
                                                castMap(value)["value"] == "a",
                                          )
                                          .length
                                          .toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(height: 30),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Notizen",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              getValue("notes", defaultV: ""),
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                PaginatedList(
                  builder: (doc) {
                    final playerData = castMap(doc.data());
                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 5,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${playerData["first"] ?? ""} ${playerData["last"] ?? ""}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    ((presence[doc.id]?["reason"] ?? "")
                                                as String)
                                            .isNotEmpty
                                        ? Text(
                                          presence[doc.id]?["reason"] ?? "",
                                        )
                                        : SizedBox.shrink(),
                                  ],
                                ),
                              ),
                              MenuAnchor(
                                menuChildren: [
                                  MenuItemButton(
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all(
                                        Colors.green,
                                      ),
                                    ),
                                    onPressed: () => register(doc.id),
                                    child: Text(
                                      "Dabei",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  MenuItemButton(
                                    onPressed: () => unsure(doc.id),
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all(
                                        Colors.amber,
                                      ),
                                    ),
                                    child: Text(
                                      "Unsicher",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  MenuItemButton(
                                    onPressed: () => cancel(doc.id),
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all(
                                        Colors.red,
                                      ),
                                    ),
                                    child: Text(
                                      "Abwesend",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                                builder: (_, controller, _) {
                                  return FilledButton.icon(
                                    icon: isCoach ? Icon(Icons.edit) : null,
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all(
                                        presence[doc.id]?["value"] == "p"
                                            ? Colors.green
                                            : (presence[doc.id]?["value"] == "u"
                                                ? Colors.amber
                                                : (presence[doc.id]?["value"] ==
                                                        "a"
                                                    ? Colors.redAccent
                                                    : Colors.grey)),
                                      ),
                                    ),
                                    onPressed:
                                        isCoach
                                            ? () {
                                              if (controller.isOpen) {
                                                controller.close();
                                              } else {
                                                controller.open();
                                              }
                                            }
                                            : null,
                                    label: Text(
                                      presence[doc.id]?["value"] == "p"
                                          ? "Dabei"
                                          : (presence[doc.id]?["value"] == "u"
                                              ? "Unsicher"
                                              : (presence[doc.id]?["value"] ==
                                                      "a"
                                                  ? "Abwesend"
                                                  : "Keine Antwort")),
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Divider(thickness: 0.5),
                      ],
                    );
                  },
                  query: FirebaseFirestore.instance.collection("members"),
                  filter:
                      (docs) =>
                          docs.where((doc) {
                              final data = castMap(doc.data());
                              return data["roles"] != null &&
                                  data["roles"] is Map &&
                                  data["roles"]!["player"] != null &&
                                  data["roles"]!["player"] is List &&
                                  (data["roles"]!["player"]! as List<dynamic>)
                                      .contains(teamId);
                            }).toList()
                            ..sort((a, b) {
                              convert(String c) => switch (c) {
                                "a" => "c",
                                "u" => "b",
                                "p" => "a",
                                _ => c,
                              };

                              final aValue = convert(
                                eventData["presence"]?[a.id]?["value"]
                                        as String? ??
                                    "z",
                              );
                              final bValue = convert(
                                eventData["presence"]?[b.id]?["value"]
                                        as String? ??
                                    "z",
                              );

                              return aValue.compareTo(bValue);
                            }),
                  collectionKey: "members",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
