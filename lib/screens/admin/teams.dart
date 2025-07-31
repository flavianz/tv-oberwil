import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tv_oberwil/components/paginated_list_page.dart';

class TeamsScreen extends StatelessWidget {
  final bool refresh;

  const TeamsScreen({super.key, this.refresh = false});

  @override
  Widget build(BuildContext context) {
    return PaginatedListPage(
      query: FirebaseFirestore.instance.collection("teams"),
      title: "Teams",
      searchFields: ["search_name"],
      tableOptions: TableOptions(
        [
          TableColumn("name", "Name", (data) {
            return Text(data ?? "");
          }, 1),
        ],
        (doc) {
          context.push("/admin/team/${doc.id}");
        },
      ),
    );
  }
}

/*class TeamsScreen extends ConsumerStatefulWidget {
  final bool refresh;

  const TeamsScreen({super.key, required this.refresh});

  @override
  ConsumerState<TeamsScreen> createState() => TeamsScreenState();
}

class TeamsScreenState extends ConsumerState<TeamsScreen> {
  final ScrollController _scrollController = ScrollController();
  List<String> notSelectedTeams = [];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncDocs = ref.watch(userListControllerProvider);

    final searchController = ref.watch(textControllerProvider);

    void handleSearchSubmit(String value) {
      ref.read(searchQueryProvider.notifier).state = value;
      ref.read(userListControllerProvider.notifier).fetchInitial();
    }

    final isScreenWide = MediaQuery.of(context).size.aspectRatio > 1;

    if (widget.refresh) {
      Future(() {
        ref.read(userListControllerProvider.notifier).fetchInitial();
        if (context.mounted) {
          context.go("/admin/teams");
        }
      }).then((_) {});
    }

    final teamSummary = ref.watch(
      realtimeDocProvider(FirebaseFirestore.instance.doc("teams/summary")),
    );
    if (teamSummary.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (teamSummary.hasError) {
      return const Center(child: Text("An error occurred"));
    }

    final allTeams =
        (teamSummary.value?["names"] as LinkedHashMap<String, dynamic>).entries
            .map((entry) => entry.key)
            .toList();

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isScreenWide ? 35 : 0,
        vertical: 15,
      ),
      child: Scaffold(
        appBar: AppBar(
          actionsPadding: EdgeInsets.symmetric(horizontal: 12),
          title: Text("Teams"),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: IconButton(
                onPressed: () {
                  ref.read(userListControllerProvider.notifier).fetchInitial();
                },
                icon: Icon(Icons.refresh),
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                context.go("/admin/team/${generateFirestoreKey()}?create=true");
              },
              icon: Icon(Icons.add),
              label: Text("Neu"),
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: 'Suche nach Teams',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 16, right: 8),
                          child: const Icon(Icons.search),
                        ),
                        prefixIconConstraints: BoxConstraints(),
                        suffixIconConstraints: BoxConstraints(),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: TextButton.icon(
                            iconAlignment: IconAlignment.end,
                            onPressed: () {
                              handleSearchSubmit(searchController.text);
                            },
                            icon: Icon(Icons.arrow_forward),
                            label: Text("Suchen"),
                          ),
                        ),
                      ),
                      onSubmitted: handleSearchSubmit,
                    ),
                  ),
                  TextButton.icon(
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
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 25, bottom: 7),
                child: Row(
                  children: [
                    Expanded(child: Text("Name")),
                    Expanded(child: Text("Art")),
                    Expanded(child: Text("Grösse")),
                  ],
                ),
              ),
              Divider(thickness: 2, color: Theme.of(context).primaryColor),
              Expanded(
                child: asyncDocs.when(
                  data: (docs) {
                    if (docs.isEmpty) {
                      return const Center(child: Text('Keine Teams gefunden'));
                    }

                    final controller = ref.read(
                      userListControllerProvider.notifier,
                    );

                    return ListView.separated(
                      controller: _scrollController,
                      itemCount: docs.length + 1,
                      itemBuilder: (context, index) {
                        if (index == docs.length) {
                          return controller.isLoading
                              ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                              : controller.hasMore
                              ? FilledButton.icon(
                                onPressed: () {
                                  ref
                                      .read(userListControllerProvider.notifier)
                                      .fetchMore();
                                },
                                label: Text("Mehr laden"),
                                icon: Icon(Icons.add),
                              )
                              : Container();
                        }

                        final data = docs[index].data() as Map<String, dynamic>;
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(child: Text(data['name'] ?? '')),
                                  Expanded(child: Text(data['type'] ?? '')),
                                  Expanded(
                                    child: Text(
                                      ((data["players"] ?? []) as List<dynamic>)
                                          .length
                                          .toString(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onTap: () {
                              context.push("/admin/team/${docs[index].id}");
                            },
                          ),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return Divider();
                      },
                    );
                  },
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FilterDialog extends ConsumerStatefulWidget {
  final List<String> allTeams;
  final List<String> notSelectedTeams;

  const FilterDialog({
    super.key,
    required this.allTeams,
    required this.notSelectedTeams,
  });

  @override
  _FilterDialogState createState() => _FilterDialogState();
}

class _FilterDialogState extends ConsumerState<FilterDialog> {
  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(
      realtimeDocProvider(FirebaseFirestore.instance.doc("teams/summary")),
    );
    if (userData.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (userData.hasError) {
      return const Center(child: Text("An error occurred"));
    }

    final allTeams =
        (userData.value?["names"] as LinkedHashMap<String, dynamic>).entries
            .map((entry) => entry.key)
            .toList();

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
              children: [
                Row(
                  children: const [
                    Icon(Icons.people_alt),
                    SizedBox(width: 16),
                    Text("Teams"),
                  ],
                ),
                Divider(color: Theme.of(context).dividerColor),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: Text("Alle"),
                      onSelected: (isNowActive) {
                        setState(() {
                          if (isNowActive) {
                            widget.notSelectedTeams.clear();
                          } else {
                            widget.notSelectedTeams.clear();
                            widget.notSelectedTeams.addAll(allTeams);
                          }
                        });
                      },
                      selected: widget.notSelectedTeams.isEmpty,
                    ),
                    ...(userData.value?["names"]
                            as LinkedHashMap<String, dynamic>)
                        .entries
                        .map((entry) {
                          return FilterChip(
                            label: Text(entry.value),
                            onSelected: (isNowActive) {
                              setState(() {
                                if (isNowActive) {
                                  widget.notSelectedTeams.remove(entry.key);
                                } else {
                                  widget.notSelectedTeams.add(entry.key);
                                }
                              });
                            },
                            selected:
                                !widget.notSelectedTeams.contains(entry.key),
                          );
                        }),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => context.pop(),
                  icon: Icon(Icons.close),
                  label: const Text('Abbrechen'),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: () {
                    context.pop();
                    ref.read(teamsFilterProvider.notifier).state =
                        allTeams.where((id) {
                          return !widget.notSelectedTeams.contains(id);
                        }).toList();
                    ref
                        .read(userListControllerProvider.notifier)
                        .fetchInitial();
                  },
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
}*/
