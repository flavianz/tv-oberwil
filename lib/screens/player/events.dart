import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:tv_oberwil/components/paginated_list.dart';

import '../../utils.dart';

class PlayerEvents extends StatefulWidget {
  const PlayerEvents({super.key});

  @override
  State<PlayerEvents> createState() => _PlayerEventsState();
}

class _PlayerEventsState extends State<PlayerEvents> {
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
            return Card.outlined(
              elevation: 1,
              child: Padding(
                padding: EdgeInsets.all(15),
                child: IntrinsicHeight(
                  child: Row(
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
                              onPressed: () {},
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green,
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
                                      "10",
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
                                    onPressed: () {},
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.amber,
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
                                          "10",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  FilledButton(
                                    onPressed: () {},
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
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
                                          "17",
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
              .doc("BJKawVNV88EzhOIhOapX")
              .collection("events"),
          orderBy: "meet",
        ),
      ),
    );
  }
}
