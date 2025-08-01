import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tv_oberwil/components/paginated_list.dart';
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

class PaginatedListPage extends StatefulWidget {
  final Widget Function(DocumentSnapshot<Object?>)? builder;
  final Query<Map<String, dynamic>> query;
  final int maxQueryLimit;
  final List<String>? searchFields;
  final bool isFilterable;
  final List<Widget>? actions;
  final String? title;
  final TableOptions? tableOptions;
  final bool showBackButton;
  final bool actionsInSearchBar;

  const PaginatedListPage({
    super.key,
    this.builder,
    required this.query,
    this.title,
    this.maxQueryLimit = 10,
    this.searchFields,
    this.isFilterable = true,
    this.actions,
    this.tableOptions,
    this.showBackButton = true,
    this.actionsInSearchBar = false,
  });

  @override
  State<PaginatedListPage> createState() => _PaginatedListPageState();
}

class _PaginatedListPageState extends State<PaginatedListPage> {
  Query<Map<String, dynamic>>? generatedQuery;
  String? searchText;
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (widget.builder == null && widget.tableOptions == null) {
      throw ErrorDescription("No builder or table specified");
    }
    generatedQuery = widget.query;
    final isScreenWide = MediaQuery.of(context).size.aspectRatio > 1;

    if (widget.searchFields != null &&
        widget.searchFields!.isNotEmpty &&
        searchText != null &&
        searchText!.isNotEmpty) {
      if (widget.searchFields!.length > 2) {
        throw ErrorDescription("Too many search fields");
      }
      List<Filter> filters = [];
      for (final key in widget.searchFields!) {
        filters.add(
          Filter.and(
            Filter(key, isGreaterThanOrEqualTo: searchText),
            Filter(key, isLessThan: "${searchText}zz"),
          ),
        );
      }
      if (filters.length == 1) {
        generatedQuery = generatedQuery!.where(filters[0]);
      } else {
        generatedQuery = generatedQuery!.where(
          Filter.or(filters[0], filters[1]),
        );
      }
    }
    final showAppBar =
        widget.title != null ||
        (widget.actions != null && !widget.actionsInSearchBar);
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
                            suffixIconConstraints: BoxConstraints(),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: TextButton.icon(
                                iconAlignment: IconAlignment.end,
                                onPressed: () {
                                  setState(() {
                                    searchText = searchController.text;
                                  });
                                },
                                icon: Icon(Icons.arrow_forward),
                                label: Text("Suchen"),
                              ),
                            ),
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
                      /*TextButton.icon(
                    onPressed: () {
                      if (isScreenWide) {
                        showDialog<String>(
                          context: context,
                          builder:
                              (BuildContext context) => Dialog(
                                child: FilterDialog(
                                  allTeams: allTeams,
                                  notSelectedTeams: notSelectedTeams,
                                ),
                              ),
                        );
                      } else {
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return FilterDialog(
                              allTeams: allTeams,
                              notSelectedTeams: notSelectedTeams,
                            );
                          },
                        );
                      }
                    },
                    label: Text("Filter"),
                    icon: Icon(Icons.filter_list),
                  ),*/
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
                                                child: column.builder(
                                                  data[column.key],
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
                  query: generatedQuery!,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
