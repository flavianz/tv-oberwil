import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tv_oberwil/components/input_boxes.dart';
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
      child: Scaffold(
        appBar: AppBar(title: Text("Mitglieder-Einstellungen")),
        body: ListView(
          children:
              docModel.fields.values
                  .map(
                    (field) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 5),
                      child: Column(
                        children: [
                          Row(
                            spacing: 8,
                            children: [
                              Expanded(
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
                                  selected: switch (field) {
                                    TextDataField() => "text",
                                    BoolDataField() => "bool",
                                    DateDataField() => "date",
                                    TimeDataField() => "time",
                                    SelectionDataField() => "time",
                                    MultiSelectDataField() => "multi",
                                  },
                                  onSelected: (_) {},
                                  defaultKey: "text",
                                ),
                              ),
                            ],
                          ),
                          Divider(),
                        ],
                      ),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}
