import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tv_oberwil/components/input_boxes.dart';
import 'package:tv_oberwil/components/misc.dart';
import 'package:tv_oberwil/components/collection_list_widget.dart';
import 'package:tv_oberwil/firestore_providers/firestore_tools.dart';
import 'package:tv_oberwil/utils.dart';

import '../firestore_providers/paginated_list_provider.dart';

class TableOptions {
  final Function(DocumentSnapshot<Object?>) rowOnTap;

  const TableOptions(this.rowOnTap);
}

sealed class FilterProperty {
  final String key;

  const FilterProperty(this.key);
}

class ChipFilterProperty extends FilterProperty {
  final List<String> selectedKeys;
  final List<String> possibleKeys;
  final bool isList;

  const ChipFilterProperty(
    super.key,
    this.selectedKeys,
    this.possibleKeys,
    this.isList,
  );
}

class BoolFilterProperty extends FilterProperty {
  final bool? value;

  const BoolFilterProperty(super.key, this.value);
}

class DateFilterProperty extends FilterProperty {
  DateTime startDate;
  DateTime endDate;

  DateFilterProperty(super.key, this.startDate, this.endDate);
}

class OrderData {
  DataField filterField;
  bool direction; // true = descending, false = ascending

  OrderData(this.filterField, this.direction);
}

class CollectionListPage extends ConsumerStatefulWidget {
  final Widget Function(DocumentSnapshot<Object?>)? builder;
  final Query<Map<String, dynamic>> query;
  final String collectionKey;
  final int maxQueryLimit;
  final List<String>? searchFields;
  final List<Widget>? actions;
  final String? title;
  final TableOptions? tableOptions;
  final bool showBackButton;
  final bool actionsInSearchBar;
  final OrderData defaultOrderData;

  const CollectionListPage({
    super.key,
    this.builder,
    required this.query,
    required this.collectionKey,
    this.title,
    this.maxQueryLimit = 10,
    this.searchFields,
    this.actions,
    this.tableOptions,
    this.showBackButton = true,
    this.actionsInSearchBar = false,
    required this.defaultOrderData,
  });

  @override
  ConsumerState<CollectionListPage> createState() => _CollectionListPageState();
}

class _CollectionListPageState extends ConsumerState<CollectionListPage> {
  String? searchText;
  final TextEditingController searchController = TextEditingController();
  FilterProperty? activeFilter;
  Map<String, FilterProperty>? filterProperties;
  late OrderData orderData;
  DocModel model = DocModel({});
  List<DataField>? filters = [];

  @override
  void initState() {
    super.initState();
    orderData = widget.defaultOrderData;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.builder == null && widget.tableOptions == null) {
      throw ErrorDescription("No builder or table specified");
    }

    final isScreenWide = MediaQuery.of(context).size.aspectRatio > 1;
    final showAppBar =
        widget.title != null ||
        (widget.actions != null && !widget.actionsInSearchBar);

    final List<bool Function(DocumentSnapshot<Object?>)> filterFunctions = [];

    // text search
    if (searchText != null &&
        searchText!.isNotEmpty &&
        widget.searchFields != null) {
      filterFunctions.add((doc) {
        final data = castMap(doc.data());
        bool searchTextContainsAllSearchKeys = true;
        for (final searchKey in searchText!.split(" ")) {
          if (searchKey.isEmpty) {
            continue;
          }
          bool searchKeyInAnySearchField = false;
          for (final searchField in widget.searchFields!) {
            if (data[searchField] != null &&
                (data[searchField] as String).contains(searchify(searchKey))) {
              searchKeyInAnySearchField = true;
              break;
            }
          }
          if (!searchKeyInAnySearchField) {
            searchTextContainsAllSearchKeys = false;
            break;
          }
        }
        return searchTextContainsAllSearchKeys;
      });
    }

