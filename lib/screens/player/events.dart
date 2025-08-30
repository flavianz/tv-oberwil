import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tv_oberwil/components/app.dart';
import 'package:tv_oberwil/components/misc.dart';
import 'package:tv_oberwil/components/paginated_list.dart';

import '../../firestore_providers/paginated_list_proivder.dart';
import '../../utils.dart';

class PlayerEvents extends ConsumerStatefulWidget {
  final String teamId;
  final bool isCoach;

  const PlayerEvents({super.key, required this.teamId, this.isCoach = false});

  @override
  ConsumerState<PlayerEvents> createState() => _PlayerEventsState();
}

class _PlayerEventsState extends ConsumerState<PlayerEvents> {
  @override
  Widget build(BuildContext context) {
    final isScreenWide = MediaQuery.of(context).size.aspectRatio > 1;

    final recEventsProvider = ref.watch(
      getCollectionProvider(
        "teams/${widget.teamId}/r_events",
        FirebaseFirestore.instance
            .collection("teams")
            .doc(widget.teamId)
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

    builder(DocumentSnapshot<Object?> doc, model) {
      final eventData = castMap(doc.data());

      dynamic getValue(String key, {dynamic defaultV}) {
        if (eventData["r"] != null && eventData[key] == null) {
          dynamic value = recEvents[eventData["r"]]?[key];
          final edits = List<Map<String, dynamic>>.of(
            castList(
              recEvents[eventData["r"]]?["edits"],
            ).map((e) => castMap(e)),
          )..sort(
            (a, b) =>
                castDateTime(a["time"]).compareTo(castDateTime(b["time"])),
          );

          for (dynamic edit in edits) {
            final after = castDateTime(edit["after"]);
            final date = castDateTime(eventData["date"]);
            if (after.millisecondsSinceEpoch <= date.millisecondsSinceEpoch ||
                isSameDate(after, date)) {
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
      final presence = castMap(eventData["presence"]);
      final localMemberUid = ref.read(userDataProvider).value?["member"];

      final dateBox = ConstrainedBox(
        constraints: BoxConstraints(minWidth: 80),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(getWeekday(date.weekday), style: TextStyle(fontSize: 12)),
              Text(
                "${date.day}.${date.month}.",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );

      final nameBox = Padding(
        padding: EdgeInsets.only(left: 15),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getValue("name", defaultV: ""),
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),

                  Text(
                    getValue("location", defaultV: ""),
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            getValue("cancelled") == true
                ? getPill("Abgesagt", Colors.red, true)
                : getNearbyTimeDifference(date) != null
                ? getPill(
                  getNearbyTimeDifference(date)!,
                  isSameDate(date, DateTime.now())
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).colorScheme.secondaryFixedDim,
                  isSameDate(date, DateTime.now()),
                )
                : SizedBox.shrink(),
          ],
        ),
      );

      final timesBox = Padding(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              children: [
                Text("Treffen", style: TextStyle(fontSize: 12)),
                Text(
                  "${meetDate.hour.toString().padLeft(2, '0')}:${meetDate.minute.toString().padLeft(2, '0')}",
                ),
              ],
            ),
            VerticalDivider(thickness: 0.5, width: 30),
            Column(
              children: [
                Text("Start", style: TextStyle(fontSize: 12)),
                Text(
                  "${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}",
                ),
              ],
            ),
            VerticalDivider(thickness: 0.5, width: 30),
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
      );
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
          !widget.isCoach;

      final voteBox = Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 5,
          children: [
            FilledButton(
              onPressed: () async {
                if (isLateToVote) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Du bist zu spät!')));
                  return;
                }
                await FirebaseFirestore.instance
                    .collection('teams')
                    .doc(widget.teamId)
                    .collection("events")
                    .doc(doc.id)
                    .update({
                      'presence.$localMemberUid': {"value": 'p', "reason": ""},
                      // only this key inside the map is updated
                    });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Du bist angemeldet!')),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor:
                    castMap(presence[localMemberUid])["value"] == "p"
                        ? Colors.green
                        : Colors.grey,
                // set your desired color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // less round corners
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Dabei"),
                    Text(
                      presence.values
                          .where((value) => castMap(value)["value"] == "p")
                          .length
                          .toString(),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              spacing: 5,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FilledButton(
                  onPressed: () {
                    if (isLateToVote) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Du bist zu spät!')),
                      );
                      return;
                    }
                    showStringInputDialog(
                      title: "Unsicher melden",
                      hintText: "Gib einen Grund an",
                      context: context,
                      onSubmit: (input) async {
                        await FirebaseFirestore.instance
                            .collection('teams')
                            .doc(widget.teamId)
                            .collection("events")
                            .doc(doc.id)
                            .update({
                              'presence.$localMemberUid': {
                                "value": 'u',
                                "reason": input,
                              },
                              // only this key inside the map is updated
                            });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Du bist als unsicher gemeldet!'),
                            ),
                          );
                        }
                      },
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        castMap(presence[localMemberUid])["value"] == "u"
                            ? Colors.amber
                            : Colors.grey,
                    // set your desired color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        10,
                      ), // less round corners
                    ),
                  ),
                  child: Row(
                    spacing: 5,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Unsicher"),
                      Text(
                        presence.values
                            .where((value) => castMap(value)["value"] == "u")
                            .length
                            .toString(),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    if (isLateToVote) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Du bist zu spät!')),
                      );
                      return;
                    }
                    showStringInputDialog(
                      title: "Abmelden",
                      hintText: "Gib einen Grund an",
                      context: context,
                      onSubmit: (input) async {
                        await FirebaseFirestore.instance
                            .collection('teams')
                            .doc(widget.teamId)
                            .collection("events")
                            .doc(doc.id)
                            .update({
                              'presence.$localMemberUid': {
                                "value": 'a',
                                "reason": input,
                              },
                              // only this key inside the map is updated
                            });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Du bist abgemeldet!')),
                          );
                        }
                      },
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        castMap(presence[localMemberUid])["value"] == "a"
                            ? Colors.redAccent
                            : Colors.grey,
                    // set your desired color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        10,
                      ), // less round corners
                    ),
                  ),
                  child: Row(
                    spacing: 5,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Abwesend"),
                      Text(
                        presence.values
                            .where((value) => castMap(value)["value"] == "a")
                            .length
                            .toString(),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      final bool isWideEnough = MediaQuery.of(context).size.width > 1200;

      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            context.push(
              "/${widget.isCoach ? "coach" : "player"}/team/${widget.teamId}/event/${doc.id}",
            );
          },
          child: Card.outlined(
            elevation: 1,
            child: Padding(
              padding: EdgeInsets.all(15),
              child:
                  isWideEnough
                      ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          dateBox,
                          SizedBox(
                            height: 65,
                            child: VerticalDivider(width: 20),
                          ),
                          Expanded(child: nameBox),
                          SizedBox(
                            height: 65,
                            child: VerticalDivider(width: 20),
                          ),
                          timesBox,
                          SizedBox(
                            height: 65,
                            child: VerticalDivider(width: 20),
                          ),
                          voteBox,
                        ],
                      )
                      : Column(
                        children: [
                          Row(
                            children: [
                              dateBox,
                              SizedBox(
                                height: 40,
                                child: VerticalDivider(width: 20),
                              ),
                              Expanded(child: nameBox),
                            ],
                          ),
                          SizedBox(height: 20),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 10,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                  height: 35,
                                  child: VerticalDivider(
                                    thickness: 0.5,
                                    width: 30,
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      "Start",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      "${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}",
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 35,
                                  child: VerticalDivider(
                                    thickness: 0.5,
                                    width: 30,
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      "Ende",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      "${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}",
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 5,
                            children: [
                              Flexible(
                                fit: FlexFit.loose,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: FilledButton(
                                    onPressed: () async {
                                      if (isLateToVote) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Du bist zu spät!'),
                                          ),
                                        );
                                        return;
                                      }
                                      await FirebaseFirestore.instance
                                          .collection('teams')
                                          .doc(widget.teamId)
                                          .collection("events")
                                          .doc(doc.id)
                                          .update({
                                            'presence.$localMemberUid': {
                                              "value": 'p',
                                              "reason": "",
                                            },
                                            // only this key inside the map is updated
                                          });
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Du bist angemeldet!',
                                            ),
                                          ),
                                        );
                                      }
                                    },
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
                                    onPressed: () {
                                      if (isLateToVote) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Du bist zu spät!'),
                                          ),
                                        );
                                        return;
                                      }
                                      showStringInputDialog(
                                        title: "Unsicher melden",
                                        hintText: "Gib einen Grund an",
                                        context: context,
                                        onSubmit: (input) async {
                                          await FirebaseFirestore.instance
                                              .collection('teams')
                                              .doc(widget.teamId)
                                              .collection("events")
                                              .doc(doc.id)
                                              .update({
                                                'presence.$localMemberUid': {
                                                  "value": 'u',
                                                  "reason": input,
                                                },
                                                // only this key inside the map is updated
                                              });
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Du bist als unsicher gemeldet!',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      );
                                    },
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
                                                    castMap(value)["value"] ==
                                                    "u",
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
                                    onPressed: () {
                                      if (isLateToVote) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Du bist zu spät!'),
                                          ),
                                        );
                                        return;
                                      }
                                      showStringInputDialog(
                                        title: "Abmelden",
                                        hintText: "Gib einen Grund an",
                                        context: context,
                                        onSubmit: (input) async {
                                          await FirebaseFirestore.instance
                                              .collection('teams')
                                              .doc(widget.teamId)
                                              .collection("events")
                                              .doc(doc.id)
                                              .update({
                                                'presence.$localMemberUid': {
                                                  "value": 'a',
                                                  "reason": input,
                                                },
                                                // only this key inside the map is updated
                                              });
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Du bist abgemeldet!',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      );
                                    },
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
                                                    castMap(value)["value"] ==
                                                    "a",
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
                        ],
                      ),
            ),
          ),
        ),
      );
    }

    final today = Timestamp.fromMillisecondsSinceEpoch(
      Timestamp.now().millisecondsSinceEpoch -
          (Timestamp.now().millisecondsSinceEpoch % (1000 * 3600 * 24)) -
          1000 * 2600 * 12,
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isScreenWide ? 35 : 10,
        vertical: 15,
      ),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text("Termine"),
            bottom: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.access_alarm), text: "Kommend"),
                Tab(icon: Icon(Icons.more_time_outlined), text: "Vergangen"),
              ],
            ),
            actions:
                widget.isCoach ? [NewEventMenu(teamId: widget.teamId)] : [],
          ),
          body: Padding(
            padding: EdgeInsets.only(top: 10),
            child: TabBarView(
              children: [
                PaginatedList(
                  builder: builder,
                  query: FirebaseFirestore.instance
                      .collection("teams")
                      .doc(widget.teamId)
                      .collection("events"),
                  collectionKey: "teams/${widget.teamId}/events",
                  filter: (data) {
                    return data.where((doc) {
                        final data = castMap(doc.data());
                        return data["date"] != null &&
                            (data["date"] as Timestamp)
                                    .millisecondsSinceEpoch >=
                                today.millisecondsSinceEpoch;
                      }).toList()
                      ..sort((a, b) {
                        final aDate =
                            ((castMap(a.data())["date"] ?? Timestamp.now())
                                    as Timestamp)
                                .toDate();
                        final bDate =
                            ((castMap(b.data())["date"] ?? Timestamp.now())
                                    as Timestamp)
                                .toDate();
                        final aStart =
                            ((castMap(a.data())["start"] ?? Timestamp.now())
                                    as Timestamp)
                                .toDate();
                        final bStart =
                            ((castMap(b.data())["start"] ?? Timestamp.now())
                                    as Timestamp)
                                .toDate();
                        return DateTime(
                          aDate.year,
                          aDate.month,
                          aDate.day,
                          aStart.hour,
                          aStart.minute,
                        ).compareTo(
                          DateTime(
                            bDate.year,
                            bDate.month,
                            bDate.day,
                            bStart.hour,
                            bStart.minute,
                          ),
                        );
                      });
                  },
                ),
                PaginatedList(
                  builder: builder,
                  query: FirebaseFirestore.instance
                      .collection("teams")
                      .doc(widget.teamId)
                      .collection("events"),

                  collectionKey: "teams/${widget.teamId}/events",
                  filter: (data) {
                    return data.where((doc) {
                        final data = castMap(doc.data());
                        return data["date"] != null &&
                            (data["date"] as Timestamp).millisecondsSinceEpoch <
                                today.millisecondsSinceEpoch;
                      }).toList()
                      ..sort((a, b) {
                        final aDate =
                            ((castMap(a.data())["date"] ?? Timestamp.now())
                                    as Timestamp)
                                .toDate();
                        final bDate =
                            ((castMap(b.data())["date"] ?? Timestamp.now())
                                    as Timestamp)
                                .toDate();
                        final aStart =
                            ((castMap(a.data())["start"] ?? Timestamp.now())
                                    as Timestamp)
                                .toDate();
                        final bStart =
                            ((castMap(b.data())["start"] ?? Timestamp.now())
                                    as Timestamp)
                                .toDate();
                        return DateTime(
                              aDate.year,
                              aDate.month,
                              aDate.day,
                              aStart.hour,
                              aStart.minute,
                            ).compareTo(
                              DateTime(
                                bDate.year,
                                bDate.month,
                                bDate.day,
                                bStart.hour,
                                bStart.minute,
                              ),
                            ) *
                            -1;
                      });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NewEventMenu extends StatefulWidget {
  final String teamId;

  const NewEventMenu({super.key, required this.teamId});

  @override
  State<NewEventMenu> createState() => _NewEventMenuState();
}

class _NewEventMenuState extends State<NewEventMenu> {
  final FocusNode _buttonFocusNode = FocusNode(debugLabel: 'Menu Button');

  @override
  void dispose() {
    _buttonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      childFocusNode: _buttonFocusNode,
      menuChildren: <Widget>[
        MenuItemButton(
          onPressed: () {
            context.push(
              "/coach/team/${widget.teamId}/event/${generateFirestoreKey()}/createSimple",
            );
          },
          child: const Text('Einzel'),
        ),
        MenuItemButton(onPressed: () {}, child: const Text('Wiederkehrend')),
      ],
      builder: (_, MenuController controller, Widget? child) {
        return FilledButton.icon(
          focusNode: _buttonFocusNode,
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.add),
          label: Text("Neu"),
        );
      },
    );
  }
}
