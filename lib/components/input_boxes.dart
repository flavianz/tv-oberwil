import 'package:flutter/material.dart';

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

class SelectionInputBox<T> extends StatelessWidget {
  final String title;
  final bool isEditMode;
  final Map<T, String> options;
  final T selected;
  final Function(T) onSelected;
  final T defaultKey;

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
            (options..putIfAbsent(defaultKey, () => "Keine Angabe")).entries
                .map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                })
                .toList(),
        onChanged:
            isEditMode
                ? (T? s) {
                  onSelected(s ?? selected);
                }
                : null,
        value: isEditMode ? selected : null,
        disabledHint: Text(
          options[selected] ?? "Keine Angabe",
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
  final String selectedText;
  final String title;
  final bool openDialogInNonEditMode;
  final Function(dynamic data) onUpdate;
  final Widget? prefixIcon;

  const DialogInputBox({
    super.key,
    required this.dialogBuilder,
    required this.isEditMode,
    required this.selectedText,
    required this.title,
    required this.onUpdate,
    this.openDialogInNonEditMode = false,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return InputBox(
      inputWidget: TextField(
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          hintText: selectedText,
          prefixIcon: prefixIcon,
        ),
        readOnly: true,
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

class MultiSelectInputBox extends StatefulWidget {
  final String title;
  final bool isEditMode;
  final Map<T, String> options;
  final List<T> selected;
  final Function(List<T>) onSelected;

  const MultiSelectInputBox({
    super.key,
    required this.title,
    required this.isEditMode,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  State<MultiSelectInputBox> createState() => _MultiSelectInputBoxState();
}

class _MultiSelectInputBoxState extends State<MultiSelectInputBox> {
  List<String> selected = [];

  @override
  void initState() {
    selected = widget.selected;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DialogInputBox(
      dialogBuilder: (onSelected) {
        return Dialog(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Column(
                  children:
                      widget.options.entries.map((option) {
                        return Row(
                          spacing: 15,
                          children: [
                            Checkbox(
                              value: selected.contains(option.key),
                              onChanged: (bool? newValue) {
                                if (newValue ?? false) {
                                  selected.add(option.key);
                                } else {
                                  selected.remove(option.key);
                                }
                              },
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
        );
      },
      isEditMode: widget.isEditMode,
      selectedText: widget.options[widget.selected] ?? "",
      title: widget.title,
      onUpdate: (selected) => widget.onSelected(selected),
    );
  }
}
