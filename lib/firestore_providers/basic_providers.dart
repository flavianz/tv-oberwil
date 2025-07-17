import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final realtimeDocProvider = StreamProvider.family<
  DocumentSnapshot<Map<String, dynamic>>,
  DocumentReference<Map<String, dynamic>>
>((ref, DocumentReference<Map<String, dynamic>> docRef) {
  return docRef.snapshots();
});

final realtimeCollectionProvider = StreamProvider.family<
  QuerySnapshot<Map<String, dynamic>>,
  Query<Map<String, dynamic>>
>((ref, Query<Map<String, dynamic>> collectionRef) {
  return collectionRef.snapshots();
});
