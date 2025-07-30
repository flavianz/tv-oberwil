import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

StateNotifierProvider<
  PaginatedListController,
  AsyncValue<List<DocumentSnapshot>>
>
paginatedListProvider(
  Query<Map<String, dynamic>> query,
  String orderBy, [
  int maxQuerySize = 10,
]) {
  return StateNotifierProvider<
    PaginatedListController,
    AsyncValue<List<DocumentSnapshot>>
  >((ref) => PaginatedListController(ref, query, maxQuerySize));
}

class PaginatedListController
    extends StateNotifier<AsyncValue<List<DocumentSnapshot>>> {
  final Query<Map<String, dynamic>> query;
  final int maxQuerySize;

  final Ref ref;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoading = false;
  List<DocumentSnapshot> _allDocs = [];

  PaginatedListController(this.ref, this.query, this.maxQuerySize)
    : super(const AsyncLoading()) {
    fetchInitial();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  StreamSubscription? _subscription;

  Future<void> fetchInitial() async {
    _lastDoc = null;
    _hasMore = true;
    _allDocs = [];
    _isLoading = true;
    state = const AsyncLoading();

    // Cancel any existing listener
    await _subscription?.cancel();

    Query<Map<String, dynamic>> query = this.query.limit(maxQuerySize);

    _subscription = query.snapshots().listen(
      (snapshot) {
        _allDocs = snapshot.docs;
        _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMore = snapshot.size == maxQuerySize;
        state = AsyncData([..._allDocs]);
      },
      onError: (error, stack) {
        state = AsyncError(error, stack);
      },
    );

    _isLoading = false;
  }

  Future<void> fetchMore() async {
    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    final snapshot = await _fetchQuery(_lastDoc);
    final newDocs = snapshot.docs;

    if (newDocs.isNotEmpty) {
      _lastDoc = newDocs.last;
      _allDocs.addAll(newDocs);
      state = AsyncData([..._allDocs]);
    }

    _hasMore = newDocs.length == maxQuerySize;
    _isLoading = false;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _fetchQuery(
    DocumentSnapshot? startAfter,
  ) {
    Query<Map<String, dynamic>> firestoreQuery = query.limit(maxQuerySize);

    if (startAfter != null) {
      firestoreQuery = firestoreQuery.startAfterDocument(startAfter);
    }

    return firestoreQuery.get();
  }

  bool get isLoading => _isLoading;

  bool get hasMore => _hasMore;
}
