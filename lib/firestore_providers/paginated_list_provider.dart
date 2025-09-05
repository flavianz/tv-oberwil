import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/misc.dart';

CollectionProvider paginatedListProvider(
  Query<Map<String, dynamic>> query,
  String collectionKey,
) {
  return CollectionProvider(
    (ref) => RealtimeCollectionProvider(query, collectionKey),
  );
}

class RealtimeCollectionProvider
    extends
        StateNotifier<
          AsyncValue<List<DocumentSnapshot<Map<String, dynamic>>>>
        > {
  final Query<Map<String, dynamic>> query;
  final String collectionKey;
  bool isLoading = true;

  RealtimeCollectionProvider(this.query, this.collectionKey)
    : super(AsyncLoading()) {
    init();
  }

  void init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    int? lastFetched = prefs.getInt(collectionKey);
    if (lastFetched == null) {
      await query
          .get()
          .then((fetchedCollection) {
            state = AsyncData(fetchedCollection.docs);
            printServer(
              "${fetchedCollection.docs.length} docs in $collectionKey",
            );
            prefs.setInt(collectionKey, DateTime.now().millisecondsSinceEpoch);
            lastFetched = DateTime.now().millisecondsSinceEpoch;
          })
          .onError((error, stackTrace) {
            state = AsyncError(error ?? {}, stackTrace);
          });
    } else {
      await query
          .get(GetOptions(source: Source.cache))
          .then((fetchedCollection) {
            printCache(
              "${fetchedCollection.docs.length} docs in $collectionKey",
            );

            state = AsyncData(fetchedCollection.docs);
          })
          .onError((error, stackTrace) {
            state = AsyncError(error ?? {}, stackTrace);
          });
    }
    query
        .where(
          "lU",
          isGreaterThanOrEqualTo: Timestamp.fromMillisecondsSinceEpoch(
            lastFetched!,
          ),
        )
        .snapshots()
        .listen(
          (fetchedCollection) {
            if (!state.hasValue) {
              printServer(
                "${fetchedCollection.docChanges.length} new docs in $collectionKey, but local data did not exist",
              );
              return;
            }

            final mergedList = [...state.value!];
            for (final addedDoc in fetchedCollection.docChanges) {
              mergedList
                ..removeWhere((doc) => doc.id == addedDoc.doc.id)
                ..add(addedDoc.doc);
            }
            state = AsyncData(mergedList);
            printServer(
              "${fetchedCollection.docChanges.length} new docs in $collectionKey",
            );
            if (fetchedCollection.docChanges.isNotEmpty) {
              prefs.setInt(
                collectionKey,
                (fetchedCollection.docChanges[0].doc.get("lU") as Timestamp)
                    .millisecondsSinceEpoch,
              );
            } else {
              prefs.setInt(
                collectionKey,
                DateTime.now().millisecondsSinceEpoch,
              );
            }
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
      RealtimeCollectionProvider,
      AsyncValue<List<DocumentSnapshot<Map<String, dynamic>>>>
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

final docFromLiveCollectionProvider = StreamProvider.family<
  DocumentSnapshot<Map<String, dynamic>>?,
  (String collectionKey, DocumentReference<Map<String, dynamic>> doc)
>((ref, args) {
  final (collectionKey, doc) = args;

  if (collectionProviders.containsKey(collectionKey)) {
    final collectionState = ref.watch(collectionProviders[collectionKey]!);

    return collectionState.when(
      data: (docs) async* {
        final index = docs.indexWhere((entry) => entry.id == doc.id);
        printCache("doc ${doc.path}");
        yield index == -1 ? null : docs[index];
      },
      error: (e, st) async* {
        throw e;
      },
      loading: () async* {
        // Emit nothing while loading
        yield null;
      },
    );
  } else {
    printServer("doc ${doc.path}");
    return doc.snapshots();
  }
});
