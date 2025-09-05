import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tv_oberwil/firestore_providers/basic_providers.dart';

CollectionProvider paginatedListProvider(
  Query<Map<String, dynamic>> query,
  String collectionKey,
) {
  return CollectionProvider(
    (ref) => RealtimeCollectionProvider(query, collectionKey),
  );
}

class RealtimeCollectionProvider
    extends StateNotifier<AsyncValue<List<DocumentSnapshot>>> {
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
      print("loading collection $collectionKey from server");
      await query
          .get()
          .then((fetchedCollection) {
            state = AsyncData(fetchedCollection.docs);
            print(
              "loaded ${fetchedCollection.docs.length} docs in $collectionKey from server",
            );
            prefs.setInt(collectionKey, DateTime.now().millisecondsSinceEpoch);
            lastFetched = DateTime.now().millisecondsSinceEpoch;
          })
          .onError((error, stackTrace) {
            state = AsyncError(error ?? {}, stackTrace);
          });
    } else {
      print(
        "last fetched $collectionKey at ${DateTime.fromMillisecondsSinceEpoch(lastFetched).toString()}",
      );
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
              print(
                "received ${fetchedCollection.docChanges.length} new docs in $collectionKey from server but local data did not exist",
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
            print(
              "received ${fetchedCollection.docChanges.length} new docs in $collectionKey from server via snapshot listener",
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

StreamProvider<DocumentSnapshot<Object?>?> getDocFromLiveCollection(
  String collectionKey,
  DocumentReference<Map<String, dynamic>> doc,
) {
  if (collectionProviders.containsKey(collectionKey)) {
    return StreamProvider((ref) {
      return ref
          .watch(collectionProviders[collectionKey]!.notifier)
          .stream
          .map(
            (value) => value.whenOrNull(
              data: (data) {
                final modelIndex = data.indexWhere(
                  (entry) => entry.id == doc.id,
                );
                if (modelIndex == -1) {
                  return null;
                }
                return data[modelIndex];
              },
            ),
          );
    });
  } else {
    return realtimeDocProvider(doc);
  }
}
