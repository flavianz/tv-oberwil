import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final userStreamProvider = StreamProvider.family<
  DocumentSnapshot<Map<String, dynamic>>,
  String
>((ref, uid) {
  return FirebaseFirestore.instance.collection('members').doc(uid).snapshots();
});

class MemberDetailsScreen extends ConsumerStatefulWidget {
  final String uid;

  const MemberDetailsScreen({super.key, required this.uid});

  @override
  ConsumerState<MemberDetailsScreen> createState() =>
      _MemberDetailsScreenState();
}

class _MemberDetailsScreenState extends ConsumerState<MemberDetailsScreen> {
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  DateTime? _birthdate;

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.aspectRatio > 1;
    final memberData = ref.watch(userStreamProvider(widget.uid));

    if (memberData.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (memberData.hasError) {
      return const Center(child: Text("An error occurred loading your data"));
    }

    final data = memberData.value?.data() ?? {};
    _firstNameController.text = data["first"] ?? "";
    _middleNameController.text = data["middle"] ?? "";
    _lastNameController.text = data["last"] ?? "";
    _birthdate = DateTime.fromMillisecondsSinceEpoch(
      (data["birthdate"] as Timestamp).millisecondsSinceEpoch,
    );

    final personalInfoBoxes = [
      TextInputBox(controller: _firstNameController, title: "Vorname"),
      TextInputBox(controller: _middleNameController, title: "Zwischenname"),
      TextInputBox(controller: _lastNameController, title: "Name"),
      DateInputBox(
        title: "Geburtsdatum",
        onDateSelected: (date) {
          print(date);
        },
        defaultDate: _birthdate ?? DateTime.now(),
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
            IconButton(onPressed: () {}, icon: const Icon(Icons.edit)),
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
                                  .doc("members/${memberData.value?.id}")
                                  .delete();
                              context.pop();
                              context.go("/members?r=true");
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

  const TextInputBox({
    super.key,
    required this.controller,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return InputBox(
      inputWidget: TextField(
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        readOnly: true,
        controller: controller,
      ),
      title: title,
    );
  }
}

class DateInputBox extends StatelessWidget {
  final String title;
  final Function onDateSelected;
  final DateTime defaultDate;

  const DateInputBox({
    super.key,
    required this.title,
    required this.onDateSelected,
    required this.defaultDate,
  });

  @override
  Widget build(BuildContext context) {
    return InputBox(
      inputWidget: TextField(
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        readOnly: true,
        onTap: () async {
          onDateSelected(
            await showDatePicker(
              context: context,
              initialDate: defaultDate,
              firstDate: DateTime(1900),
              lastDate: DateTime(2200),
            ),
          );
        },
        controller: TextEditingController(
          text: "${defaultDate.day}. ${defaultDate.month}. ${defaultDate.year}",
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
