import 'package:flutter_test/flutter_test.dart';

/// Tests for the canonical county matching enforced by Firestore queries/rules.
void main() {
  group('County Filtering Logic', () {
    // Both values must exist and match the canonical county name exactly.
    bool countyMatches(String? userCounty, String? contentCounty) {
      if (contentCounty == null || contentCounty.isEmpty) return false;
      if (userCounty == null || userCounty.isEmpty) return false;
      return userCounty == contentCounty;
    }

    test('content with null countyId is blocked until migration', () {
      expect(countyMatches('Cluj', null), isFalse);
      expect(countyMatches('Sibiu', null), isFalse);
      expect(countyMatches(null, null), isFalse);
    });

    test('content with empty countyId is blocked until migration', () {
      expect(countyMatches('Cluj', ''), isFalse);
      expect(countyMatches('Sibiu', ''), isFalse);
    });

    test('exact match works', () {
      expect(countyMatches('Cluj', 'Cluj'), isTrue);
      expect(countyMatches('Sibiu', 'Sibiu'), isTrue);
    });

    test('a city name is not accepted as a county alias', () {
      expect(countyMatches('Cluj-Napoca', 'Cluj'), isFalse);
      expect(countyMatches('Bistrița-Năsăud', 'Bistrița'), isFalse);
    });

    test('partial county names do not match', () {
      expect(countyMatches('Cluj', 'Cluj-Napoca'), isFalse);
      expect(countyMatches('Bistrița', 'Bistrița-Năsăud'), isFalse);
    });

    test('non-canonical casing does not match', () {
      expect(countyMatches('CLUJ', 'cluj'), isFalse);
      expect(countyMatches('cluj', 'CLUJ'), isFalse);
      expect(countyMatches('Cluj-Napoca', 'CLUJ'), isFalse);
    });

    test('non-matching counties return false', () {
      expect(countyMatches('Cluj', 'Sibiu'), isFalse);
      expect(countyMatches('Sibiu', 'Cluj'), isFalse);
      expect(countyMatches('București', 'Cluj'), isFalse);
    });

    test('user with null county cannot see county-specific content', () {
      expect(countyMatches(null, 'Cluj'), isFalse);
      expect(countyMatches('', 'Cluj'), isFalse);
    });
  });

  group('School Filtering Logic', () {
    // For school-specific content:
    // - County-level content (schoolId == null) is visible to all in county
    // - School-specific content is only visible to users from that school

    bool schoolMatches(String? userSchoolId, String? contentSchoolId) {
      // County-level content (no school) is visible to all
      if (contentSchoolId == null) return true;
      // User must be from the same school to see school-specific content
      return userSchoolId == contentSchoolId;
    }

    test('county-level content (null schoolId) is visible to all', () {
      expect(schoolMatches('school-1', null), isTrue);
      expect(schoolMatches('school-2', null), isTrue);
      expect(schoolMatches(null, null), isTrue);
    });

    test('school-specific content is visible only to same school', () {
      expect(schoolMatches('school-1', 'school-1'), isTrue);
      expect(schoolMatches('school-2', 'school-2'), isTrue);
    });

    test('school-specific content is not visible to other schools', () {
      expect(schoolMatches('school-1', 'school-2'), isFalse);
      expect(schoolMatches('school-2', 'school-1'), isFalse);
    });

    test('user without school cannot see school-specific content', () {
      expect(schoolMatches(null, 'school-1'), isFalse);
    });
  });
}
