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
                    children: [
                      Column(
                        children: [
                          Text(
                            getWeekday(startDate.weekday),
                            style: TextStyle(fontSize: 12),
                          ),
                          Text(
                            "${startDate.day}.${startDate.month}.",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      VerticalDivider(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.get("name") ?? "",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            getTimeDistance(startDate),
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
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
