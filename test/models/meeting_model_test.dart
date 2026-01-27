import 'package:flutter_test/flutter_test.dart';
import 'package:cje/models/meeting_model.dart';
import 'package:cje/core/constants/enums.dart';

void main() {
  group('MeetingModel', () {
    group('filtering', () {
      test('upcoming meetings filter correctly', () {
        final now = DateTime.now();

        final upcomingMeeting = MeetingModel(
          id: 'upcoming-1',
          title: 'Upcoming Meeting',
          type: MeetingType.countyAG,
          dateTime: now.add(const Duration(hours: 1)),
          durationMinutes: 60,
          location: 'Room A',
          createdById: 'user-1',
          createdByName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );

        final pastMeeting = MeetingModel(
          id: 'past-1',
          title: 'Past Meeting',
          type: MeetingType.countyAG,
          dateTime: now.subtract(const Duration(hours: 1)),
          durationMinutes: 60,
          location: 'Room B',
          createdById: 'user-1',
          createdByName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );

        final meetings = [upcomingMeeting, pastMeeting];

        // Filter for upcoming only
        final upcomingOnly = meetings.where((m) => m.dateTime.isAfter(now)).toList();

        expect(upcomingOnly.length, equals(1));
        expect(upcomingOnly[0].id, equals('upcoming-1'));
      });

      test('past meetings filter correctly', () {
        final now = DateTime.now();

        final upcomingMeeting = MeetingModel(
          id: 'upcoming-1',
          title: 'Upcoming Meeting',
          type: MeetingType.countyAG,
          dateTime: now.add(const Duration(hours: 1)),
          durationMinutes: 60,
          location: 'Room A',
          createdById: 'user-1',
          createdByName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );

        final pastMeeting = MeetingModel(
          id: 'past-1',
          title: 'Past Meeting',
          type: MeetingType.countyAG,
          dateTime: now.subtract(const Duration(hours: 1)),
          durationMinutes: 60,
          location: 'Room B',
          createdById: 'user-1',
          createdByName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );

        final meetings = [upcomingMeeting, pastMeeting];

        // Filter for past only
        final pastOnly = meetings.where((m) => m.dateTime.isBefore(now)).toList();

        expect(pastOnly.length, equals(1));
        expect(pastOnly[0].id, equals('past-1'));
      });
    });

    group('sorting', () {
      test('upcoming meetings sort by dateTime ascending (soonest first)', () {
        final now = DateTime.now();

        final soonerMeeting = MeetingModel(
          id: 'sooner-1',
          title: 'Sooner Meeting',
          type: MeetingType.countyAG,
          dateTime: now.add(const Duration(hours: 1)),
          durationMinutes: 60,
          location: 'Room A',
          createdById: 'user-1',
          createdByName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );

        final laterMeeting = MeetingModel(
          id: 'later-1',
          title: 'Later Meeting',
          type: MeetingType.countyAG,
          dateTime: now.add(const Duration(hours: 5)),
          durationMinutes: 60,
          location: 'Room B',
          createdById: 'user-1',
          createdByName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );

        final meetings = [laterMeeting, soonerMeeting];

        // Sort ascending (soonest first)
        meetings.sort((a, b) => a.dateTime.compareTo(b.dateTime));

        expect(meetings[0].id, equals('sooner-1'));
        expect(meetings[1].id, equals('later-1'));
      });

      test('past meetings sort by dateTime descending (most recent first)', () {
        final now = DateTime.now();

        final recentPast = MeetingModel(
          id: 'recent-1',
          title: 'Recent Past Meeting',
          type: MeetingType.countyAG,
          dateTime: now.subtract(const Duration(hours: 1)),
          durationMinutes: 60,
          location: 'Room A',
          createdById: 'user-1',
          createdByName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );

        final olderPast = MeetingModel(
          id: 'older-1',
          title: 'Older Past Meeting',
          type: MeetingType.countyAG,
          dateTime: now.subtract(const Duration(hours: 5)),
          durationMinutes: 60,
          location: 'Room B',
          createdById: 'user-1',
          createdByName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );

        final meetings = [olderPast, recentPast];

        // Sort descending (most recent first)
        meetings.sort((a, b) => b.dateTime.compareTo(a.dateTime));

        expect(meetings[0].id, equals('recent-1'));
        expect(meetings[1].id, equals('older-1'));
      });
    });

    group('getDescription', () {
      test('returns translated description when available', () {
        final now = DateTime.now();
        final meeting = MeetingModel(
          id: 'meeting-1',
          title: 'Test Meeting',
          description: 'Default description',
          descriptionTranslations: {'en': 'English description', 'ro': 'Descriere română'},
          type: MeetingType.countyAG,
          dateTime: now.add(const Duration(hours: 1)),
          durationMinutes: 60,
          location: 'Room A',
          createdById: 'user-1',
          createdByName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );

        expect(meeting.getDescription('en'), equals('English description'));
        expect(meeting.getDescription('ro'), equals('Descriere română'));
      });

      test('returns default description when translation not available', () {
        final now = DateTime.now();
        final meeting = MeetingModel(
          id: 'meeting-1',
          title: 'Test Meeting',
          description: 'Default description',
          descriptionTranslations: {'ro': 'Doar română'},
          type: MeetingType.countyAG,
          dateTime: now.add(const Duration(hours: 1)),
          durationMinutes: 60,
          location: 'Room A',
          createdById: 'user-1',
          createdByName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );

        // When translation for 'en' is not in map, falls back to default description
        expect(meeting.getDescription('en'), equals('Default description'));
      });

      test('returns description when no translations map', () {
        final now = DateTime.now();
        final meeting = MeetingModel(
          id: 'meeting-1',
          title: 'Test Meeting',
          description: 'Default description',
          type: MeetingType.countyAG,
          dateTime: now.add(const Duration(hours: 1)),
          durationMinutes: 60,
          location: 'Room A',
          createdById: 'user-1',
          createdByName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );

        expect(meeting.getDescription('en'), equals('Default description'));
      });

      test('returns null when no description at all', () {
        final now = DateTime.now();
        final meeting = MeetingModel(
          id: 'meeting-1',
          title: 'Test Meeting',
          type: MeetingType.countyAG,
          dateTime: now.add(const Duration(hours: 1)),
          durationMinutes: 60,
          location: 'Room A',
          createdById: 'user-1',
          createdByName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );

        expect(meeting.getDescription('en'), isNull);
      });
    });
  });
}
