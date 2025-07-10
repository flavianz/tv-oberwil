import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

StateNotifierProvider<UserListController, AsyncValue<List<DocumentSnapshot>>>
paginatedListProvider(
  Query<Map<String, dynamic>> collection,
  String orderBy, [
  int maxQuerySize = 10,
]) {
  return StateNotifierProvider<
    UserListController,
    AsyncValue<List<DocumentSnapshot>>
  >((ref) => UserListController(ref, collection, orderBy, maxQuerySize));
}

class UserListController
    extends StateNotifier<AsyncValue<List<DocumentSnapshot>>> {
  final Query<Map<String, dynamic>> collection;
  final String orderBy;
  final int maxQuerySize;

  final Ref ref;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoading = false;
  List<DocumentSnapshot> _allDocs = [];

  UserListController(this.ref, this.collection, this.orderBy, this.maxQuerySize)
    : super(const AsyncLoading()) {
    fetchInitial();
  }

  Future<void> fetchInitial() async {
    _lastDoc = null;
    _hasMore = true;
    _allDocs = [];
    _isLoading = true;
    state = const AsyncLoading();

    final snapshot = await _fetchQuery(null);
    _allDocs = snapshot.docs;
    _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    _hasMore = snapshot.size == maxQuerySize;

    state = AsyncData(_allDocs);
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
    Query<Map<String, dynamic>> firestoreQuery = collection
        .orderBy(orderBy)
        .limit(maxQuerySize);

    if (startAfter != null) {
      firestoreQuery = firestoreQuery.startAfterDocument(startAfter);
    }

    return firestoreQuery.get();
  }

  bool get isLoading => _isLoading;

  bool get hasMore => _hasMore;
}
