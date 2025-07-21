import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tv_oberwil/components/details_edit_page.dart';

class SimpleEventDetailsEdit extends StatelessWidget {
  final String teamId;
  final String eventId;
  final bool created;

  const SimpleEventDetailsEdit({
    super.key,
    required this.teamId,
    required this.eventId,
    this.created = false,
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
            data: false,
          ),
          DetailsEditProperty(
            "location",
            "Ort",
            DetailsEditPropertyType.text,
            data: false,
          ),
          DetailsEditProperty("date", "Datum", DetailsEditPropertyType.date),
        ],
        [
          DetailsEditProperty("meet", "Treffen", DetailsEditPropertyType.time),
          DetailsEditProperty("start", "Start", DetailsEditPropertyType.time),
          DetailsEditProperty("end", "Ende", DetailsEditPropertyType.time),
        ],
        [DetailsEditProperty("notes", "Notizen", DetailsEditPropertyType.text)],
      ],
      titleKey: "name",
      created: created,
      defaultEdit: true,
    );
  }
}
