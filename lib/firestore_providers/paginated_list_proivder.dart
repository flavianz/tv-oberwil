import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

CollectionProvider paginatedListProvider(
  Query<Map<String, dynamic>> query,
  String collectionKey,
) {
  return StateNotifierProvider<
    PaginatedListController,
    AsyncValue<List<DocumentSnapshot>>
  >((ref) => PaginatedListController(query, collectionKey));
}

class PaginatedListController
    extends StateNotifier<AsyncValue<List<DocumentSnapshot>>> {
  final Query<Map<String, dynamic>> query;
  final String collectionKey;
  bool isLoading = true;

  PaginatedListController(this.query, this.collectionKey)
    : super(AsyncLoading()) {
    init();
  }

  void init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? lastFetched = prefs.getInt(collectionKey);
    if (lastFetched == null) {
      print("loading collection $collectionKey from server");
      await query
          .get()
          .then((fetchedCollection) {
            state = AsyncData(fetchedCollection.docs);
            print(
              "loaded ${fetchedCollection.docs.length} docs in $collectionKey from server",
            );
            prefs.setInt(collectionKey, DateTime.now().millisecondsSinceEpoch);
          })
          .onError((error, stackTrace) {
            state = AsyncError(error ?? {}, stackTrace);
          });
    } else {
      print("loading collection $collectionKey from cache");
      await query
          .get(GetOptions(source: Source.cache))
          .then((fetchedCollection) {
            print(
              "loaded ${fetchedCollection.docs.length} docs in $collectionKey from cache",
            );
            state = AsyncData(fetchedCollection.docs);
          })
          .onError((error, stackTrace) {
            state = AsyncError(error ?? {}, stackTrace);
          });
    }
    print(
      "last fetched $collectionKey at ${DateTime.fromMillisecondsSinceEpoch(lastFetched!).toString()}",
    );
    query
        .where("lU", isGreaterThanOrEqualTo: lastFetched)
        .snapshots()
        .listen(
          (fetchedCollection) {
            if (!state.hasValue) {
              print(
                "received ${fetchedCollection.size} new docs in $collectionKey from server but local data did not exist",
              );
              return;
            }

            final mergedList = state.value!;
            for (final addedDoc in fetchedCollection.docs) {
              mergedList
                ..removeWhere((doc) => doc.id == addedDoc.id)
                ..add(addedDoc);
            }
            state = AsyncData(mergedList);
            print(
              "received ${fetchedCollection.docChanges.length} new docs in $collectionKey from server via snapshot listener",
            );
            prefs.setInt(collectionKey, DateTime.now().millisecondsSinceEpoch);
          },
          onError: (error, stackTrace) {
            state = AsyncError(error ?? {}, stackTrace);
          },
        )
        .onDone(() => print("closing snapshot listener to $collectionKey"));
  }
}

typedef CollectionProvider =
    StateNotifierProvider<
      PaginatedListController,
      AsyncValue<List<DocumentSnapshot>>
    >;

final Map<String, CollectionProvider> collectionProviders = {};

CollectionProvider getCollectionProvider(
  String collectionKey,
  Query<Map<String, dynamic>> query,
) {
  if (collectionProviders.containsKey(collectionKey)) {
    return collectionProviders[collectionKey]!;
  } else {
    collectionProviders[collectionKey] = paginatedListProvider(
      query,
      collectionKey,
    );
    return collectionProviders[collectionKey]!;
  }
}
