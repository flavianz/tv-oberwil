import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tv_oberwil/firestore_providers/firestore_tools.dart';
import 'package:tv_oberwil/utils.dart';

import '../../components/input_boxes.dart';
import '../firestore_providers/paginated_list_provider.dart';
import 'collection_list_widget.dart';

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

sealed class TabType {
  final Tab? tab;

  TabType(this.tab);
}

class DetailsTabType extends TabType {
  final List<List<DataField>> customFields;

  DetailsTabType(super.tab, this.customFields);
}

class CustomTabType extends TabType {
  final Widget widget;

  CustomTabType(super.tab, this.widget);
}

class CustomDetailsTabType extends TabType {
  final Widget Function(DocumentSnapshot<Object?>) builder;

  CustomDetailsTabType(super.tab, this.builder);
}

class DetailsEditPage extends ConsumerStatefulWidget {
  final DocumentReference<Map<String, dynamic>> doc;
  final bool created;
  final List<TabType> tabs;
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

  bool isEditMode = false;
  bool _inputsInitialized = false;
  bool _isSaving = false;
  bool isFirstRender = true;
  List<List<DataField>>? fields;
  DocModel? docModel;

  @override
  void dispose() {
    for (var property in docModel == null ? [] : docModel!.fields.values) {
      if (property is TextDataField) {
        (values[property.key] as TextEditingController).dispose();
      }
    }
    super.dispose();
  }

