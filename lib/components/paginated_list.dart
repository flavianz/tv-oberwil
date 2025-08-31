import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tv_oberwil/firestore_providers/paginated_list_proivder.dart';
import 'package:equatable/equatable.dart';
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

  const DataField(
    this.key,
    this.name,
    this.required, {
    this.tableColumnWidth,
    this.order,
  });

  factory DataField.fromMap(Map<String, dynamic> map) {
    final bool required = map["required"] ?? false;
    final String name = map["name"] ?? "Name";
    final String key = map["key"] ?? "key";
    final int? tableColumnWidth = map["table_column_width"];
    final int? order = map["order"];
    switch ((map["type"] ?? "") as String) {
      case "text":
        return TextDataField(
          key,
          name,
          required,
          map["searchable"] ?? false,
          tableColumnWidth: tableColumnWidth,
          order: order,
        );
      case "bool":
        return BoolDataField(
          key,
          name,
          required,
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
    super.required, {
    super.tableColumnWidth,
    super.order,
  });
}

class PaginatedList extends ConsumerStatefulWidget {
  final Widget Function(DocumentSnapshot<Object?>, DocModel) builder;
  final Query<Map<String, dynamic>> query;
  final String collectionKey;
  final List<DocumentSnapshot<Object?>> Function(
    List<DocumentSnapshot<Object?>>,
  )?
  filter;

  const PaginatedList({
    super.key,
    required this.builder,
    required this.query,
    required this.collectionKey,
    this.filter,
  });

  @override
  ConsumerState<PaginatedList> createState() => _PaginatedListState();
}

class PaginatedParams extends Equatable {
  final Query<Map<String, dynamic>> query;
  final String collectionKey;

  const PaginatedParams(this.query, this.collectionKey);

  @override
  List<Object?> get props => [query, collectionKey];
}

class _PaginatedListState extends ConsumerState<PaginatedList> {
  @override
  Widget build(BuildContext context) {
    final docs = ref.watch(
      getCollectionProvider(widget.collectionKey, widget.query),
    );
    return docs.when(
      data: (data) {
        final modelIndex = data.indexWhere((doc) => doc.id == "model");
        if (modelIndex == -1) {
          throw ErrorDescription("no doc model found");
        }
        final DocModel docModel = DocModel.fromMap(
          castMap(data[modelIndex].data()),
        );
        final cleanData = [...data];
        cleanData.removeAt(modelIndex);

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
            return widget.builder(children[index], docModel);
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
