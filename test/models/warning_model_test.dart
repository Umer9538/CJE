import 'package:flutter_test/flutter_test.dart';
import 'package:cje/models/warning_model.dart';

void main() {
  group('WarningModel', () {
    group('isActive', () {
      test('returns true when warning has no expiration date', () {
        final now = DateTime.now();
        final warning = WarningModel(
          id: 'warning-1',
          userId: 'user-1',
          userName: 'Test User',
          type: WarningType.verbal,
          reason: 'Test reason',
          issuedById: 'admin-1',
          issuedByName: 'Admin',
          issuedAt: now.subtract(const Duration(days: 1)),
          isActive: true,
          expiresAt: null,
          countyId: 'Cluj',
        );

        expect(warning.isActive, isTrue);
      });

      test('isActive can be manually set to false', () {
        final now = DateTime.now();
        final warning = WarningModel(
          id: 'warning-1',
          userId: 'user-1',
          userName: 'Test User',
          type: WarningType.verbal,
          reason: 'Test reason',
          issuedById: 'admin-1',
          issuedByName: 'Admin',
          issuedAt: now.subtract(const Duration(days: 1)),
          isActive: false,
          expiresAt: null,
          countyId: 'Cluj',
        );

        expect(warning.isActive, isFalse);
      });
    });

    group('WarningType', () {
      test('displayName returns correct English names (Reprimand)', () {
        expect(WarningType.verbal.displayName, equals('Verbal Reprimand'));
        expect(WarningType.written.displayName, equals('Written Reprimand'));
        expect(WarningType.suspension.displayName, equals('Suspension'));
        expect(WarningType.removal.displayName, equals('Removal'));
      });

      test('displayNameRo returns correct Romanian names (Mustrare)', () {
        expect(WarningType.verbal.displayNameRo, equals('Mustrare Verbală'));
        expect(WarningType.written.displayNameRo, equals('Mustrare Scrisă'));
        expect(WarningType.suspension.displayNameRo, equals('Suspendare'));
        expect(WarningType.removal.displayNameRo, equals('Excludere'));
      });
    });
  });

  group('AbsenceModel', () {
    group('AbsenceType', () {
      test('displayName returns correct English names', () {
        expect(AbsenceType.excused.displayName, equals('Excused'));
        expect(AbsenceType.unexcused.displayName, equals('Unexcused'));
      });

      test('displayNameRo returns correct Romanian names', () {
        expect(AbsenceType.excused.displayNameRo, equals('Motivată'));
        expect(AbsenceType.unexcused.displayNameRo, equals('Nemotivată'));
      });
    });
  });
}
