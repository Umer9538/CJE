import 'package:flutter_test/flutter_test.dart';

/// Tests for county filtering logic used across repositories
/// The filtering should use flexible matching: "Cluj" matches "Cluj-Napoca" and vice versa
void main() {
  group('County Filtering Logic', () {
    // Helper function that mirrors repository filtering logic
    bool countyMatches(String? userCounty, String? contentCounty) {
      // If content has no county, it's visible to everyone (legacy/global)
      if (contentCounty == null || contentCounty.isEmpty) return true;
      // If user has no county, they can't see county-specific content
      if (userCounty == null || userCounty.isEmpty) return false;

      final userCountyLower = userCounty.toLowerCase();
      final contentCountyLower = contentCounty.toLowerCase();

      // Flexible match: one contains the other
      return userCountyLower.contains(contentCountyLower) ||
          contentCountyLower.contains(userCountyLower);
    }

    test('content with null countyId is visible to everyone', () {
      expect(countyMatches('Cluj', null), isTrue);
      expect(countyMatches('Sibiu', null), isTrue);
      expect(countyMatches(null, null), isTrue);
    });

    test('content with empty countyId is visible to everyone', () {
      expect(countyMatches('Cluj', ''), isTrue);
      expect(countyMatches('Sibiu', ''), isTrue);
    });

    test('exact match works', () {
      expect(countyMatches('Cluj', 'Cluj'), isTrue);
      expect(countyMatches('Sibiu', 'Sibiu'), isTrue);
    });

    test('flexible match - user county contains content county', () {
      expect(countyMatches('Cluj-Napoca', 'Cluj'), isTrue);
      expect(countyMatches('Bistrița-Năsăud', 'Bistrița'), isTrue);
    });

    test('flexible match - content county contains user county', () {
      expect(countyMatches('Cluj', 'Cluj-Napoca'), isTrue);
      expect(countyMatches('Bistrița', 'Bistrița-Năsăud'), isTrue);
    });

    test('case insensitive matching', () {
      expect(countyMatches('CLUJ', 'cluj'), isTrue);
      expect(countyMatches('cluj', 'CLUJ'), isTrue);
      expect(countyMatches('Cluj-Napoca', 'CLUJ'), isTrue);
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
