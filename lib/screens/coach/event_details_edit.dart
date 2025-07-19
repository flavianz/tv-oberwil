import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tv_oberwil/components/details_edit_page.dart';

class EventDetailsEdit extends StatelessWidget {
  final String teamId;
  final String eventId;

  const EventDetailsEdit({
    super.key,
    required this.teamId,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return DetailsEditPage(
      doc: FirebaseFirestore.instance
          .collection("teams")
          .doc(teamId)
          .collection("events")
          .doc(eventId),
      properties: [
        [
          DetailsEditProperty(
            "name",
            "Name",
            DetailsEditPropertyType.text,
            data: true,
          ),
        ],
      ],
      titleKey: "name",
    );
  }
}
