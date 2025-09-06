import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

class DateInputBox extends StatelessWidget {
  final String title;
  final Function(DateTime) onDateSelected;
  final DateTime defaultDate;
  final bool isEditMode;

  const DateInputBox({
    super.key,
    required this.title,
    required this.onDateSelected,
    required this.defaultDate,
    required this.isEditMode,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        "${defaultDate.day}. ${defaultDate.month}. ${defaultDate.year}";
    return InputBox(
      inputWidget: TextField(
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          hintText: formattedDate,
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

class TimeInputBox extends StatelessWidget {
  final String title;
  final Function(DateTime) onTimeSelected;
  final DateTime defaultTime;
  final bool isEditMode;

  const TimeInputBox({
    super.key,
    required this.title,
    required this.onTimeSelected,
    required this.defaultTime,
    required this.isEditMode,
  });

  @override
  Widget build(BuildContext context) {
    final formattedTime =
        "${defaultTime.hour.toString().padLeft(2, '0')}:${defaultTime.minute.toString().padLeft(2, '0')}";

    return InputBox(
      inputWidget: TextField(
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          hintText: formattedTime,
          prefixIcon: Icon(Icons.access_time),
        ),
        readOnly: true,
        onTap: () async {
          if (isEditMode) {
            TimeOfDay? newTime = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(defaultTime),
            );

            if (newTime != null) {
              // Convert TimeOfDay to DateTime with today's date
              final now = DateTime.now();
              final selectedDateTime = DateTime(
                now.year,
                now.month,
                now.day,
                newTime.hour,
                newTime.minute,
              );
              onTimeSelected(selectedDateTime);
            }
          }
        },
      ),
      title: title,
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
  final Map<String, dynamic> options;
  final String selected;
  final Function(String) onSelected;
  final String defaultKey;

  const SelectionInputBox({
    super.key,
    required this.title,
    required this.isEditMode,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.defaultKey,
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
        hint: Text(
          options[selected] ?? "Keine Angabe",
          style: TextStyle(color: Colors.black),
        ),
      ),
      title: title,
    );
  }
}

class BoolInputBox extends StatelessWidget {
  final String title;
  final bool isEditMode;
  final bool selected;
  final Function(bool) onSelected;
  final bool defaultValue;

  const BoolInputBox({
    super.key,
    required this.title,
    required this.isEditMode,
    required this.selected,
    required this.onSelected,
    required this.defaultValue,
  });

  @override
  Widget build(BuildContext context) {
    return InputBox(
      inputWidget: DropdownButtonFormField(
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: [
          DropdownMenuItem(value: true, child: Text("Ja")),
          DropdownMenuItem(value: false, child: Text("Nein")),
        ],
        onChanged:
            isEditMode
                ? (bool? s) {
                  onSelected(s ?? selected);
                }
                : null,
        value: isEditMode ? selected : null,
        hint: Text(
          selected ? "Ja" : "Nein",
          style: TextStyle(color: Colors.black),
        ),
      ),
      title: title,
    );
  }
}

class MemberInputBox extends StatelessWidget {
  final String title;
  final Function(DateTime) onDateSelected;
  final DateTime defaultDate;
  final bool isEditMode;

  const MemberInputBox({
    super.key,
    required this.title,
    required this.onDateSelected,
    required this.defaultDate,
    required this.isEditMode,
  });

  @override
  Widget build(BuildContext context) {
    return InputBox(
      inputWidget: TextField(
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          hintText: "formattedDate",
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

class DialogInputBox<T> extends StatelessWidget {
  final Dialog Function(Function) dialogBuilder;
  final bool isEditMode;
  final Widget boxContent;
  final String title;
  final bool openDialogInNonEditMode;
  final Function(dynamic data) onUpdate;

  const DialogInputBox({
    super.key,
    required this.dialogBuilder,
    required this.isEditMode,
    required this.boxContent,
    required this.title,
    required this.onUpdate,
    this.openDialogInNonEditMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return InputBox(
      inputWidget: GestureDetector(
        onTap: () async {
          if (isEditMode || openDialogInNonEditMode) {
            showDialog(
              context: context,
              builder: (context) {
                return dialogBuilder(onUpdate);
              },
            );
          }
        },
        child: MouseRegion(
          cursor:
              isEditMode || openDialogInNonEditMode
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.centerLeft,
            constraints: BoxConstraints(
              minHeight: 48,
              minWidth: double.infinity,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: boxContent,
          ),
        ),
      ),
      title: title,
    );
  }
}

typedef CustomInputBoxData =
    ({
      dynamic defaultValue,
      Widget Function(dynamic data, Function(dynamic newData) updateValue)
      builder,
    });

class MultiSelectInputBox extends StatelessWidget {
  final String title;
  final bool isEditMode;
  final Map<String, dynamic> options;
  final List<dynamic> selected;
  final Function(List<dynamic>) onSelected;

  const MultiSelectInputBox({
    super.key,
    required this.title,
    required this.isEditMode,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DialogInputBox(
      dialogBuilder: (onSelected) {
        return Dialog(
          child: MultiSelectInputDialog(
            selected: selected,
            options: options,
            onSelected: this.onSelected,
          ),
        );
      },
      isEditMode: isEditMode,
      boxContent: Text(selected.map((option) => options[option]).join(", ")),
      title: title,
      onUpdate: (selected) => onSelected(selected),
    );
  }
}

class MultiSelectInputDialog extends StatefulWidget {
  final List<dynamic> selected;
  final Map<String, dynamic> options;
  final Function(List<dynamic>) onSelected;

  const MultiSelectInputDialog({
    super.key,
    required this.selected,
    required this.options,
    required this.onSelected,
  });

  @override
  State<MultiSelectInputDialog> createState() => _MultiSelectInputDialogState();
}

class _MultiSelectInputDialogState extends State<MultiSelectInputDialog> {
  late List<dynamic> selected;

  @override
  void initState() {
    super.initState();
    // initialize local state from widget prop
    selected = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  widget.options.entries.map((entry) {
                    final key = entry.key;
                    return Row(
                      spacing: 8,
                      mainAxisSize: MainAxisSize.min,
                      // content only takes needed space
                      children: [
                        Checkbox(
                          value: selected.contains(key),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                selected = [...selected, key];
                              } else {
                                selected =
                                    selected.where((e) => e != key).toList();
                              }
                            });
                          },
                        ),
                        Text(widget.options[key]),
                      ],
                    );
                  }).toList(),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text("Abbrechen"),
                ),
                FilledButton(
                  onPressed: () {
                    widget.onSelected(selected);
                    context.pop();
                  },
                  child: Text("Ok"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
