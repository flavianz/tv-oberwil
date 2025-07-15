import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tv_oberwil/components/paginated_list.dart';
import 'package:tv_oberwil/utils.dart';

import '../../components/app.dart';
import '../../firestore_providers/basic_providers.dart';

class PlayerEventDetails extends ConsumerWidget {
  final String teamId;
  final String eventId;

  const PlayerEventDetails({
    super.key,
    required this.teamId,
    required this.eventId,
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
    final eventData = castMap(eventDoc.value?.data());

    final meetDate = getDateTime(eventData["meet"] ?? Timestamp.now());
    final startDate = getDateTime(eventData["start"] ?? Timestamp.now());
    final endDate = getDateTime(eventData["end"] ?? Timestamp.now());

    final localMemberUid = ref.read(userDataProvider).value?["member"];
    final presence = castMap(eventData["presence"]);

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
                Text(eventData["name"] ?? ""),
                getNearbyTimeDifference(startDate) != null
                    ? Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      margin: EdgeInsets.only(left: 10),
                      decoration: BoxDecoration(
                        color:
                            isSameDay(startDate, DateTime.now())
                                ? Theme.of(context).primaryColor
                                : Theme.of(
                                  context,
                                ).colorScheme.secondaryFixedDim,
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
            bottom: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.info_outline), text: "Infos"),
                Tab(icon: Icon(Icons.people_alt), text: "Teilnehmer"),
                /*Tab(icon: Icon(Icons.directions_car), text: "Mitfahren"),*/
              ],
            ),
            actions: [IconButton(onPressed: () {}, icon: Icon(Icons.refresh))],
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
                          Text(eventData["location"] ?? "Keine Ortsangabe"),
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
                                onPressed: () async {
                                  if (meetDate.isBefore(DateTime.now())) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Du bist zu spät!'),
                                      ),
                                    );
                                    return;
                                  }
                                  await FirebaseFirestore.instance
                                      .collection('teams')
                                      .doc(teamId)
                                      .collection("events")
                                      .doc(eventId)
                                      .update({
                                        'presence.$localMemberUid': {
                                          "value": 'p',
                                          "reason": "",
                                        },
                                        // only this key inside the map is updated
                                      });
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Du bist angemeldet!'),
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
                                  if (meetDate.isBefore(DateTime.now())) {
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                                          .doc(teamId)
                                          .collection("events")
                                          .doc(eventId)
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
                                onPressed: () {
                                  if (meetDate.isBefore(DateTime.now())) {
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                                          .doc(teamId)
                                          .collection("events")
                                          .doc(eventId)
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
                              eventData["notes"] ?? "",
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
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 5,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${playerData["first"] ?? ""} ${playerData["last"] ?? ""}",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ((presence[doc.id]?["reason"] ?? "") as String)
                                      .isNotEmpty
                                  ? Text(presence[doc.id]?["reason"] ?? "")
                                  : SizedBox.shrink(),
                            ],
                          ),
                          Container(
                            height: 15,
                            width: 15,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(
                                Radius.circular(15),
                              ),
                              color:
                                  presence[doc.id]?["value"] == "p"
                                      ? Colors.green
                                      : (presence[doc.id]?["value"] == "u"
                                          ? Colors.amber
                                          : (presence[doc.id]?["value"] == "a"
                                              ? Colors.redAccent
                                              : Colors.grey)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  query: FirebaseFirestore.instance
                      .collection("members")
                      .where("roles.player", arrayContains: teamId),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