  void resetInputs(Map<String, dynamic> data) {
    assert(docModel != null, "no doc model when resetting inputs");
    fields = [];
    for (final field in docModel!.fields.values) {
      while (fields!.length < field.row + 1) {
        fields!.add([]);
      }
      fields![field.row].add(field);
    }
    for (var field in docModel!.fields.values) {
      switch (field) {
        case TextDataField():
          {
            values[field.key] = TextEditingController();
            values[field.key]?.text = data[field.key] ?? "";
          }
        case DateDataField():
          values[field.key] = data[field.key] ?? field.minDate;
        case TimeDataField():
          values[field.key] =
              data[field.key] ?? Timestamp.fromDate(DateTime(2000));
        case SelectionDataField():
          values[field.key] = data[field.key];
        case MultiSelectDataField():
          values[field.key] = data[field.key] ?? [];
        case BoolDataField():
          values[field.key] = data[field.key] ?? false;
        case DialogPropertyType():
          values[field.key] = data[field.key];
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
    final teamData = ref.watch(
      docFromLiveCollectionProvider((widget.doc.parent.path, widget.doc)),
    );
    final docModelData = ref.watch(
      docFromLiveCollectionProvider((
        widget.doc.parent.path,
        widget.doc.parent.doc("model"),
      )),
    );

    if (teamData.hasError || docModelData.hasError) {
      return const Center(child: Text("An error occurred loading your data"));
    }

    if (teamData.isLoading || docModelData.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final data = teamData.value?.data() ?? {};
    docModel = DocModel.fromMap(castMap(docModelData.value!.data()));

    if (teamData.value != null && !_inputsInitialized) {
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

                          for (var filter
                              in (docModel == null
                                  ? []
                                  : docModel!.fields.values)) {
                            switch (filter) {
                              case TextDataField():
                                inputs[filter.key] = values[filter.key]?.text;
                                print(inputs[filter.key]);
                                if (filter.isSearchable) {
                                  inputs["search_${filter.key}"] = searchify(
                                    values[filter.key]?.text ?? "",
                                  );
                                }
                              case TimeDataField():
                                inputs[filter.key] =
                                    Timestamp.fromMillisecondsSinceEpoch(
                                      values[filter.key].millisecondsSinceEpoch,
                                    );
                              case DateDataField():
                                inputs[filter.key] =
                                    Timestamp.fromMillisecondsSinceEpoch(
                                      values[filter.key].millisecondsSinceEpoch,
                                    );
                              case SelectionDataField():
                                inputs[filter.key] = values[filter.key];
                              case BoolDataField():
                                inputs[filter.key] = values[filter.key];
                              case DialogPropertyType():
                                //TODO: implement
                                throw UnimplementedError();
                              case MultiSelectDataField():
                                inputs[filter.key] = values[filter.key];
                            }
                          }

                          if (widget.created) {
                            widget.doc
                                .set({
                                  ...inputs,
                                  "lU": FieldValue.serverTimestamp(),
                                })
                                .whenComplete(() {
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
                              await widget.doc
                                  .update({
                                    ...changedData,
                                    "lU": FieldValue.serverTimestamp(),
                                  })
                                  .whenComplete(() {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Aktualisiert!'),
                                        ),
                                      );
                                    }
                                  });
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
                    switch (tab) {
                      case DetailsTabType():
                        {
                          final personalInfoBoxes = fields!.map((list) {
                            return list.map((field) {
                              switch (field) {
                                case TextDataField():
                                  return TextInputBox(
                                    controller:
                                        values[field.key] ??
                                        TextEditingController(),
                                    title: field.name,
                                    isEditMode: isEditMode,
                                  );
                                case DateDataField():
                                  return DateInputBox(
                                    title: field.name,
                                    onDateSelected: (s) {
                                      setState(() {
                                        values = {
                                          ...values,
                                          field.key:
                                              Timestamp.fromMillisecondsSinceEpoch(
                                                s.millisecondsSinceEpoch,
                                              ),
                                        };
                                      });
                                    },
                                    defaultDate:
                                        DateTime.fromMillisecondsSinceEpoch(
                                          values[field.key]
                                              .millisecondsSinceEpoch,
                                        ),
                                    isEditMode: isEditMode,
                                  );
                                case TimeDataField():
                                  return TimeInputBox(
                                    title: field.name,
                                    onTimeSelected: (s) {
                                      setState(() {
                                        values = {
                                          ...values,
                                          field.key:
                                              Timestamp.fromMillisecondsSinceEpoch(
                                                s.millisecondsSinceEpoch,
                                              ),
                                        };
                                      });
                                    },
                                    defaultTime:
                                        DateTime.fromMillisecondsSinceEpoch(
                                          values[field.key]
                                              .millisecondsSinceEpoch,
                                        ),
                                    isEditMode: isEditMode,
                                  );
                                case SelectionDataField():
                                  return SelectionInputBox(
                                    title: field.name,
                                    isEditMode: isEditMode,
                                    options: field.options,
                                    selected: values[field.key],
                                    defaultKey: "none",
                                    onSelected: (s) {
                                      setState(() {
                                        values = {...values, field.key: s};
                                      });
                                    },
                                  );
                                case BoolDataField():
                                  return BoolInputBox(
                                    title: field.name,
                                    isEditMode: isEditMode,
                                    selected: values[field.key],
                                    defaultValue: false,
                                    onSelected: (s) {
                                      setState(() {
                                        values = {...values, field.key: s};
                                      });
                                    },
                                  );
                                case DialogPropertyType():
                                  DialogPropertyType dialogInputBoxData =
                                      field as DialogPropertyType;
                                  return DialogInputBox(
                                    dialogBuilder:
                                        dialogInputBoxData.dialogBuilder,
                                    isEditMode: isEditMode,
                                    boxContent: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        dialogInputBoxData.boxTextBuilder(
                                          values[field.key],
                                        ),
                                      ),
                                    ),
                                    title: field.name,
                                    onUpdate: (newValue) {
                                      setState(() {
                                        values = {
                                          ...values,
                                          field.key: newValue,
                                        };
                                      });
                                    },
                                    openDialogInNonEditMode:
                                        dialogInputBoxData
                                            .openDialogInNonEditMode,
                                  );
                                case MultiSelectDataField():
                                  return MultiSelectInputBox(
                                    title: field.name,
                                    isEditMode: isEditMode,
                                    options: field.options,
                                    selected: values[field.key],
                                    onSelected: (newValue) {
                                      setState(() {
                                        values = {
                                          ...values,
                                          field.key: newValue,
                                        };
                                      });
                                    },
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
                      case CustomTabType():
                        {
                          return tab.widget;
                        }
                      case CustomDetailsTabType():
                        return tab.builder(teamData.value!);
                    }
                  }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