    if (filterProperties != null) {
      for (final filterProperty in filterProperties!.values) {
        filterFunctions.add((doc) {
          final data = castMap(doc.data());
          switch (filterProperty) {
            case BoolFilterProperty():
              return filterProperty.value == null
                  ? true
                  : data[filterProperty.key] == filterProperty.value;
            case ChipFilterProperty():
              if (filterProperty.isList) {
                print(
                  "sele ${filterProperty.selectedKeys}, ${(data[filterProperty.key] as List).length}",
                );
                return filterProperty.selectedKeys.length ==
                        filterProperty.possibleKeys.length
                    ? true
                    : filterProperty.selectedKeys.any(
                      (option) =>
                          (data[filterProperty.key] as List).contains(option),
                    );
              } else {
                return filterProperty.selectedKeys.contains(
                  data[filterProperty.key],
                );
              }
            case DateFilterProperty():
              return (filterProperty.startDate.isBefore(
                        (data[filterProperty.key] as Timestamp).toDate(),
                      ) &&
                      filterProperty.endDate.isAfter(
                        (data[filterProperty.key] as Timestamp).toDate(),
                      )) ||
                  isSameDate(
                    (data[filterProperty.key] as Timestamp).toDate(),
                    filterProperty.startDate,
                  ) ||
                  isSameDate(
                    (data[filterProperty.key] as Timestamp).toDate(),
                    filterProperty.endDate,
                  );
          }
        });
      }
    }

