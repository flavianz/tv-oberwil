import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        fit: FlexFit.loose,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: 60),
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
                      Flexible(
                        fit: FlexFit.loose,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  doc.get("name") ?? "",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                getNearbyTimeDifference(startDate) != null
                                    ? Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3,
                                      ),
                                      margin: EdgeInsetsGeometry.only(left: 10),
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
                                              isSameDay(
                                                    startDate,
                                                    DateTime.now(),
                                                  )
                                                  ? Theme.of(
                                                    context,
                                                  ).canvasColor
                                                  : null,
                                        ),
                                      ),
                                    )
                                    : SizedBox.shrink(),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  doc.get("location") ?? "",
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      VerticalDivider(width: 20),
                      Flexible(
                        fit: FlexFit.loose,
                        child: Padding(
                          padding: EdgeInsetsGeometry.symmetric(vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    "Treffen",
                                    style: TextStyle(fontSize: 12),
                                  ),
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
                      ),
                      VerticalDivider(width: 20),
                      Flexible(fit: FlexFit.loose, child: Row(children: [])),
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
