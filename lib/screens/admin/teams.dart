import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tv_oberwil/components/paginated_list_page.dart';

class TeamsScreen extends StatelessWidget {
  final bool refresh;

  const TeamsScreen({super.key, this.refresh = false});

  @override
  Widget build(BuildContext context) {
    return PaginatedListPage(
      query: FirebaseFirestore.instance.collection("teams"),
      title: "Teams",
      searchFields: ["search_name"],
      tableOptions: TableOptions(
        [
          TableColumn("name", "Name", (data) {
            return Text(data ?? "");
          }, 1),
          TableColumn("sport_type", "Sportart", (data) {
            return Text(data ?? "");
          }, 1),
          TableColumn("plays_in_league", "Spielt in Liga", (data) {
            return Text(data == true ? "Ja" : "Nein");
          }, 1),
          TableColumn("genders", "Geschlecht", (data) {
            return Text(data ?? "");
          }, 1),
        ],
        (doc) {
          context.push("/admin/team/${doc.id}");
        },
      ),
    );
  }
}
