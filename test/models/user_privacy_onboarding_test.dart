import 'package:cje/core/constants/app_strings.dart';
import 'package:cje/core/constants/enums.dart';
import 'package:cje/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

UserModel _user({
  String? noticeVersion = AppStrings.privacyNoticeVersion,
  DateTime? acknowledgedAt,
  bool? isUnder16 = false,
  String? termsVersion = AppStrings.termsVersion,
}) {
  final now = DateTime(2026, 9, 29);
  return UserModel(
    id: 'user-1',
    email: 'test@example.com',
    fullName: 'Test User',
    city: 'Sibiu',
    role: UserRole.student,
    status: UserStatus.pending,
    createdAt: now,
    updatedAt: now,
    privacyNoticeVersion: noticeVersion,
    privacyNoticeAcknowledgedAt: acknowledgedAt,
    isUnder16: isUnder16,
    termsVersion: termsVersion,
    termsAcceptedAt: acknowledgedAt,
  );
}

void main() {
  group('UserModel.needsPrivacyOnboarding', () {
    test('este fals după confirmarea versiunii curente și a vârstei', () {
      final user = _user(acknowledgedAt: DateTime(2026, 9, 29));
      expect(user.needsPrivacyOnboarding, isFalse);
    });

    test('este adevărat pentru un cont importat fără confirmare', () {
      final user = _user(
        noticeVersion: null,
        acknowledgedAt: null,
        isUnder16: null,
      );
      expect(user.needsPrivacyOnboarding, isTrue);
    });

    test('este adevărat când politica confirmată nu mai este cea curentă', () {
      final user = _user(
        noticeVersion: '2025-01-01',
        acknowledgedAt: DateTime(2025, 1, 1),
      );
      expect(user.needsPrivacyOnboarding, isTrue);
    });

    test('termenii trebuie acceptați personal în versiunea curentă', () {
      final user = _user(
        acknowledgedAt: DateTime(2026, 9, 30),
        termsVersion: null,
      );
      expect(user.needsPrivacyOnboarding, isTrue);
      final outdated = _user(
        acknowledgedAt: DateTime(2026, 9, 30),
        termsVersion: '2025-01-01',
      );
      expect(outdated.needsPrivacyOnboarding, isTrue);
    });

    test('lista de utilizatori blocați este păstrată de copyWith', () {
      final user = _user(
        acknowledgedAt: DateTime(2026, 9, 30),
      ).copyWith(blockedUsers: ['blocked-1']);
      expect(user.copyWith(fullName: 'Updated').blockedUsers, ['blocked-1']);
      expect(user.toFirestore()['blockedUsers'], ['blocked-1']);
    });
  });
}
