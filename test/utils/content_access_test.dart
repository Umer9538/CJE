import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:cje/core/repositories/content_access.dart';

String encodeFilter(Object? value) => jsonEncode(value,
    toEncodable: (object) => object.toString());

void main() {
  for (final collection in [
    'announcements',
    'meetings',
    'polls',
    'initiatives',
    'documents',
  ]) {
    test('$collection keeps all predicates in one composite filter', () {
      final filter = buildContentFilter(
        collectionId: collection,
        uid: 'me',
        profile: {'role': 'student', 'city': 'Sibiu', 'schoolId': 'a'},
      );
      final encoded = encodeFilter(filter!.toJson());
      expect(encoded, contains('countyId'));
      expect(encoded, contains('schoolId'));
      expect(
        encoded,
        contains(collection == 'documents' ? 'isPublic' : 'minVisibilityRole'),
      );
      if (collection == 'announcements') {
        expect(encoded, contains('isPublished'));
      }
      if (collection == 'initiatives') {
        expect(encoded, contains('authorId'));
        expect(encoded, contains('status'));
      }
    });
  }
  test('ordinary user cannot query another county supplied by the caller', () {
    final filter = buildContentFilter(
      collectionId: 'meetings',
      uid: 'me',
      countyId: 'Cluj',
      profile: {'role': 'student', 'city': 'Sibiu', 'schoolId': 'a'},
    );
    expect(encodeFilter(filter!.toJson()), isNot(contains('Cluj')));
  });
  test('superadmin national view has no audience filter', () {
    expect(
      buildContentFilter(
        collectionId: 'meetings',
        uid: 'me',
        profile: {'role': 'superadmin'},
      ),
      isNull,
    );
  });
  test('BEX retains all county documents', () {
    final filter = buildContentFilter(
      collectionId: 'documents',
      uid: 'me',
      profile: {'role': 'bex', 'city': 'Sibiu'},
    );
    final encoded = encodeFilter(filter!.toJson());
    expect(encoded, contains('countyId'));
    expect(encoded, isNot(contains('minimumRole')));
    expect(encoded, isNot(contains('schoolId')));
  });
}
