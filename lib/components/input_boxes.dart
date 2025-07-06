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
                ? (T? s) {
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
