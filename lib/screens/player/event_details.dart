import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tv_oberwil/utils.dart';

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

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isScreenWide ? 35 : 0,
        vertical: 15,
      ),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text(eventData["name"] ?? ""),
            bottom: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.info_outline), text: "Infos"),
                Tab(icon: Icon(Icons.people_alt), text: "Teilnehmer"),
                Tab(icon: Icon(Icons.directions_car), text: "Mitfahren"),
              ],
            ),
            actions: [IconButton(onPressed: () {}, icon: Icon(Icons.refresh))],
          ),
          body: Padding(
            padding: EdgeInsets.only(top: 10),
            child: TabBarView(children: [Center(), Center(), Center()]),
          ),
        ),
      ),
    );
  }
}
