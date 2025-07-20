import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tv_oberwil/firestore_providers/paginated_list_proivder.dart';

class PaginatedList extends ConsumerStatefulWidget {
  final Widget Function(DocumentSnapshot<Object?>) builder;
  final Query<Map<String, dynamic>> query;
  final int maxQueryLimit;
  final bool divider;

  void refresh() {}

  const PaginatedList({
    super.key,
    required this.builder,
    required this.query,
    this.maxQueryLimit = 10,
    this.divider = false,
  });

  @override
  ConsumerState<PaginatedList> createState() => _PaginatedListState();
}

class PaginatedParams {
  final Query<Map<String, dynamic>> query;
  final int maxQuerySize;

  const PaginatedParams(this.query, this.maxQuerySize);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaginatedParams &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          maxQuerySize == other.maxQuerySize;

  @override
  int get hashCode => query.hashCode ^ maxQuerySize.hashCode;
}

final paginatedListProvider = StateNotifierProvider.autoDispose.family<
  UserListController,
  AsyncValue<List<DocumentSnapshot>>,
  PaginatedParams
>((ref, params) => UserListController(ref, params.query, params.maxQuerySize));

class _PaginatedListState extends ConsumerState<PaginatedList> {
  @override
  Widget build(BuildContext context) {
    final provider = paginatedListProvider(
      PaginatedParams(widget.query, widget.maxQueryLimit),
    );
    final docs = ref.watch(provider);
    return docs.when(
      data: (data) {
        if (data.isEmpty) {
          return const Center(child: Text('Nichts gefunden!'));
        }
        final controller = ref.read(provider.notifier);
        return ListView(
          children:
              data.map((doc) => widget.builder(doc)).toList()..add(
                controller.isLoading
                    ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                    : controller.hasMore
                    ? FilledButton.icon(
                      onPressed: () {
                        ref.read(provider.notifier).fetchMore();
                      },
                      label: Text("Mehr laden"),
                      icon: Icon(Icons.add),
                    )
                    : Container(),
              ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
