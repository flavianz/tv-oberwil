import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tv_oberwil/components/app.dart';
import 'package:tv_oberwil/components/paginated_list.dart';

import '../../utils.dart';

class PlayerEvents extends ConsumerStatefulWidget {
  final String teamId;

  const PlayerEvents({super.key, required this.teamId});

  @override
  ConsumerState<PlayerEvents> createState() => _PlayerEventsState();
}

class _PlayerEventsState extends ConsumerState<PlayerEvents> {
  @override
  Widget build(BuildContext context) {
    final isScreenWide = MediaQuery.of(context).size.aspectRatio > 1;

    builder(DocumentSnapshot<Object?> doc) {
      final meetDate = getDateTime(doc.get("meet"));
      final startDate = getDateTime(doc.get("start"));
      final endDate = getDateTime(doc.get("end"));
      final presence = castMap(castMap(doc.data())["presence"]);
      final localMemberUid = ref.read(userDataProvider).value?["member"];

      final dateBox = ConstrainedBox(
        constraints: BoxConstraints(minWidth: 80),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                getWeekday(startDate.weekday),
                style: TextStyle(fontSize: 12),
              ),
              Text(
                "${startDate.day}.${startDate.month}.",
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
                    doc.get("name") ?? "",
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),

                  Text(
                    doc.get("location") ?? "",
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            getNearbyTimeDifference(startDate) != null
                ? Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  margin: EdgeInsets.only(left: 10),
                  decoration: BoxDecoration(
                    color:
                        isSameDay(startDate, DateTime.now())
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).colorScheme.secondaryFixedDim,
                    borderRadius: BorderRadius.circular(
                      10,
                    ), // Makes it pill-shaped
                  ),
                  child: Text(
                    getNearbyTimeDifference(startDate)!,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isSameDay(startDate, DateTime.now())
                              ? Theme.of(context).canvasColor
                              : null,
                    ),
                  ),
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

      final voteBox = Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 5,
          children: [
            FilledButton(
              onPressed: () async {
                if (meetDate.isBefore(DateTime.now())) {
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
            IntrinsicWidth(
              child: Column(
                spacing: 5,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: () {
                      if (meetDate.isBefore(DateTime.now())) {
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
                      if (meetDate.isBefore(DateTime.now())) {
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
            ),
          ],
        ),
      );

      final bool isWideEnough = MediaQuery.of(context).size.width > 1200;

      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            context.push("/player/team/${widget.teamId}/event/${doc.id}");
          },
          child: Card.outlined(
            elevation: 1,
            child: Padding(
              padding: EdgeInsets.all(15),
              child:
                  isWideEnough
                      ? IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            dateBox,
                            VerticalDivider(width: 20),
                            Expanded(child: nameBox),
                            VerticalDivider(width: 20),
                            timesBox,
                            VerticalDivider(width: 20),
                            voteBox,
                          ],
                        ),
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
                          Divider(height: 40),
                          IntrinsicHeight(child: timesBox),
                          Divider(height: 40),
                          IntrinsicHeight(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 5,
                              children: [
                                Flexible(
                                  fit: FlexFit.loose,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: FilledButton(
                                      onPressed: () async {
                                        if (meetDate.isBefore(DateTime.now())) {
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
                                                        castMap(
                                                          value,
                                                        )["value"] ==
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
                                        if (meetDate.isBefore(DateTime.now())) {
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
                                        if (meetDate.isBefore(DateTime.now())) {
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
                          ),
                        ],
                      ),
            ),
          ),
        ),
      );
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
            title: Text("Termine"),
            bottom: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.access_alarm), text: "Kommend"),
                Tab(icon: Icon(Icons.more_time_outlined), text: "Vergangen"),
              ],
            ),
            actions: [IconButton(onPressed: () {}, icon: Icon(Icons.refresh))],
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
                      .collection("events")
                      .where("end", isGreaterThanOrEqualTo: Timestamp.now())
                      .orderBy("end"),
                  maxQueryLimit: 5,
                ),
                PaginatedList(
                  builder: builder,
                  query: FirebaseFirestore.instance
                      .collection("teams")
                      .doc(widget.teamId)
                      .collection("events")
                      .where("end", isLessThan: Timestamp.now())
                      .orderBy("end"),
                  maxQueryLimit: 5,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
