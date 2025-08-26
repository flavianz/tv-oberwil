import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tv_oberwil/components/misc.dart';
import 'package:tv_oberwil/components/paginated_list_page.dart';
import 'package:tv_oberwil/utils.dart';

class TeamsScreen extends StatelessWidget {
  final bool refresh;

  const TeamsScreen({super.key, this.refresh = false});

  @override
  Widget build(BuildContext context) {
    return PaginatedListPage(
      query: FirebaseFirestore.instance.collection("teams"),
      collectionKey: "teams",
      title: "Teams",
      searchFields: ["search_name"],
      tableOptions: TableOptions(
        [
          TableColumn(
            "name",
            "Name",
            (data) {
              return Text(data ?? "");
            },
            1,
            OrderPropertyType.text,
          ),
          TableColumn(
            "sport_type",
            "Sportart",
            (data) {
              return Text(switch (data) {
                "floorball" => "Unihockey",
                "volleyball" => "Volleyball",
                "riege" => "Riege",
                _ => "Keine Angabe",
              });
            },
            1,
            OrderPropertyType.text,
          ),
          TableColumn(
            "plays_in_league",
            "Spielt in Liga",
            (data) {
              return getBoolPill(data);
            },
            1,
            OrderPropertyType.bool,
          ),
          TableColumn(
            "genders",
            "Geschlecht",
            (data) {
              return getGenderPill(data);
            },
            1,
            OrderPropertyType.text,
          ),
        ],
        (doc) {
          context.push("/admin/team/${doc.id}");
        },
      ),
      filters: [
        BoolFilter(
          "plays_in_league",
          "Spielt in Liga",
          Icons.format_list_numbered,
        ),
        ChipFilter("sport_type", "Sportart", Icons.sports, {
          "floorball": "Unihockey",
          "volleyball": "Volleyball",
          "riege": "Riege",
          "null": "Keine Angabe",
        }),
        ChipFilter("genders", "Geschlecht", Icons.transgender, {
          "women": "Damen",
          "men": "Herren",
          "mixed": "Gemischt",
          "null": "Keine Angabe",
        }),
      ],
      actions: [
        FilledButton.icon(
          onPressed:
              () => context.push("./../team/${generateFirestoreKey()}/create"),
          label: Text("Neu"),
          icon: Icon(Icons.add),
        ),
      ],
      defaultOrderData: OrderData(OrderPropertyType.text, "first", false),
    );
  }
}
