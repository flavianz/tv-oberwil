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
      tabs: [
        DetailsTab(null, DetailsTabType.details, [
          [
            DetailsEditProperty(
              "name",
              "Name",
              TextPropertyType(isSearchable: false),
            ),
            DetailsEditProperty(
              "location",
              "Ort",
              TextPropertyType(isSearchable: false),
            ),
            DetailsEditProperty(
              "date",
              "Datum",
              DatePropertyType(DateTime.now()),
            ),
          ],
          [
            DetailsEditProperty(
              "meet",
              "Treffen",
              TimePropertyType(DateTime.now()),
            ),
            DetailsEditProperty(
              "start",
              "Start",
              TimePropertyType(DateTime.now()),
            ),
            DetailsEditProperty(
              "end",
              "Ende",
              TimePropertyType(DateTime.now()),
            ),
          ],
          [DetailsEditProperty("notes", "Notizen", TextPropertyType())],
        ]),
      ],
      titleKey: "name",
      created: created,
      defaultEdit: true,
    );
  }
}
