import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/enums.dart';

/// Build ONE composite filter. In this FlutterFire version, repeated
/// where(Filter.or(...)) calls replace the preceding composite filter.
Filter? buildContentFilter({
  required String collectionId,
  required String uid,
  required Map<String, dynamic> profile,
  String? countyId,
  bool draftsOnly = false,
}) {
  final role = UserRole.fromFirestore(profile['role'] as String? ?? 'student');
  final filters = <Filter>[];
  final county = role == UserRole.superadmin ? countyId : profile['city'];
  if (county != null && county.toString().isNotEmpty) {
    filters.add(Filter('countyId', isEqualTo: county));
  }
  if (role != UserRole.superadmin) {
    final visible = UserRole.values
        .where((r) => r.hierarchyLevel <= role.hierarchyLevel)
        .map((r) => r.name)
        .toList();
    if (!(collectionId == 'documents' && role == UserRole.bex)) {
      filters.add(
        collectionId == 'documents'
            ? Filter.or(
                Filter('isPublic', isEqualTo: true),
                Filter('minimumRole', whereIn: visible),
              )
            : Filter.or(
                Filter('minVisibilityRole', isNull: true),
                Filter('minVisibilityRole', whereIn: visible),
              ),
      );
    }
    if (role != UserRole.bex) {
      final school = profile['schoolId'];
      filters.add(
        school == null
            ? Filter('schoolId', isNull: true)
            : Filter.or(
                Filter('schoolId', isNull: true),
                Filter('schoolId', isEqualTo: school),
              ),
      );
    }
    if (collectionId == 'initiatives' && role != UserRole.bex) {
      final draftFilters = <Filter>[
        Filter('status', isNotEqualTo: 'draft'),
        Filter('authorId', isEqualTo: uid),
      ];
      if (role == UserRole.schoolRep && profile['schoolId'] != null) {
        draftFilters.add(Filter('schoolId', isEqualTo: profile['schoolId']));
      }
      filters.add(
        draftFilters.length == 3
            ? Filter.or(draftFilters[0], draftFilters[1], draftFilters[2])
            : Filter.or(draftFilters[0], draftFilters[1]),
      );
    }
  }
  if (collectionId == 'announcements') {
    filters.add(Filter('isPublished', isEqualTo: !draftsOnly));
    if (draftsOnly) filters.add(Filter('authorId', isEqualTo: uid));
  }
  return filters.isEmpty
      ? null
      : filters.reduce((left, right) => Filter.and(left, right));
}

/// Put authorization predicates into the query before downloading content.
class ContentAccess {
  final FirebaseFirestore firestore;
  ContentAccess(this.firestore);

  Future<Query<Map<String, dynamic>>> query(
    CollectionReference<Map<String, dynamic>> collection, {
    String? countyId,
    bool draftsOnly = false,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Authentication required');
    final profile = (await firestore.collection('users').doc(uid).get()).data();
    if (profile == null) throw StateError('Account profile required');
    final filter = buildContentFilter(
      collectionId: collection.id,
      uid: uid,
      profile: profile,
      countyId: countyId,
      draftsOnly: draftsOnly,
    );
    return filter == null ? collection : collection.where(filter);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots(
    CollectionReference<Map<String, dynamic>> collection, {
    String? countyId,
  }) async* {
    final scoped = await query(collection, countyId: countyId);
    yield* scoped.snapshots();
  }
}
