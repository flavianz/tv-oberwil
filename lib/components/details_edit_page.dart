import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tv_oberwil/firestore_providers/firestore_tools.dart';

import '../../components/input_boxes.dart';
import '../../firestore_providers/basic_providers.dart';

enum DetailsEditPropertyType { text, date, selection, bool }

class DetailsEditProperty {
  final String key;
  final String name;
  final DetailsEditPropertyType type;
  final dynamic data;

  const DetailsEditProperty(this.key, this.name, this.type, {this.data});
}

class DetailsEditPage extends ConsumerStatefulWidget {
  final DocumentReference<Map<String, dynamic>> doc;
  final bool created;
  final List<List<DetailsEditProperty>> properties;
  final String titleKey;

  const DetailsEditPage({
    super.key,
    required this.doc,
    this.created = false,
    required this.properties,
    required this.titleKey,
  });

  @override
  ConsumerState<DetailsEditPage> createState() => _DetailsEditPageState();
}

class _DetailsEditPageState extends ConsumerState<DetailsEditPage> {
  Map<String, dynamic> values = {};
  List<DetailsEditProperty> expandedProperties = [];

  bool isEditMode = false;
  bool _inputsInitialized = false;
  bool _isSaving = false;
  bool isFirstRender = true;

  @override
  void dispose() {
    for (var property in expandedProperties) {
      if (property.type == DetailsEditPropertyType.text) {
        (values[property.key] as TextEditingController).dispose();
      }
    }
    super.dispose();
  }

