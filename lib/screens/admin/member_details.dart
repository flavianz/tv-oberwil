import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tv_oberwil/firestore_providers/firestore_tools.dart';

import '../../components/input_boxes.dart';
import '../../firestore_providers/basic_providers.dart';

class MemberDetailsScreen extends ConsumerStatefulWidget {
  final String uid;
  final bool created;

  const MemberDetailsScreen({
    super.key,
    required this.uid,
    this.created = false,
  });

  @override
  ConsumerState<MemberDetailsScreen> createState() =>
      _MemberDetailsScreenState();
}

class _MemberDetailsScreenState extends ConsumerState<MemberDetailsScreen> {
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  DateTime _birthdate = DateTime.now();
  List<dynamic> teams = [];

  bool isEditMode = false;
  bool _inputsInitialized = false;
  bool _isSaving = false;
  bool isFirstRender = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void resetInputs(Map<String, dynamic> data) {
    _firstNameController.text = data["first"] ?? "";
    _middleNameController.text = data["middle"] ?? "";
    _lastNameController.text = data["last"] ?? "";
    _birthdate = DateTime.fromMillisecondsSinceEpoch(
      ((data["birthdate"] ?? Timestamp.now()) as Timestamp)
          .millisecondsSinceEpoch,
    );
    teams = (data["teams"] ?? []) as List<dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    if (isFirstRender) {
      isEditMode = widget.created;
      isFirstRender = false;
    }
    final isTablet = MediaQuery.of(context).size.aspectRatio > 1;
    final memberData = ref.watch(
      realtimeDocProvider(
        FirebaseFirestore.instance.doc("members/${widget.uid}"),
      ),
    );

    if (memberData.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (memberData.hasError) {
      return const Center(child: Text("An error occurred loading your data"));
    }

    final data = memberData.value?.data() ?? {};

    if (!memberData.isLoading &&
        memberData.value != null &&
        !_inputsInitialized) {
      final data = memberData.value!.data();
      if (data != null) {
        resetInputs(data);
        _inputsInitialized = true;
      }
    }

    final personalInfoBoxes = [
      TextInputBox(
        controller: _firstNameController,
        title: "Vorname",
        isEditMode: isEditMode,
      ),
      TextInputBox(
        controller: _middleNameController,
        title: "Zwischenname",
        isEditMode: isEditMode,
      ),
      TextInputBox(
        controller: _lastNameController,
        title: "Name",
        isEditMode: isEditMode,
      ),
      DateInputBox(
        title: "Geburtsdatum",
        onDateSelected: (date) {
          setState(() {
            _birthdate = date;
          });
        },
        defaultDate: _birthdate,
        isEditMode: isEditMode,
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 35 : 0,
        vertical: 15,
      ),
      child: Scaffold(
        appBar: AppBar(
          actionsPadding: const EdgeInsets.symmetric(horizontal: 12),
          title: Text(
            widget.created
                ? "Neues Mitglied"
                : "${_lastNameController.text}, ${_firstNameController.text}",
          ),
          actions: [
            (Row(
              spacing: 5,
              children:
                  isEditMode
                      ? [
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              resetInputs(data);
                              isEditMode = false;
                              _inputsInitialized = true;
                              if (widget.created) {
                                context.go("/admin/members");
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
                            final Map<String, dynamic> inputs = {
                              "first": _firstNameController.text,
                              "search_first": searchify(
                                _firstNameController.text,
                              ),
                              "middle": _middleNameController.text,
                              "last": _lastNameController.text,
                              "search_last": searchify(
                                _lastNameController.text,
                              ),
                              "birthdate": Timestamp.fromMillisecondsSinceEpoch(
                                _birthdate.millisecondsSinceEpoch,
                              ),
                              "teams": teams,
                            };
                            if (widget.created) {
                              FirebaseFirestore.instance
                                  .doc("members/${widget.uid}")
                                  .set(inputs)
                                  .whenComplete(() {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Mitglied wurde erstellt!',
                                          ),
                                        ),
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
                                await FirebaseFirestore.instance
                                    .doc("members/${widget.uid}")
                                    .update(changedData)
                                    .whenComplete(() {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Daten wurden aktualisiert!',
                                            ),
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
                                context.go("/admin/members?r=true");
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
                      ]
                      : [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              isEditMode = true;
                            });
                          },
                          icon: const Icon(Icons.edit),
                        ),
                      ],
            )),
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Spieler löschen?'),
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
                            onPressed: () => context.go("/admin/members"),
                            child: const Text("Abbrechen"),
                          ),
                          FilledButton.icon(
                            onPressed: () {
                              FirebaseFirestore.instance
                                  .doc("members/${memberData.value?.id}")
                                  .delete();
                              context.pop();
                              context.go("/admin/members?r=true");
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const Text(
                "Persönliche Informationen",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 21),
              ),
              const SizedBox(height: 10),
              isTablet
                  ? Row(
                    children:
                        personalInfoBoxes
                            .map(
                              (w) => Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: 15),
                                  child: w,
                                ),
                              ),
                            )
                            .toList(),
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children:
                        personalInfoBoxes
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
    );
  }
}
