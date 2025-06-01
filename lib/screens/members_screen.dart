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
  ConsumerState<MembersScreen> createState() =>
      _FirestoreInfiniteScrollPageState();
}

final textControllerProvider = Provider<TextEditingController>((ref) {
  return TextEditingController();
});

class _FirestoreInfiniteScrollPageState extends ConsumerState<MembersScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        ref.read(userListControllerProvider.notifier).fetchMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncDocs = ref.watch(userListControllerProvider);
    final query = ref.watch(searchQueryProvider);

    final searchController = ref.watch(textControllerProvider);

    void handleSearchSubmit(String value) {
      ref.read(searchQueryProvider.notifier).state = value;
      ref.read(userListControllerProvider.notifier).fetchInitial();
    }

    final isTablet = MediaQuery.of(context).size.aspectRatio > 1;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 35 : 0,
        vertical: 15,
      ),
      child: Scaffold(
        appBar: AppBar(
          actionsPadding: EdgeInsets.all(12),
          title: Text("Mitglieder"),
          actions: [
            FilledButton.icon(
              onPressed: () {},
              icon: Icon(Icons.add),
              label: Text("Mitglied hinzufügen"),
              style: FilledButton.styleFrom(minimumSize: Size(10, 55)),
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
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
                        return GestureDetector(
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