  void resetInputs(Map<String, dynamic> data) {
    expandedProperties =
        widget.properties.expand((element) => element).toList();
    for (var property in expandedProperties) {
      if (property.type == DetailsEditPropertyType.text) {
        values[property.key] = TextEditingController();
        values[property.key]?.text = data[property.key] ?? "";
      } else if (property.type == DetailsEditPropertyType.selection) {
        values[property.key] = data[property.key] ?? property.data?.keys[0];
      } else if (property.type == DetailsEditPropertyType.bool) {
        values[property.key] = data[property.key] ?? true;
      } else if (property.type == DetailsEditPropertyType.date) {
        values[property.key] = data[property.key] ?? Timestamp.now();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isFirstRender) {
      isEditMode = widget.created;
      isFirstRender = false;
    }

    final isTablet = MediaQuery.of(context).size.aspectRatio > 1;
    final teamData = ref.watch(realtimeDocProvider(widget.doc));

    if (teamData.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (teamData.hasError) {
      return const Center(child: Text("An error occurred loading your data"));
    }

    final data = teamData.value?.data() ?? {};

    if (!teamData.isLoading && teamData.value != null && !_inputsInitialized) {
      final data = teamData.value!.data();
      if (data != null) {
        resetInputs(data);
        _inputsInitialized = true;
      }
    }

    final personalInfoBoxes = widget.properties.map((list) {
      return list.map((property) {
        if (property.type == DetailsEditPropertyType.text) {
          return TextInputBox(
            controller: values[property.key],
            title: property.name,
            isEditMode: isEditMode,
          );
        } else if (property.type == DetailsEditPropertyType.selection) {
          values[property.key] = data[property.key] ?? property.data?.keys[0];
          return SelectionInputBox(
            title: property.name,
            isEditMode: isEditMode,
            options: property.data,
            selected: values[property.key],
            onSelected: (s) {
              setState(() {
                values = {...values, property.key: s};
              });
            },
          );
        } else if (property.type == DetailsEditPropertyType.bool) {
          return SelectionInputBox(
            title: property.name,
            isEditMode: isEditMode,
            options: {true: "Ja", false: "Nein"},
            selected: values[property.key],
            onSelected: (s) {
              setState(() {
                values = {...values, property.key: s};
              });
            },
          );
        } else if (property.type == DetailsEditPropertyType.date) {
          values[property.key] = data[property.key] ?? Timestamp.now();
          return DateInputBox(
            title: property.name,
            onDateSelected: (s) {
              setState(() {
                values = {...values, property.key: s};
              });
            },
            defaultDate: values[property.key],
            isEditMode: isEditMode,
          );
        }
      });
    });

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 35 : 0,
        vertical: 15,
      ),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            actionsPadding: const EdgeInsets.symmetric(horizontal: 12),
            title: Text(values[widget.titleKey].text),
            actions: [
              (isEditMode
                  ? Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            resetInputs(data);
                            isEditMode = false;
                            _inputsInitialized = true;
                            if (widget.created) {
                              context.pop();
                            }
                          });
                        },
                        label: Text("Abbrechen"),
                        icon: Icon(Icons.close),
                      ),
                      FilledButton.icon(
                        onPressed: () async {
                          setState(() {
                            _isSaving = true;
                          });
                          Map<String, dynamic> changedData = {};
                          final Map<String, dynamic> inputs = {};

                          for (var property in expandedProperties) {
                            if (property.type == DetailsEditPropertyType.text) {
                              inputs[property.key] = values[property.key]?.text;
                              if (property.data == true) {
                                inputs["search_${property.key}"] = searchify(
                                  values[property.key]?.text,
                                );
                              }
                            } else if (property.type ==
                                    DetailsEditPropertyType.selection ||
                                property.type == DetailsEditPropertyType.bool) {
                              inputs[property.key] = values[property.key];
                            } else if (property.type ==
                                DetailsEditPropertyType.date) {
                              inputs[property
                                  .key] = Timestamp.fromMillisecondsSinceEpoch(
                                values[property.key].millisecondsSinceEpoch,
                              );
                            }
                          }

                          if (widget.created) {
                            widget.doc.set(inputs).whenComplete(() {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Erstellt!')),
                                );
                              }
                            });
                          } else {
                            for (final entry in inputs.entries) {
                              if (data[entry.key] != entry.value) {
                                changedData[entry.key] = entry.value;
                              }
                            }
                            if (changedData.isNotEmpty) {
                              await widget.doc.update(changedData).whenComplete(
                                () {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Aktualisiert!')),
                                    );
                                  }
                                },
                              );
                            }
                          }

                          setState(() {
                            _isSaving = false;
                            isEditMode = false;
                            if (widget.created) {
                              context.pop();
                            }
                          });
                        },
                        label: Text("Speichern"),
                        icon:
                            _isSaving
                                ? Transform.scale(
                                  scale: 0.5,
                                  child: CircularProgressIndicator(
                                    color: Theme.of(context).canvasColor,
                                  ),
                                )
                                : Icon(Icons.check),
                      ),
                    ],
                  )
                  : IconButton(
                    onPressed: () {
                      setState(() {
                        isEditMode = true;
                      });
                    },
                    icon: const Icon(Icons.edit),
                  )),
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Löschen?'),
                          content: const SingleChildScrollView(
                            child: ListBody(
                              children: [
                                Text(
                                  'Das Löschen kann nicht rückgängig gemacht werden.',
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => context.pop(),
                              child: const Text("Abbrechen"),
                            ),
                            FilledButton.icon(
                              onPressed: () {
                                widget.doc.delete();
                                context.pop();
                                context.pop();
                              },
                              label: const Text("Löschen"),
                              icon: const Icon(Icons.delete),
                            ),
                          ],
                        ),
                  );
                },
                icon: const Icon(Icons.delete),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: ListView(
              children: [
                const SizedBox(height: 30),
                isTablet
                    ? Column(
                      children:
                          personalInfoBoxes
                              .map(
                                (row) => Row(
                                  children:
                                      row
                                          .toList()
                                          .map(
                                            (w) => Expanded(
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                  right: 15,
                                                ),
                                                child: w,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                ),
                              )
                              .toList(),
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children:
                          personalInfoBoxes
                              .expand((element) => element)
                              .toList()
                              .map(
                                (w) => Padding(
                                  padding: EdgeInsets.only(bottom: 10),
                                  child: w,
                                ),
                              )
                              .toList(),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
