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

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => MembersScreenState();
}

final textControllerProvider = Provider<TextEditingController>((ref) {
  return TextEditingController();
});

class MembersScreenState extends ConsumerState<MembersScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // auto-fetching more
    /*_scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        ref.read(userListControllerProvider.notifier).fetchMore();
      }
    });*/
  }

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
              },
              icon: Icon(Icons.add),
              label: Text("Mitglied hinzufügen"),
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
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('This is a typical dialog.'),
                                      const SizedBox(height: 15),
                                      TextButton(
                                        onPressed: () {
                                          context.pop();
                                        },
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
