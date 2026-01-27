import 'package:flutter_test/flutter_test.dart';
import 'package:cje/models/poll_model.dart';
import 'package:cje/core/constants/enums.dart';

void main() {
  group('PollModel', () {
    group('isActive', () {
      test('returns true when current time is between startDate and endDate', () {
        final now = DateTime.now();
        final poll = PollModel(
          id: 'test-poll',
          question: 'Test Question',
          type: PollType.county,
          options: [],
          createdById: 'user-1',
          createdByName: 'Test User',
          startDate: now.subtract(const Duration(hours: 1)),
          endDate: now.add(const Duration(hours: 1)),
          createdAt: now,
          updatedAt: now,
        );

        expect(poll.isActive, isTrue);
      });

      test('returns true when current time equals startDate (inclusive start)', () {
        final now = DateTime.now();
        final poll = PollModel(
          id: 'test-poll',
          question: 'Test Question',
          type: PollType.county,
          options: [],
          createdById: 'user-1',
          createdByName: 'Test User',
          startDate: now,
          endDate: now.add(const Duration(hours: 1)),
          createdAt: now,
          updatedAt: now,
        );

        expect(poll.isActive, isTrue);
      });

      test('returns false when current time is before startDate', () {
        final now = DateTime.now();
        final poll = PollModel(
          id: 'test-poll',
          question: 'Test Question',
          type: PollType.county,
          options: [],
          createdById: 'user-1',
          createdByName: 'Test User',
          startDate: now.add(const Duration(hours: 1)),
          endDate: now.add(const Duration(hours: 2)),
          createdAt: now,
          updatedAt: now,
        );

        expect(poll.isActive, isFalse);
      });

      test('returns false when current time is after endDate', () {
        final now = DateTime.now();
        final poll = PollModel(
          id: 'test-poll',
          question: 'Test Question',
          type: PollType.county,
          options: [],
          createdById: 'user-1',
          createdByName: 'Test User',
          startDate: now.subtract(const Duration(hours: 2)),
          endDate: now.subtract(const Duration(hours: 1)),
          createdAt: now,
          updatedAt: now,
        );

        expect(poll.isActive, isFalse);
      });

      test('returns false when current time equals endDate (exclusive end)', () {
        final now = DateTime.now();
        final poll = PollModel(
          id: 'test-poll',
          question: 'Test Question',
          type: PollType.county,
          options: [],
          createdById: 'user-1',
          createdByName: 'Test User',
          startDate: now.subtract(const Duration(hours: 1)),
          endDate: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(poll.isActive, isFalse);
      });
    });

    group('hasEnded', () {
      test('returns true when current time is after endDate', () {
        final now = DateTime.now();
        final poll = PollModel(
          id: 'test-poll',
          question: 'Test Question',
          type: PollType.county,
          options: [],
          createdById: 'user-1',
          createdByName: 'Test User',
          startDate: now.subtract(const Duration(hours: 2)),
          endDate: now.subtract(const Duration(hours: 1)),
          createdAt: now,
          updatedAt: now,
        );

        expect(poll.hasEnded, isTrue);
      });

      test('returns true when current time equals endDate', () {
        final now = DateTime.now();
        final poll = PollModel(
          id: 'test-poll',
          question: 'Test Question',
          type: PollType.county,
          options: [],
          createdById: 'user-1',
          createdByName: 'Test User',
          startDate: now.subtract(const Duration(hours: 1)),
          endDate: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(poll.hasEnded, isTrue);
      });

      test('returns false when current time is before endDate', () {
        final now = DateTime.now();
        final poll = PollModel(
          id: 'test-poll',
          question: 'Test Question',
          type: PollType.county,
          options: [],
          createdById: 'user-1',
          createdByName: 'Test User',
          startDate: now.subtract(const Duration(hours: 1)),
          endDate: now.add(const Duration(hours: 1)),
          createdAt: now,
          updatedAt: now,
        );

        expect(poll.hasEnded, isFalse);
      });
    });

    group('getQuestion', () {
      test('returns translated question when available', () {
        final now = DateTime.now();
        final poll = PollModel(
          id: 'test-poll',
          question: 'Default Question',
          questionTranslations: {'en': 'English Question', 'ro': 'Întrebare Română'},
          type: PollType.county,
          options: [],
          createdById: 'user-1',
          createdByName: 'Test User',
          startDate: now,
          endDate: now.add(const Duration(hours: 1)),
          createdAt: now,
          updatedAt: now,
        );

        expect(poll.getQuestion('en'), equals('English Question'));
        expect(poll.getQuestion('ro'), equals('Întrebare Română'));
      });

      test('returns default question when translation not available', () {
        final now = DateTime.now();
        final poll = PollModel(
          id: 'test-poll',
          question: 'Default Question',
          questionTranslations: {'en': 'English Question'},
          type: PollType.county,
          options: [],
          createdById: 'user-1',
          createdByName: 'Test User',
          startDate: now,
          endDate: now.add(const Duration(hours: 1)),
          createdAt: now,
          updatedAt: now,
        );

        expect(poll.getQuestion('fr'), equals('Default Question'));
      });

      test('returns default question when translations is null', () {
        final now = DateTime.now();
        final poll = PollModel(
          id: 'test-poll',
          question: 'Default Question',
          type: PollType.county,
          options: [],
          createdById: 'user-1',
          createdByName: 'Test User',
          startDate: now,
          endDate: now.add(const Duration(hours: 1)),
          createdAt: now,
          updatedAt: now,
        );

        expect(poll.getQuestion('en'), equals('Default Question'));
      });
    });
  });
}
