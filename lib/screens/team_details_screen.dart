import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final userStreamProvider = StreamProvider.family<
  DocumentSnapshot<Map<String, dynamic>>,
  String
>((ref, uid) {
  return FirebaseFirestore.instance.collection('teams').doc(uid).snapshots();
});

class TeamDetailsScreen extends ConsumerStatefulWidget {
  final String uid;

  const TeamDetailsScreen({super.key, required this.uid});

  @override
  ConsumerState<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends ConsumerState<TeamDetailsScreen> {
  final _teamNameController = TextEditingController();
  String teamType = "active";
  bool isEditMode = false;
  bool _inputsInitialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  void resetInputs(Map<String, dynamic> data) {
    _teamNameController.text = data["name"] ?? "";
    teamType = data["type"] ?? "active";
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.aspectRatio > 1;
    final teamData = ref.watch(userStreamProvider(widget.uid));

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

    final personalInfoBoxes = [
      TextInputBox(
        controller: _teamNameController,
        title: "Teamname",
        isEditMode: isEditMode,
      ),
      SelectionInputBox(
        title: "Teamart",
        isEditMode: isEditMode,
        options: {"juniors": "Junioren", "active": "Aktive", "fun": "Plausch"},
        selected: teamType,
        onSelected: (s) {
          setState(() {
            teamType = s;
          });
        },
      ),
    ];

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
            title: Text(_teamNameController.text),
            bottom: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.info_outline), text: "Infos"),
                Tab(icon: Icon(Icons.people_alt_outlined), text: "Spieler"),
                Tab(icon: Icon(Icons.shield_outlined), text: "Trainer"),
              ],
            ),
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
                            "name": _teamNameController.text,
                            "type": teamType,
                          };
                          for (final entry in inputs.entries) {
                            if (data[entry.key] != entry.value) {
                              changedData[entry.key] = entry.value;
                            }
                          }
                          if (changedData.isNotEmpty) {
                            await FirebaseFirestore.instance
                                .doc("teams/${widget.uid}")
                                .update(changedData)
                                .whenComplete(() {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Daten wurden aktualisiert!',
                                        ),
                                      ),
                                    );
                                  }
                                });
                          }
                          setState(() {
                            _isSaving = false;
                            isEditMode = false;
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
                              onPressed: () => context.pop(),
                              child: const Text("Abbrechen"),
                            ),
                            FilledButton.icon(
                              onPressed: () {
                                FirebaseFirestore.instance
                                    .doc("teams/${teamData.value?.id}")
                                    .delete();
                                context.pop();
                                context.go("/teams?r=true");
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
          body: TabBarView(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
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
              Center(),
              Center(),
            ],
          ),
        ),
      ),
    );
  }
}

class TextInputBox extends StatelessWidget {
  final TextEditingController controller;
  final String title;
  final bool isEditMode;

  const TextInputBox({
    super.key,
    required this.controller,
    required this.title,
    required this.isEditMode,
  });

  @override
  Widget build(BuildContext context) {
    return InputBox(
      inputWidget: TextField(
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        readOnly: !isEditMode,
        controller: controller,
      ),
      title: title,
    );
  }
}

class SelectionInputBox extends StatelessWidget {
  final String title;
  final bool isEditMode;
  final Map<String, String> options;
  final String selected;
  final Function(String) onSelected;

  const SelectionInputBox({
    super.key,
    required this.title,
    required this.isEditMode,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InputBox(
      inputWidget: DropdownButtonFormField(
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items:
            options.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
        onChanged:
            isEditMode
                ? (String? s) {
                  onSelected(s ?? selected);
                }
                : null,
        value: isEditMode ? selected : null,
        disabledHint: Text(
          options[selected] ?? "None",
          style: TextStyle(color: Colors.black),
        ),
      ),
      title: title,
    );
  }
}

class InputBox extends StatelessWidget {
  final Widget inputWidget;
  final String title;

  const InputBox({super.key, required this.inputWidget, required this.title});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          inputWidget,
        ],
      ),
    );
  }
}
