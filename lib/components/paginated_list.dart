import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tv_oberwil/firestore_providers/paginated_list_proivder.dart';
import 'package:equatable/equatable.dart';

class PaginatedList extends ConsumerStatefulWidget {
  final Widget Function(DocumentSnapshot<Object?>) builder;
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
    final provider = getCollectionProvider(widget.collectionKey, widget.query);
    final docs = ref.watch(provider);
    return docs.when(
      data: (data) {
        final List<DocumentSnapshot<Object?>> children =
            widget.filter != null
                ? widget.filter!(data).toList()
                : data.toList();
        if (children.isEmpty) {
          return const Center(child: Text('Nichts gefunden!'));
        }
        return ListView.builder(
          itemCount: children.length,
          itemBuilder: (context, index) {
            return widget.builder(children[index]);
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
