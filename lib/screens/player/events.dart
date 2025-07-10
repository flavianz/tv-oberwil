import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isScreenWide ? 35 : 0,
        vertical: 15,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text("Termine"),
          actions: [IconButton(onPressed: () {}, icon: Icon(Icons.refresh))],
        ),
        body: PaginatedList(
          builder: (doc) {
            final meetDate = getDateTime(doc.get("meet"));
            final startDate = getDateTime(doc.get("start"));
            final endDate = getDateTime(doc.get("end"));
            final presence =
                ((((doc.data() ?? {}) as Map<String, dynamic>)["presence"] ??
                        <String, dynamic>{})
                    as Map<String, dynamic>);
            final localMemberUid = ref.read(userDataProvider).value?["member"];
            return Card.outlined(
              elevation: 1,
              child: Padding(
                padding: EdgeInsets.all(15),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ConstrainedBox(
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
                      ),
                      VerticalDivider(width: 20),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: 15),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doc.get("name") ?? "",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
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
                        ),
                      ),
                      VerticalDivider(width: 20),
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
                                Text("Treffen", style: TextStyle(fontSize: 12)),
                                Text("${meetDate.hour}:${meetDate.minute}"),
                              ],
                            ),
                            VerticalDivider(thickness: 0.5, width: 30),
                            Column(
                              children: [
                                Text("Start", style: TextStyle(fontSize: 12)),
                                Text("${startDate.hour}:${startDate.minute}"),
                              ],
                            ),
                            VerticalDivider(thickness: 0.5, width: 30),
                            Column(
                              children: [
                                Text("Ende", style: TextStyle(fontSize: 12)),
                                Text("${endDate.hour}:${endDate.minute}"),
                              ],
                            ),
                          ],
                        ),
                      ),

                      VerticalDivider(width: 20),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          spacing: 5,
                          children: [
                            FilledButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('teams')
                                    .doc(widget.teamId)
                                    .collection("events")
                                    .doc(doc.id)
                                    .update({
                                      'presence.$localMemberUid': 'p',
                                      // only this key inside the map is updated
                                    });
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    presence[localMemberUid] == "p"
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
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("Dabei"),
                                    Text(
                                      presence.values
                                          .where((value) => value == "p")
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
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('teams')
                                          .doc(widget.teamId)
                                          .collection("events")
                                          .doc(doc.id)
                                          .update({
                                            'presence.$localMemberUid': 'u',
                                            // only this key inside the map is updated
                                          });
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor:
                                          presence[localMemberUid] == "u"
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Unsicher"),
                                        Text(
                                          presence.values
                                              .where((value) => value == "u")
                                              .length
                                              .toString(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  FilledButton(
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('teams')
                                          .doc(widget.teamId)
                                          .collection("events")
                                          .doc(doc.id)
                                          .update({
                                            'presence.$localMemberUid': 'a',
                                            // only this key inside the map is updated
                                          });
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor:
                                          presence[localMemberUid] == "a"
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Abwesend"),
                                        Text(
                                          presence.values
                                              .where((value) => value == "a")
                                              .length
                                              .toString(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          collection: FirebaseFirestore.instance
              .collection("teams")
              .doc(widget.teamId)
              .collection("events"),
          orderBy: "meet",
        ),
      ),
    );
  }
}
