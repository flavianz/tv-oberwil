import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tv_oberwil/components/misc.dart';
import 'package:tv_oberwil/components/paginated_list.dart';
import 'package:tv_oberwil/firestore_providers/firestore_tools.dart';
import 'package:tv_oberwil/utils.dart';

class TableColumn {
  final String key;
  final String name;
  final Widget Function(dynamic data) builder;
  final int space;

  const TableColumn(this.key, this.name, this.builder, this.space);
}

class TableOptions {
  final List<TableColumn> columns;
  final Function(DocumentSnapshot<Object?>) rowOnTap;

  const TableOptions(this.columns, this.rowOnTap);
}

sealed class Filter {
  final String name;
  final String key;
  final IconData icon;

  const Filter(this.key, this.name, this.icon);
}

class ChipFilter extends Filter {
  final Map<String, String> options;

  ChipFilter(super.key, super.name, super.icon, this.options);
}

class BoolFilter extends Filter {
  final bool Function(bool, dynamic data)? filterApplyFunction;

  BoolFilter(super.key, super.name, super.icon, {this.filterApplyFunction});
}

sealed class FilterProperty {
  final String key;

  const FilterProperty(this.key);
}

class ChipFilterProperty extends FilterProperty {
  final List<String> selectedKeys;

  const ChipFilterProperty(super.key, this.selectedKeys);
}

class BoolFilterProperty extends FilterProperty {
  final bool? value;
  final bool Function(bool, dynamic data)? filterApplyFunction;

  const BoolFilterProperty(super.key, this.value, {this.filterApplyFunction});
}

class PaginatedListPage extends StatefulWidget {
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
  final List<Filter>? filters;

  const PaginatedListPage({
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
    this.filters,
  });

  @override
  State<PaginatedListPage> createState() => _PaginatedListPageState();
}

class _PaginatedListPageState extends State<PaginatedListPage> {
  String? searchText;
  final TextEditingController searchController = TextEditingController();
  FilterProperty? activeFilter;
  Map<String, FilterProperty>? filterProperties;

  @override
  void initState() {
    super.initState();
    if (widget.filters != null) {
      filterProperties = Map.fromEntries(
        widget.filters!.map((filter) {
          return MapEntry(filter.key, switch (filter) {
            BoolFilter() => BoolFilterProperty(
              filter.key,
              null,
              filterApplyFunction: filter.filterApplyFunction,
            ),
            ChipFilter() => ChipFilterProperty(
              filter.key,
              filter.options.keys.toList(),
            ),
          });
        }),
      );
    }
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
                  : (filterProperty.filterApplyFunction == null
                      ? data[filterProperty.key] == filterProperty.value
                      : filterProperty.filterApplyFunction!(
                        filterProperty.value!,
                        data[filterProperty.key],
                      ));
            case ChipFilterProperty():
              throw UnimplementedError();
          }
        });
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isScreenWide ? 35 : 0,
        vertical: 15,
      ),
      child: Scaffold(
        appBar:
            showAppBar
                ? AppBar(
                  automaticallyImplyLeading: widget.showBackButton,
                  actionsPadding: EdgeInsets.symmetric(horizontal: 12),
                  title: widget.title != null ? Text(widget.title!) : null,
                  actions: !widget.actionsInSearchBar ? widget.actions : null,
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
                      (widget.actionsInSearchBar && widget.actions != null)
                          ? Row(children: widget.actions!)
                          : SizedBox.shrink(),
                      widget.filters != null
                          ? TextButton.icon(
                            onPressed: () async {
                              if (isScreenWide) {
                                await showDialog<String>(
                                  context: context,
                                  builder:
                                      (BuildContext context) => Dialog(
                                        child: FilterDialog(
                                          availableFilters: widget.filters!,
                                          filterProperties: filterProperties!,
                                        ),
                                      ),
                                );
                                setState(() {
                                  filterProperties =
                                      filterProperties == null
                                          ? null
                                          : {...filterProperties!};
                                });
                              } else {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Center();
                                  },
                                );
                              }
                            },
                            label: Text("Filter"),
                            icon: Icon(Icons.filter_list),
                          )
                          : SizedBox.shrink(),
                    ],
                  )
                  : SizedBox.shrink(),
              widget.tableOptions != null
                  ? Padding(
                    padding: const EdgeInsets.only(top: 25, bottom: 7),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children:
                          widget.tableOptions!.columns.map((column) {
                            return Expanded(
                              flex: column.space,
                              child: Text(column.name),
                            );
                          }).toList(),
                    ),
                  )
                  : SizedBox.shrink(),
              Divider(thickness: 2, color: Theme.of(context).primaryColor),
              Expanded(
                child: PaginatedList(
                  builder:
                      widget.tableOptions != null
                          ? ((doc) {
                            final data = castMap(doc.data());
                            return GestureDetector(
                              onTap: () => widget.tableOptions!.rowOnTap(doc),
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 5,
                                      ),
                                      child: Row(
                                        children:
                                            widget.tableOptions!.columns.map((
                                              column,
                                            ) {
                                              return Expanded(
                                                flex: column.space,
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: column.builder(
                                                    data[column.key],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                    Divider(height: 20),
                                  ],
                                ),
                              ),
                            );
                          })
                          : widget.builder!,
                  query: widget.query,
                  collectionKey: widget.collectionKey,
                  filter:
                      (docs) =>
                          docs
                              .where(
                                (doc) =>
                                    filterFunctions.every((test) => test(doc)),
                              )
                              .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FilterDialog extends StatefulWidget {
  final List<Filter> availableFilters;
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
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 800),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children:
                  widget.availableFilters.map((filter) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Icon(filter.icon),
                            const SizedBox(width: 16),
                            Text(filter.name),
                          ],
                        ),
                        Divider(),
                        switch (filter) {
                          ChipFilter() => throw UnimplementedError(),
                          BoolFilter() => Row(
                            children: [
                              Radio<bool?>(
                                value: null,
                                groupValue:
                                    ((widget.filterProperties[filter.key])
                                            as BoolFilterProperty?)
                                        ?.value,
                                onChanged: (bool? value) {
                                  setState(() {
                                    widget.filterProperties[filter
                                        .key] = BoolFilterProperty(
                                      filter.key,
                                      null,
                                      filterApplyFunction:
                                          filter.filterApplyFunction,
                                    );
                                  });
                                },
                              ),
                              getPill("Beide", Colors.amber, true),
                              SizedBox(width: 25),
                              Radio(
                                value: true,
                                groupValue:
                                    ((widget.filterProperties[filter.key])
                                            as BoolFilterProperty?)
                                        ?.value,
                                onChanged: (bool? value) {
                                  setState(() {
                                    widget.filterProperties[filter
                                        .key] = BoolFilterProperty(
                                      filter.key,
                                      true,
                                      filterApplyFunction:
                                          filter.filterApplyFunction,
                                    );
                                  });
                                },
                              ),
                              getPill("Ja", Colors.green, true),
                              SizedBox(width: 25),
                              Radio(
                                value: false,
                                groupValue:
                                    ((widget.filterProperties[filter.key])
                                            as BoolFilterProperty?)
                                        ?.value,
                                onChanged: (bool? value) {
                                  setState(() {
                                    widget.filterProperties[filter
                                        .key] = BoolFilterProperty(
                                      filter.key,
                                      false,
                                      filterApplyFunction:
                                          filter.filterApplyFunction,
                                    );
                                  });
                                },
                              ),
                              getPill("Nein", Colors.red, true),
                            ],
                          ),
                        },
                      ],
                    );
                  }).toList(),
            ),
            const SizedBox(height: 30),
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