    openFilterFunction() async {
      if (isScreenWide) {
        await showDialog<String>(
          context: context,
          builder:
              (BuildContext context) => Dialog(
                child: FilterDialog(
                  availableFilters: filters!,
                  filterProperties: filterProperties!,
                ),
              ),
        );
      } else {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          // Allows modal to expand beyond default limits
          builder:
              (context) => FractionallySizedBox(
                heightFactor: 0.7, // 90% of screen height
                child: FilterDialog(
                  availableFilters: filters!,
                  filterProperties: filterProperties!,
                ),
              ),
        );
      }
      setState(() {
        filterProperties =
            filterProperties == null ? null : {...filterProperties!};
      });
    }

    final builder =
        widget.tableOptions != null
            ? ((doc) {
              final data = castMap(doc.data());
              final orderedFields =
                  model.fields.values
                      .where((field) => field.tableColumnWidth != null)
                      .toList()
                    ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
              return GestureDetector(
                onTap: () => widget.tableOptions!.rowOnTap(doc),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children:
                              orderedFields
                                  .map(
                                    (field) => Expanded(
                                      flex: field.tableColumnWidth!,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: switch (field) {
                                          TextDataField() => Text(
                                            data[field.key] ?? "",
                                          ),
                                          BoolDataField() => getBoolPill(
                                            data[field.key] ?? false,
                                          ),
                                          DateDataField() => () {
                                            final date =
                                                DateTime.fromMillisecondsSinceEpoch(
                                                  ((data[field.key] ??
                                                              Timestamp.now())
                                                          as Timestamp)
                                                      .millisecondsSinceEpoch,
                                                );
                                            return Text(
                                              "${date.day}. ${date.month}. ${date.year}",
                                            );
                                          }(),
                                          SelectionDataField() => Text(
                                            field.options[data[field.key]] ??
                                                "",
                                          ),
                                          MultiSelectDataField() => Text(
                                            (data[field.key] as List<dynamic>?)
                                                    ?.map(
                                                      (key) =>
                                                          field.options[key],
                                                    )
                                                    .join(", ") ??
                                                "",
                                          ),
                                        },
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                      Divider(height: 20),
                    ],
                  ),
                ),
              );
            })
            : widget.builder!;

    final docs = ref.watch(
      getCollectionProvider(widget.collectionKey, widget.query),
    );
    return docs.when(
      data: (data) {
        final modelIndex = data.indexWhere((doc) => doc.id == "model");
        if (modelIndex == -1) {
          throw ErrorDescription("no doc model found");
        }
        if (model.fields.isEmpty) {
          model = DocModel.fromMap(castMap(data[modelIndex].data()));
          filters =
              model.fields.values
                  .where(
                    (field) =>
                        field.tableColumnWidth != null &&
                        field is! TextDataField,
                  )
                  .toList()
                ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
          filterProperties = Map.fromEntries(
            filters!.map((filter) {
              return MapEntry(filter.key, switch (filter) {
                BoolDataField() => BoolFilterProperty(filter.key, null),
                SelectionDataField() => ChipFilterProperty(
                  filter.key,
                  filter.options.keys.toList(),
                  filter.options.keys.toList(),
                  false,
                ),
                MultiSelectDataField() => ChipFilterProperty(
                  filter.key,
                  filter.options.keys.toList(),
                  filter.options.keys.toList(),
                  true,
                ),
                DateDataField() => DateFilterProperty(
                  filter.key,
                  filter.minDate,
                  filter.maxDate,
                ),
                TextDataField() => throw UnimplementedError(),
              });
            }),
          );
        }
        final List<DocumentSnapshot<Object?>> filtered =
            data
                .where((doc) => doc.id != "model")
                .where((doc) => filterFunctions.every((test) => test(doc)))
                .toList()
              ..sort(switch (orderData.filterField) {
                TextDataField() || SelectionDataField() => (
                  DocumentSnapshot<Object?> a,
                  DocumentSnapshot<Object?> b,
                ) {
                  final value = (searchify(
                    castMap(a.data())[orderData.filterField.key] ?? "",
                  )).compareTo(
                    searchify(
                      castMap(b.data())[orderData.filterField.key] ?? "",
                    ),
                  );
                  return orderData.direction ? -1 * value : value;
                },
                BoolDataField() => (
                  DocumentSnapshot<Object?> a,
                  DocumentSnapshot<Object?> b,
                ) {
                  final boolA =
                      ((castMap(a.data())[orderData.filterField.key] ?? true)
                          as bool);
                  final boolB =
                      ((castMap(b.data())[orderData.filterField.key] ?? true)
                          as bool);
                  final value = boolA == boolB ? 0 : (boolA && !boolB ? 1 : -1);
                  return orderData.direction ? (-1 * value) : value;
                },
                DateDataField() => (
                  DocumentSnapshot<Object?> a,
                  DocumentSnapshot<Object?> b,
                ) {
                  final value = ((castMap(a.data())[orderData
                                  .filterField
                                  .key] ??
                              Timestamp.now())
                          as Timestamp)
                      .compareTo(
                        (castMap(b.data())[orderData.filterField.key] ??
                                Timestamp.now())
                            as Timestamp,
                      );
                  return orderData.direction ? -1 * value : value;
                },
                MultiSelectDataField() => (
                  DocumentSnapshot<Object?> a,
                  DocumentSnapshot<Object?> b,
                ) {
                  final value = ((castMap(a.data())[orderData
                                  .filterField
                                  .key] ??
                              [])
                          as List<dynamic>)
                      .length
                      .compareTo(
                        ((castMap(b.data())[orderData.filterField.key] ?? [],)
                                as List)
                            .length,
                      );
                  return orderData.direction ? -1 * value : value;
                },
              });
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isScreenWide ? 35 : 0,
            vertical: 15,
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar:
                showAppBar
                    ? AppBar(
                      forceMaterialTransparency: true,
                      automaticallyImplyLeading: widget.showBackButton,
                      actionsPadding: EdgeInsets.symmetric(horizontal: 12),
                      title: widget.title != null ? Text(widget.title!) : null,
                      actions:
                          !widget.actionsInSearchBar ? widget.actions : null,
                    )
                    : null,
            body: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  widget.searchFields != null
                      ? Row(
                        spacing: 10,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              onChanged: (newSearchText) {
                                setState(() {
                                  searchText = newSearchText;
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Suchen...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    right: 8,
                                  ),
                                  child: const Icon(Icons.search),
                                ),
                                prefixIconConstraints: BoxConstraints(),
                              ),
                              onSubmitted: (_) {
                                setState(() {
                                  searchText = searchController.text;
                                });
                              },
                            ),
                          ),

                          filters != null && filters!.isNotEmpty
                              ? (isScreenWide
                                  ? TextButton.icon(
                                    onPressed: openFilterFunction,
                                    label: Text("Filter"),
                                    icon: Icon(Icons.filter_list),
                                  )
                                  : IconButton.filledTonal(
                                    onPressed: openFilterFunction,
                                    icon: Icon(Icons.filter_list),
                                  ))
                              : SizedBox.shrink(),
                          (widget.actionsInSearchBar && widget.actions != null)
                              ? Row(children: widget.actions!)
                              : SizedBox.shrink(),
                        ],
                      )
                      : SizedBox.shrink(),
                  widget.tableOptions != null
                      ? Padding(
                        padding: const EdgeInsets.only(top: 25, bottom: 7),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: () {
                            final orderedFields =
                                model.fields.values
                                    .where(
                                      (field) => field.tableColumnWidth != null,
                                    )
                                    .toList()
                                  ..sort(
                                    (a, b) =>
                                        (a.order ?? 0).compareTo(b.order ?? 0),
                                  );
                            return orderedFields.map((field) {
                              return Expanded(
                                flex: field.tableColumnWidth!,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (orderData.filterField.key ==
                                          field.key) {
                                        orderData.direction =
                                            !orderData.direction;
                                      } else {
                                        orderData.filterField = field;
                                        orderData.direction = false;
                                      }
                                    });
                                  },
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(field.name),
                                          Padding(
                                            padding: EdgeInsets.only(right: 10),
                                            child: Icon(
                                              orderData.filterField.key ==
                                                      field.key
                                                  ? (orderData.direction
                                                      ? Icons.arrow_drop_down
                                                      : Icons.arrow_drop_up)
                                                  : Icons.swap_vert_sharp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList();
                          }(),
                        ),
                      )
                      : SizedBox.shrink(),
                  Divider(thickness: 2, color: Theme.of(context).primaryColor),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) => builder(filtered[i]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) {
        return Center(child: SelectableText('Error: $e'));
      },
    );
  }
}

