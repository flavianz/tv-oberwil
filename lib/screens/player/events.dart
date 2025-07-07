import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:tv_oberwil/components/paginated_list.dart';

class PlayerEvents extends StatefulWidget {
  const PlayerEvents({super.key});

  @override
  State<PlayerEvents> createState() => _PlayerEventsState();
}

class _PlayerEventsState extends State<PlayerEvents> {
  @override
  Widget build(BuildContext context) {
    return PaginatedList(
      builder: (doc) {
        return Text(doc.get("name") ?? "");
      },
      collection: FirebaseFirestore.instance
          .collection("teams")
          .doc("BJKawVNV88EzhOIhOapX")
          .collection("events"),
      orderBy: "meet",
    );
  }
}
