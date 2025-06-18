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
  String? _mainCoach;
  final _lastNameController = TextEditingController();
  DateTime _birthdate = DateTime.now();
  bool isEditMode = false;
  bool _inputsInitialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _teamNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void resetInputs(Map<String, dynamic> data) {
    _teamNameController.text = data["name"] ?? "";
    _mainCoach = data["head_coach"];
    _lastNameController.text = data["last"] ?? "";
    _birthdate = DateTime.fromMillisecondsSinceEpoch(
      (data["birthdate"] as Timestamp).millisecondsSinceEpoch,
    );
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
      InputBox(
        controller: _mainCoach,
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
            print(date);
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
          title: Text("${data["last"]}, ${data["first"]}"),
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
                          "first": _teamNameController.text,
                          "middle": _mainCoach.text,
                          "last": _lastNameController.text,
                          "birthdate": Timestamp.fromMillisecondsSinceEpoch(
                            _birthdate.millisecondsSinceEpoch,
                          ),
                        };
                        for (final entry in inputs.entries) {
                          if (data[entry.key] != entry.value) {
                            changedData[entry.key] = entry.value;
                          }
                        }
                        if (changedData.isNotEmpty) {
                          await FirebaseFirestore.instance
                              .doc("teams/${widget.uid}")
                              .update(changedData);
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

class MemberInputBox extends StatelessWidget {
  final String title;
  final Function(DateTime) onMemberSelected;
  final DateTime defaultMember;
  final bool isEditMode;

  const MemberInputBox({
    super.key,
    required this.title,
    required this.onMemberSelected,
    required this.defaultMember,
    required this.isEditMode,
  });

  @override
  Widget build(BuildContext context) {
    return InputBox(
      inputWidget: TextField(
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          hintText: ,
          prefixIcon: Icon(Icons.date_range),
        ),
        readOnly: true,
        onTap: () async {
          if (isEditMode) {
            DateTime? newDate = await showDatePicker(
              context: context,
              initialDate: defaultDate,
              firstDate: DateTime(1900),
              lastDate: DateTime(2200),
            );

            if (newDate != null) {
              onDateSelected(newDate);
            }
          }
        },
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
