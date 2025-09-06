import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tv_oberwil/components/collection_list_page.dart';
import 'package:tv_oberwil/components/collection_list_widget.dart';
import 'package:tv_oberwil/firestore_providers/paginated_list_provider.dart';
import 'package:tv_oberwil/utils.dart';

class PresencePage extends ConsumerWidget {
  final String teamId;

  const PresencePage({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, ref) {
    final eventData = ref.watch(
      getCollectionProvider(
        "teams/$teamId/events",
        FirebaseFirestore.instance
            .collection("teams")
            .doc(teamId)
            .collection("events"),
      ),
    );

    if (eventData.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (eventData.hasError || !eventData.hasValue) {
      print(eventData.error);
      return Center(child: SelectableText(eventData.error.toString()));
    }

    final presenceData = {};

    for (final doc in eventData.value!) {
      final data = castMap(doc.data());
      for (final entry in castMap(data["presence"]).entries) {
        print(entry.value);
        if (!presenceData.containsKey(entry.key)) {
          presenceData[entry.key] = 0;
        }
        if (entry.value["value"] == "p") {
          print(presenceData[entry.key]);
          presenceData[entry.key] = presenceData[entry.key] + 1;
        }
      }
    }

    return CollectionListPage(
      query: FirebaseFirestore.instance
          .collection("teams")
          .doc(teamId)
          .collection("team_members"),
      title: "Präsenz",
      collectionKey: "teams/$teamId/team_members",
      searchFields: ["search_last", "search_first"],
      defaultOrderData: OrderData(
        TextDataField("search_last", "Nachname", true, 0, true),
        false,
      ),
      builder: (doc) {
        final data = castMap(doc.data());
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text("${data["first"] ?? ""} ${data["last"] ?? ""}"),
                  ),
                  Expanded(
                    child: Text(
                      "${(((presenceData[doc.id] ?? 0) as int) / eventData.value!.length * 100).ceil()} %",
                    ),
                  ),
                ],
              ),
            ),
            Divider(),
          ],
        );
      },
    );
  }
}
