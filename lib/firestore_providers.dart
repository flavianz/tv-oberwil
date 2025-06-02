import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final userListControllerProvider = StateNotifierProvider<
  UserListController,
  AsyncValue<List<DocumentSnapshot>>
>((ref) => UserListController(ref));

class UserListController
    extends StateNotifier<AsyncValue<List<DocumentSnapshot>>> {
  final Ref ref;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoading = false;
  List<DocumentSnapshot> _allDocs = [];

  UserListController(this.ref) : super(const AsyncLoading()) {
    fetchInitial();
  }

  final int querySizeLimit = 10;

  Future<void> fetchInitial() async {
    _lastDoc = null;
    _hasMore = true;
    _allDocs = [];
    _isLoading = true;
    state = const AsyncLoading();

    final query = ref.read(searchQueryProvider).trim();
    final snapshot = await _fetchQuery(query, null);

    _allDocs = snapshot.docs;
    _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    _hasMore = snapshot.size == querySizeLimit;

    state = AsyncData(_allDocs);
    _isLoading = false;
  }

  Future<void> fetchMore() async {
    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    final query = ref.read(searchQueryProvider).trim();
    final snapshot = await _fetchQuery(query, _lastDoc);
    final newDocs = snapshot.docs;

    if (newDocs.isNotEmpty) {
      _lastDoc = newDocs.last;
      _allDocs.addAll(newDocs);
      state = AsyncData([..._allDocs]);
    }

    _hasMore = newDocs.length == querySizeLimit;
    _isLoading = false;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _fetchQuery(
    String query,
    DocumentSnapshot? startAfter,
  ) {
    Query<Map<String, dynamic>> firestoreQuery = FirebaseFirestore.instance
        .collection('members')
        .where(
          Filter.or(
            Filter.and(
              Filter('search_first', isGreaterThanOrEqualTo: searchify(query)),
              Filter('search_first', isLessThan: searchify('${query}zz')),
            ),
            Filter.and(
              Filter('search_last', isGreaterThanOrEqualTo: searchify(query)),
              Filter('search_last', isLessThan: searchify('${query}zz')),
            ),
          ),
        )
        .orderBy("search_last")
        .orderBy("search_first")
        .limit(querySizeLimit);

    if (startAfter != null) {
      firestoreQuery = firestoreQuery.startAfterDocument(startAfter);
    }

    return firestoreQuery.get();
  }

  bool get isLoading => _isLoading;

  bool get hasMore => _hasMore;
}

String searchify(String str) {
  return str
      .toLowerCase()
      .replaceAll("ö", "oe")
      .replaceAll("ä", "ae")
      .replaceAll("ü", "ue");
}
