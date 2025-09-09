import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tv_oberwil/utils.dart';

import '../../components/collection_list_widget.dart';
import '../../firestore_providers/paginated_list_provider.dart';

class MemberSettingsPage extends ConsumerStatefulWidget {
  const MemberSettingsPage({super.key});

  @override
  ConsumerState<MemberSettingsPage> createState() => _MemberSettingsPageState();
}

class _MemberSettingsPageState extends ConsumerState<MemberSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final isScreenWide = MediaQuery.of(context).size.aspectRatio > 1;

    final docModelDoc = ref.watch(
      docFromLiveCollectionProvider((
        "members",
        FirebaseFirestore.instance.collection("members").doc("model"),
      )),
    );

    if (docModelDoc.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (docModelDoc.hasError || !docModelDoc.hasValue) {
      return Center(child: Text(docModelDoc.error.toString()));
    }

    final docModel = DocModel.fromMap(castMap(docModelDoc.value!.data()));

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isScreenWide ? 35 : 0,
        vertical: 15,
      ),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text("Mitglieder-Einstellungen"),
            bottom: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.settings), text: "Allgemein"),
                Tab(icon: Icon(Icons.text_fields), text: "Felder"),
              ],
            ),
            actionsPadding: EdgeInsets.symmetric(horizontal: 12),
          ),
          body: Padding(
            padding: EdgeInsets.all(12),
            child: TabBarView(
              children: [
                Center(child: Text("Allgemein")),
                Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Alle Mitglied-Felder",
                            style: TextStyle(fontSize: 18),
                          ),
                          FilledButton.icon(
                            onPressed: () {},
                            label: Text("Neues Feld"),
                            icon: Icon(Icons.add),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: Theme.of(context).primaryColor),
                    Expanded(
                      child: ListView(
                        children: () {
                          final fields = [...docModel.fields.values];
                          fields.sort((a, b) {
                            if (a.required != b.required) {
                              return a.required ? 1 : -1;
                            }
                            return a.type().compareTo(b.type());
                          });
                          return fields
                              .map(
                                (field) => Column(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 3,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                field.required
                                                    ? Tooltip(
                                                      message:
                                                          "Dieses Feld ist systemrelevant und kann nicht geändert werden",
                                                      child: Icon(
                                                        Icons.lock,
                                                        size: 20,
                                                      ),
                                                    )
                                                    : SizedBox.shrink(),
                                                SizedBox(
                                                  width:
                                                      field.required ? 15 : 0,
                                                ),
                                                Text(field.name),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(switch (field) {
                                              TextDataField() => "Text",
                                              BoolDataField() => "Ja / Nein",
                                              DateDataField() => "Datum",
                                              TimeDataField() => "Uhrzeit",
                                              SelectionDataField() => "Auswahl",
                                              MultiSelectDataField() =>
                                                "Mehrfachauswahl",
                                            }),
                                          ),
                                          IconButton(
                                            tooltip:
                                                field.required
                                                    ? "Bearbeiten nicht möglich"
                                                    : "Bearbeiten",
                                            onPressed:
                                                field.required ? null : () {},
                                            icon: Icon(Icons.edit),
                                          ),
                                          IconButton(
                                            tooltip:
                                                field.required
                                                    ? "Löschen nicht möglich"
                                                    : "Löschen",
                                            onPressed:
                                                field.required ? null : () {},
                                            icon: Icon(Icons.delete),
                                          ),
                                          /*Expanded(
                                            child: TextInputBox(
                                              controller: TextEditingController(
                                                text: field.name,
                                              ),
                                              title: "Titel",
                                              isEditMode: true,
                                            ),
                                          ),
                                          Expanded(
                                            child: SelectionInputBox(
                                              title: "Feldart",
                                              isEditMode: true,
                                              options: {
                                                "text": "Text",
                                                "bool": "Ja/Nein",
                                                "date": "Datum",
                                                "time": "Uhrzeit",
                                                "selection": "Auswahl",
                                                "multi": "Mehrfach-Auswahl",
                                              },
                                              selected: field.type(),
                                              onSelected: (_) {},
                                              defaultKey: "text",
                                            ),
                                          ),*/
                                        ],
                                      ),
                                    ),
                                    Divider(),
                                  ],
                                ),
                              )
                              .toList();
                        }(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
