import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../firestore_providers.dart';

final usersStreamProvider = StreamProvider<List<dynamic>>((ref) {
  return FirebaseFirestore.instance.collection('members').snapshots().map((
    snapshot,
  ) {
    return snapshot.docs.map((doc) => doc.data()).toList();
  });
});

final membersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final snapshot = await FirebaseFirestore.instance.collection('members').get();
  return snapshot.docs.map((doc) => doc.data()).toList();
});

final textControllerProvider = Provider<TextEditingController>((ref) {
  return TextEditingController();
});

final memberSummaryProvider = StreamProvider<Map?>((ref) {
  var docRef = FirebaseFirestore.instance.collection('teams').doc("summary");
  return docRef.snapshots().map((doc) => doc.data());
});

class MembersScreen extends ConsumerStatefulWidget {
  final bool refresh;

  const MembersScreen({super.key, required this.refresh});

  @override
  ConsumerState<MembersScreen> createState() => MembersScreenState();
}

class MembersScreenState extends ConsumerState<MembersScreen> {
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
          context.go("/members");
        }
      }).then((_) {});
    }

    final memberSummary = ref.watch(memberSummaryProvider);
    if (memberSummary.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (memberSummary.hasError) {
      return const Center(child: Text("An error occurred"));
    }

    final allTeams =
        (memberSummary.value?["names"] as LinkedHashMap<String, dynamic>)
            .entries
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
          title: Text("Mitglieder"),
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
                FirebaseFirestore.instance.collection("members").add({
                  "first": "Franz",
                  "last": "Triebe",
                  "search_first": "franz",
                  "search_last": "triebe",
                  "birthdate": Timestamp.now(),
                  "teams": {
                    "teamid": {"name": "Junioren Bla", "role": "Spieler"},
                  },
                });
                ref.read(userListControllerProvider.notifier).fetchInitial();
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
                        labelText: 'Suche nach Mitgliedern',
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
                    Expanded(child: Text("Vorname")),
                    Expanded(child: Text("Teams")),
                  ],
                ),
              ),
              Divider(thickness: 2, color: Theme.of(context).primaryColor),
              Expanded(
                child: asyncDocs.when(
                  data: (docs) {
                    if (docs.isEmpty) {
                      return const Center(child: Text('No users found.'));
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
                                  Expanded(child: Text(data['last'] ?? '')),
                                  Expanded(child: Text(data['first'] ?? '')),
                                  Expanded(
                                    child: Row(
                                      spacing: 5,
                                      children:
                                          (List.from(data['teams'] ?? [])).map((
                                            teamId,
                                          ) {
                                            return Text(
                                              (memberSummary.value?["names"]
                                                      as LinkedHashMap<
                                                        String,
                                                        dynamic
                                                      >)[teamId] ??
                                                  "Unknown",
                                            );
                                          }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onTap: () {
                              context.push("/member/${docs[index].id}");
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
    final userData = ref.watch(memberSummaryProvider);
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
}
