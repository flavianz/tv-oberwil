import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tv_oberwil/firestore_providers/paginated_list_provider.dart';
import 'package:tv_oberwil/utils.dart';

class DocModel {
  final Map<String, DataField> fields;

  const DocModel(this.fields);

  factory DocModel.fromMap(Map<String, dynamic> map) {
    return DocModel(
      Map.fromEntries(
        castMap(map["fields"]).entries.map(
          (entry) =>
              MapEntry(entry.key, DataField.fromMap(map["fields"]?[entry.key])),
        ),
      ),
    );
  }
}

sealed class DataField {
  final bool required;
  final String name;
  final String key;
  final int? tableColumnWidth;
  final int? order;
  final int row;

  String type() {
    return switch (this) {
      TextDataField() => "text",
      BoolDataField() => "bool",
      DateDataField() => "date",
      TimeDataField() => "time",
      SelectionDataField() => "time",
      MultiSelectDataField() => "multi",
    };
  }

  const DataField(
    this.key,
    this.name,
    this.required,
    this.row, {
    this.tableColumnWidth,
    this.order,
  });

  factory DataField.fromMap(Map<String, dynamic> map) {
    final bool required = map["required"] ?? false;
    final String name = map["name"] ?? "Name";
    final String key = map["key"] ?? "key";
    final int? tableColumnWidth = map["table_column_width"];
    final int? order = map["order"];
    final int row = map["row"] ?? 0;
    switch ((map["type"] ?? "") as String) {
      case "text":
        return TextDataField(
          key,
          name,
          required,
          row,
          map["searchable"] ?? false,
          tableColumnWidth: tableColumnWidth,
          order: order,
        );
      case "bool":
        return BoolDataField(
          key,
          name,
          required,
          row,
          tableColumnWidth: tableColumnWidth,
          order: order,
        );
      case "date":
        return DateDataField(
          key,
          name,
          required,
          row,
          ((map["min_date"] ?? Timestamp.now()) as Timestamp).toDate(),
          ((map["max_date"] ?? Timestamp.now()) as Timestamp).toDate(),
          tableColumnWidth: tableColumnWidth,
          order: order,
        );
      case "time":
        return TimeDataField(
          key,
          name,
          required,
          row,
          tableColumnWidth: tableColumnWidth,
          order: order,
        );
      case "selection":
        return SelectionDataField(
          key,
          name,
          required,
          row,
          map["options"] ?? {},
          tableColumnWidth: tableColumnWidth,
          order: order,
        );
      case "multi_select":
        return MultiSelectDataField(
          key,
          name,
          required,
          row,
          map["options"] ?? {},
          tableColumnWidth: tableColumnWidth,
          order: order,
        );
      case _:
        throw ErrorDescription("Unknown data field type");
    }
  }

  @override
  String toString() {
    return {
      "required": required,
      "name": name,
      "key": key,
      "column_width": tableColumnWidth,
    }.toString();
  }
}

class TextDataField extends DataField {
  final bool isSearchable;

  TextDataField(
    super.key,
    super.name,
    super.row,
    super.required,
    this.isSearchable, {
    super.tableColumnWidth,
    super.order,
  });
}

class BoolDataField extends DataField {
  const BoolDataField(
    super.key,
    super.name,
    super.row,
    super.required, {
    super.tableColumnWidth,
    super.order,
  });
}

class DateDataField extends DataField {
  final DateTime minDate;
  final DateTime maxDate;

  const DateDataField(
    super.key,
    super.name,
    super.row,
    super.required,
    this.minDate,
    this.maxDate, {
    super.tableColumnWidth,
    super.order,
  });
}

class TimeDataField extends DataField {
  const TimeDataField(
    super.key,
    super.name,
    super.row,
    super.required, {
    super.tableColumnWidth,
    super.order,
  });
}

class SelectionDataField extends DataField {
  final Map<String, dynamic> options;

  SelectionDataField(
    super.key,
    super.name,
    super.row,
    super.required,
    this.options, {
    super.tableColumnWidth,
    super.order,
  });
}

class MultiSelectDataField extends DataField {
  final Map<String, dynamic> options;

  MultiSelectDataField(
    super.key,
    super.name,
    super.required,
    super.row,
    this.options, {
    super.tableColumnWidth,
    super.order,
  });
}

class CollectionListWidget extends ConsumerStatefulWidget {
  final Widget Function(DocumentSnapshot<Object?>) builder;
  final Query<Map<String, dynamic>> query;
  final String collectionKey;
  final List<DocumentSnapshot<Object?>> Function(
    List<DocumentSnapshot<Object?>>,
  )?
  filter;
  final bool removeModel;

  const CollectionListWidget({
    super.key,
    required this.builder,
    required this.query,
    required this.collectionKey,
    this.filter,
    this.removeModel = false,
  });

  @override
  ConsumerState<CollectionListWidget> createState() =>
      _CollectionWidgetListState();
}

class _CollectionWidgetListState extends ConsumerState<CollectionListWidget> {
  @override
  Widget build(BuildContext context) {
    final docs = ref.watch(
      getCollectionProvider(widget.collectionKey, widget.query),
    );
    return docs.when(
      data: (data) {
        final cleanData = [...data];
        if (widget.removeModel) {
          cleanData.removeWhere((doc) => doc.id == "model");
        }

        final List<DocumentSnapshot<Object?>> children =
            widget.filter != null
                ? widget.filter!(cleanData).toList()
                : cleanData.toList();
        if (children.isEmpty) {
          return const Center(child: Text('Nichts gefunden!'));
        }
        return ListView.builder(
          itemCount: children.length,
          itemBuilder: (context, index) {
            return widget.builder(children[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) {
        return Center(child: SelectableText('Error: $e'));
      },
    );
  }
}
