import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(usersStreamProvider);

    if (data.isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (data.hasError) {
      return Center(child: Text("An error has occurred"));
    }

    return Container(
      padding: EdgeInsets.all(10),
      child: Column(
        children: [
          AppBar(
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
          Expanded(
            child: DataTable(
              rows:
                  data.value!.map((member) {
                    return DataRow(
                      cells: [
                        DataCell(Text("${member["first"]} ${member["last"]}")),
                        DataCell(
                          Row(
                            children:
                                (member["roles"] as List).cast<String>().map((
                                  role,
                                ) {
                                  return Text(role);
                                }).toList(),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
              columns: [
                DataColumn(label: Text("Name")),
                DataColumn(label: Text("Rollen")),
              ],
              dataRowMaxHeight: double.infinity,
            ),
          ),
        ],
      ),
    );
  }
}

class FirestoreInfiniteScrollPage extends ConsumerStatefulWidget {
  const FirestoreInfiniteScrollPage({super.key});

  @override
  ConsumerState<FirestoreInfiniteScrollPage> createState() =>
      _FirestoreInfiniteScrollPageState();
}

class _FirestoreInfiniteScrollPageState
    extends ConsumerState<FirestoreInfiniteScrollPage> {
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

    return Scaffold(
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
              decoration: InputDecoration(
                labelText: 'Suche nach Namen...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: const Icon(Icons.search),
              ),
              onSubmitted: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
                ref.read(userListControllerProvider.notifier).fetchInitial();
              },
            ),
            Expanded(
              child: asyncDocs.when(
                data: (docs) {
                  if (docs.isEmpty) {
                    return const Center(child: Text('No users found.'));
                  }

                  final controller = ref.read(
                    userListControllerProvider.notifier,
                  );
                  final hasMore = controller.hasMore;

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: docs.length + 1,
                    itemBuilder: (context, index) {
                      if (index == docs.length) {
                        return hasMore
                            ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            )
                            : Container();
                      }

                      final data = docs[index].data() as Map<String, dynamic>;
                      return Row(
                        children: [
                          Expanded(child: Text(data['first'] ?? '')),
                          Expanded(child: Text(data['last'] ?? '')),
                        ],
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