class FilterDialog extends StatefulWidget {
  final List<DataField> availableFilters;
  final Map<String, FilterProperty> filterProperties;

  const FilterDialog({
    super.key,
    required this.availableFilters,
    required this.filterProperties,
  });

  @override
  FilterDialogState createState() => FilterDialogState();
}

class FilterDialogState extends State<FilterDialog> {
  @override
  Widget build(BuildContext context) {
    final isScreenWide = MediaQuery.of(context).size.aspectRatio > 1;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 800),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children:
                          widget.availableFilters.map((filter) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(filter.name),
                                Divider(),
                                switch (filter) {
                                  SelectionDataField() ||
                                  MultiSelectDataField() => () {
                                    final options =
                                        filter is SelectionDataField
                                            ? filter.options
                                            : (filter as MultiSelectDataField)
                                                .options;
                                    return Wrap(
                                      alignment: WrapAlignment.start,
                                      spacing: 5,
                                      runSpacing: 5,
                                      children: [
                                        FilterChip(
                                          selected:
                                              ((widget.filterProperties[filter
                                                          .key])
                                                      as ChipFilterProperty?)
                                                  ?.selectedKeys
                                                  .length ==
                                              options.length,
                                          label: Text("Alle"),
                                          onSelected: (bool isSelectedNow) {
                                            if (isSelectedNow) {
                                              setState(() {
                                                widget.filterProperties[filter
                                                    .key] = ChipFilterProperty(
                                                  filter.key,
                                                  options.keys.toList(),
                                                  options.keys.toList(),
                                                  filter
                                                      is MultiSelectDataField,
                                                );
                                              });
                                            } else {
                                              setState(() {
                                                widget.filterProperties[filter
                                                    .key] = ChipFilterProperty(
                                                  filter.key,
                                                  [],
                                                  options.keys.toList(),
                                                  filter
                                                      is MultiSelectDataField,
                                                );
                                              });
                                            }
                                          },
                                        ),
                                        ...options.entries.map(
                                          (option) => FilterChip(
                                            selected: ((widget
                                                        .filterProperties[filter
                                                        .key])
                                                    as ChipFilterProperty?)!
                                                .selectedKeys
                                                .contains(option.key),
                                            label: Text(option.value),
                                            onSelected: (isSelectedNow) {
                                              if (isSelectedNow) {
                                                setState(() {
                                                  ((widget.filterProperties[filter
                                                              .key])
                                                          as ChipFilterProperty?)
                                                      ?.selectedKeys
                                                      .add(option.key);
                                                });
                                              } else {
                                                setState(() {
                                                  ((widget.filterProperties[filter
                                                              .key])
                                                          as ChipFilterProperty?)
                                                      ?.selectedKeys
                                                      .remove(option.key);
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    );
                                  }(),
                                  BoolDataField() => SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        Radio<bool?>(
                                          value: null,
                                          groupValue:
                                              ((widget.filterProperties[filter
                                                          .key])
                                                      as BoolFilterProperty?)
                                                  ?.value,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              widget.filterProperties[filter
                                                  .key] = BoolFilterProperty(
                                                filter.key,
                                                null,
                                              );
                                            });
                                          },
                                        ),
                                        getPill("Beide", Colors.amber, true),
                                        SizedBox(width: 15),
                                        Radio(
                                          value: true,
                                          groupValue:
                                              ((widget.filterProperties[filter
                                                          .key])
                                                      as BoolFilterProperty?)
                                                  ?.value,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              widget.filterProperties[filter
                                                  .key] = BoolFilterProperty(
                                                filter.key,
                                                true,
                                              );
                                            });
                                          },
                                        ),
                                        getPill("Ja", Colors.green, true),
                                        SizedBox(width: 15),
                                        Radio(
                                          value: false,
                                          groupValue:
                                              ((widget.filterProperties[filter
                                                          .key])
                                                      as BoolFilterProperty?)
                                                  ?.value,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              widget.filterProperties[filter
                                                  .key] = BoolFilterProperty(
                                                filter.key,
                                                false,
                                              );
                                            });
                                          },
                                        ),
                                        getPill("Nein", Colors.red, true),
                                      ],
                                    ),
                                  ),
                                  DateDataField() => () {
                                    final children = [
                                      DateInputBox(
                                        title: "Von",
                                        onDateSelected:
                                            (date) => setState(() {
                                              (widget.filterProperties[filter
                                                          .key]
                                                      as DateFilterProperty)
                                                  .startDate = date;
                                            }),
                                        defaultDate:
                                            (widget.filterProperties[filter.key]
                                                    as DateFilterProperty)
                                                .startDate,
                                        isEditMode: true,
                                      ),
                                      DateInputBox(
                                        title: "Bis",
                                        onDateSelected:
                                            (date) => setState(() {
                                              (widget.filterProperties[filter
                                                          .key]
                                                      as DateFilterProperty)
                                                  .endDate = date;
                                            }),
                                        defaultDate:
                                            (widget.filterProperties[filter.key]
                                                    as DateFilterProperty)
                                                .endDate,
                                        isEditMode: true,
                                      ),
                                    ];
                                    return isScreenWide
                                        ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          spacing: 15,
                                          children: children,
                                        )
                                        : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          spacing: 10,
                                          children: children,
                                        );
                                  }(),
                                  TextDataField() => throw UnimplementedError(),
                                },
                                SizedBox(height: 25),
                              ],
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.icon(
                  onPressed: () => context.pop(),
                  icon: Icon(Icons.check),
                  label: const Text('Anwenden'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
