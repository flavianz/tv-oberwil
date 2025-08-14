import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tv_oberwil/firestore_providers/firestore_tools.dart';

import '../../components/input_boxes.dart';
import '../../firestore_providers/basic_providers.dart';

enum PropertyTypeEnum { multiSelect }

sealed class PropertyType {
  const PropertyType();
}

class TextPropertyType extends PropertyType {
  final bool isSearchable;
  final String defaultValue;

  const TextPropertyType({this.isSearchable = false, this.defaultValue = ""});
}

class DatePropertyType extends PropertyType {
  final DateTime defaultValue;

  const DatePropertyType(this.defaultValue);
}

class TimePropertyType extends PropertyType {
  final DateTime defaultValue;

  const TimePropertyType(this.defaultValue);
}

class SelectionPropertyType extends PropertyType {
  final Map<dynamic, String> options;

  SelectionPropertyType(this.options) {
    if (!options.keys.contains("null")) {
      throw ArgumentError("Selection contained no null property");
    }
  }
}

class BoolPropertyType extends PropertyType {
  final bool defaultValue;

  const BoolPropertyType({this.defaultValue = false});
}

class DialogPropertyType extends PropertyType {
  final Dialog Function(Function) dialogBuilder;
  final String Function(dynamic) boxTextBuilder;
  final bool openDialogInNonEditMode;

  const DialogPropertyType(
    this.dialogBuilder,
    this.boxTextBuilder, {
    this.openDialogInNonEditMode = false,
  });
}

class MultiSelectPropertyType extends PropertyType {
  final Widget Function(String) optionBuilder;
  final Map<String, String> options;

  const MultiSelectPropertyType(this.optionBuilder, this.options);
}

enum DetailsTabType { details, list }

class DetailsTab {
  final Tab? tab;
  final DetailsTabType type;
  final dynamic data;

  const DetailsTab(this.tab, this.type, this.data);
}

class DetailsEditProperty {
  final String key;
  final String name;
  final PropertyType type;
  final bool readOnly;

  const DetailsEditProperty(
    this.key,
    this.name,
    this.type, {
    this.readOnly = false,
  });
}

class DetailsEditPage extends ConsumerStatefulWidget {
  final DocumentReference<Map<String, dynamic>> doc;
  final bool created;
  final List<DetailsTab> tabs;
  final String titleKey;
  final bool defaultEdit;

