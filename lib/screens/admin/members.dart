import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tv_oberwil/components/misc.dart';
import 'package:tv_oberwil/components/paginated_list_page.dart';

import '../../utils.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PaginatedListPage(
      query: FirebaseFirestore.instance.collection("members"),
      collectionKey: "members",
      searchFields: ["search_last", "search_first", "search_middle"],
      title: "Mitglieder",
      filters: [
        BoolFilter(
          "user",
          "Ist verknüpft",
          Icons.link,
          filterApplyFunction:
              (filterValue, dataValue) =>
                  filterValue ? dataValue != null : dataValue == null,
        ),
        DateFilter(
          "birthdate",
          "Geburtsdatum",
          Icons.cake_outlined,
          DateTime(1900),
          DateTime(2100),
        ),
      ],
      tableOptions: TableOptions(
        [
          TableColumn(
            "last",
            "Nachname",
            (data) {
              return Text(data);
            },
            2,
            OrderPropertyType.text,
          ),
          TableColumn(
            "first",
            "Vorname",
            (data) {
              return Text(data);
            },
            2,
            OrderPropertyType.text,
          ),
          TableColumn(
            "birthdate",
            "Geburtstdatum",
            (data) {
              final date = DateTime.fromMillisecondsSinceEpoch(
                (data as Timestamp).millisecondsSinceEpoch,
              );
              return Text("${date.day}. ${date.month}. ${date.year}");
            },
            2,
            OrderPropertyType.date,
          ),
          TableColumn(
            "user",
            "Ist verknüpft",
            (data) {
              return getBoolPill(data != null);
            },
            1,
            OrderPropertyType.text,
          ),
        ],
        (doc) {
          context.push("/admin/member/${doc.id}");
        },
      ),
      actions: [
        FilledButton.icon(
          onPressed: () {
            context.push("/admin/member/${generateFirestoreKey()}?create=true");
          },
          icon: Icon(Icons.add),
          label: Text("Neu"),
        ),
      ],
      defaultOrderData: OrderData(OrderPropertyType.text, "search_last", false),
    );
  }
}