  const DetailsEditPage({
    super.key,
    required this.doc,
    this.created = false,
    required this.tabs,
    required this.titleKey,
    this.defaultEdit = false,
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
  List<List<DetailsEditProperty>>? properties;

  @override
  void dispose() {
    for (var property in expandedProperties) {
      if (property.type is TextPropertyType) {
        (values[property.key] as TextEditingController).dispose();
      }
    }
    super.dispose();
  }

  void resetInputs(Map<String, dynamic> data) {
    properties =
        widget.tabs
            .where((tab) => tab.type == DetailsTabType.details)
            .map((tab) => tab.data) // Iterable<List<DetailsEditProperty>>
            .expand((list) => list)
            .cast<
              List<DetailsEditProperty>
            >() // flattens to Iterable<DetailsEditProperty>
            .toList();
    expandedProperties = properties!.expand((element) => element).toList();
    for (var property in expandedProperties) {
      switch (property.type) {
        case TextPropertyType():
          {
            values[property.key] = TextEditingController();
            values[property.key]?.text =
                data[property.key] ??
                (property.type as TextPropertyType).defaultValue;
          }
        case DatePropertyType():
          values[property.key] =
              data[property.key] ??
              Timestamp.fromDate(
                (property.type as DatePropertyType).defaultValue,
              );
        case TimePropertyType():
          values[property.key] =
              data[property.key] ??
              Timestamp.fromDate(
                (property.type as TimePropertyType).defaultValue,
              );
        case SelectionPropertyType():
          values[property.key] = data[property.key];
        case MultiSelectPropertyType():
          values[property.key] = data[property.key] ?? [];
        case BoolPropertyType():
          values[property.key] =
              data[property.key] ??
              (property.type as BoolPropertyType).defaultValue;
        case DialogPropertyType():
          values[property.key] = data[property.key];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isFirstRender) {
      isEditMode = widget.created || widget.defaultEdit;
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
      resetInputs(data);
      _inputsInitialized = true;
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 35 : 0,
        vertical: 15,
      ),
      child: DefaultTabController(
        length: widget.tabs.length,
        child: Scaffold(
          appBar: AppBar(
            actionsPadding: const EdgeInsets.symmetric(horizontal: 12),
            title: Text(
              widget.created ? "Neu" : values[widget.titleKey]?.text ?? "",
            ),
            actions: [
              Row(
                spacing: 5,
                children: [
                  isEditMode
                      ? TextButton.icon(
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
                      )
                      : SizedBox.shrink(),
                  isEditMode
                      ? FilledButton.icon(
                        onPressed: () async {
                          setState(() {
                            _isSaving = true;
                          });
                          Map<String, dynamic> changedData = {};
                          final Map<String, dynamic> inputs = {};

                          for (var property in expandedProperties) {
                            switch (property.type) {
                              case TextPropertyType():
                                inputs[property.key] =
                                    values[property.key]?.text;
                                if ((property.type as TextPropertyType)
                                    .isSearchable) {
                                  inputs["search_${property.key}"] = searchify(
                                    values[property.key]?.text ?? "",
                                  );
                                }
                              case DatePropertyType():
                              case TimePropertyType():
                                inputs[property.key] =
                                    Timestamp.fromMillisecondsSinceEpoch(
                                      values[property.key]
                                          .millisecondsSinceEpoch,
                                    );
                              case SelectionPropertyType():
                              case BoolPropertyType():
                              case DialogPropertyType():
                              case MultiSelectPropertyType():
                                inputs[property.key] = values[property.key];
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
                      )
                      : SizedBox.shrink(),
                  !isEditMode
                      ? IconButton(
                        onPressed: () {
                          setState(() {
                            isEditMode = true;
                          });
                        },
                        icon: const Icon(Icons.edit),
                      )
                      : SizedBox.shrink(),
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
                                    if (!widget.created) {
                                      widget.doc.delete();
                                    }
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
            ],
            bottom:
                widget.tabs.length > 1
                    ? TabBar(
                      tabs:
                          widget.tabs
                              .map((tab) => tab.tab ?? Tab(text: "Unknown"))
                              .toList(),
                    )
                    : null,
          ),

          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TabBarView(
              children:
                  widget.tabs.map((tab) {
                    switch (tab.type) {
                      case DetailsTabType.details:
                        {
                          final personalInfoBoxes = (tab.data
                                  as List<List<DetailsEditProperty>>)
                              .map((list) {
                                return list.map((property) {
                                  switch (property.type) {
                                    case TextPropertyType():
                                      return TextInputBox(
                                        controller:
                                            values[property.key] ??
                                            TextEditingController(),
                                        title: property.name,
                                        isEditMode:
                                            property.readOnly
                                                ? false
                                                : isEditMode,
                                      );
                                    case DatePropertyType():
                                      return DateInputBox(
                                        title: property.name,
                                        onDateSelected: (s) {
                                          setState(() {
                                            values = {
                                              ...values,
                                              property.key:
                                                  Timestamp.fromMillisecondsSinceEpoch(
                                                    s.millisecondsSinceEpoch,
                                                  ),
                                            };
                                          });
                                        },
                                        defaultDate:
                                            DateTime.fromMillisecondsSinceEpoch(
                                              values[property.key]
                                                  .millisecondsSinceEpoch,
                                            ),
                                        isEditMode:
                                            property.readOnly
                                                ? false
                                                : isEditMode,
                                      );
                                    case TimePropertyType():
                                      return TimeInputBox(
                                        title: property.name,
                                        onTimeSelected: (s) {
                                          setState(() {
                                            values = {
                                              ...values,
                                              property.key:
                                                  Timestamp.fromMillisecondsSinceEpoch(
                                                    s.millisecondsSinceEpoch,
                                                  ),
                                            };
                                          });
                                        },
                                        defaultTime:
                                            DateTime.fromMillisecondsSinceEpoch(
                                              values[property.key]
                                                  .millisecondsSinceEpoch,
                                            ),
                                        isEditMode:
                                            property.readOnly
                                                ? false
                                                : isEditMode,
                                      );
                                    case SelectionPropertyType():
                                      return SelectionInputBox(
                                        title: property.name,
                                        isEditMode:
                                            property.readOnly
                                                ? false
                                                : isEditMode,
                                        options:
                                            (property.type
                                                    as SelectionPropertyType)
                                                .options,
                                        selected: values[property.key],
                                        defaultKey: "none",
                                        onSelected: (s) {
                                          setState(() {
                                            values = {
                                              ...values,
                                              property.key: s,
                                            };
                                          });
                                        },
                                      );
                                    case BoolPropertyType():
                                      return SelectionInputBox(
                                        title: property.name,
                                        isEditMode:
                                            property.readOnly
                                                ? false
                                                : isEditMode,
                                        options: {true: "Ja", false: "Nein"},
                                        selected: values[property.key],
                                        defaultKey: false,
                                        onSelected: (s) {
                                          setState(() {
                                            values = {
                                              ...values,
                                              property.key: s,
                                            };
                                          });
                                        },
                                      );
                                    case DialogPropertyType():
                                      DialogPropertyType dialogInputBoxData =
                                          property.type as DialogPropertyType;
                                      return DialogInputBox(
                                        dialogBuilder:
                                            dialogInputBoxData.dialogBuilder,
                                        isEditMode: isEditMode,
                                        boxContent: Text(
                                          dialogInputBoxData.boxTextBuilder(
                                            values[property.key],
                                          ),
                                        ),
                                        title: property.name,
                                        onUpdate: (newValue) {
                                          setState(() {
                                            values = {
                                              ...values,
                                              property.key: newValue,
                                            };
                                          });
                                        },
                                        openDialogInNonEditMode:
                                            dialogInputBoxData
                                                .openDialogInNonEditMode,
                                      );
                                    case MultiSelectPropertyType():
                                      MultiSelectPropertyType data =
                                          property.type
                                              as MultiSelectPropertyType;
                                      return MultiSelectInputBox(
                                        title: property.name,
                                        isEditMode: isEditMode,
                                        options: data.options,
                                        selected: values[property.key],
                                        onSelected: (newValue) {
                                          setState(() {
                                            values = {
                                              ...values,
                                              property.key: newValue,
                                            };
                                          });
                                        },
                                        optionBuilder: data.optionBuilder,
                                      );
                                  }
                                });
                              });
                          return ListView(
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
                                                              padding:
                                                                  EdgeInsets.only(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children:
                                        personalInfoBoxes
                                            .expand((element) => element)
                                            .toList()
                                            .map(
                                              (w) => Padding(
                                                padding: EdgeInsets.only(
                                                  bottom: 10,
                                                ),
                                                child: w,
                                              ),
                                            )
                                            .toList(),
                                  ),
                            ],
                          );
                        }
                      case DetailsTabType.list:
                        {
                          return tab.data as Widget;
                        }
                    }
                  }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
