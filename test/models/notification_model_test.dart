import 'package:flutter_test/flutter_test.dart';
import 'package:cje/models/notification_model.dart';
import 'package:cje/core/constants/enums.dart';

void main() {
  group('NotificationModel', () {
    group('targetRoute', () {
      test('returns correct route for meeting reminder', () {
        final notification = NotificationModel(
          id: 'notif-1',
          userId: 'user-1',
          type: NotificationType.meetingReminder,
          title: 'Meeting Reminder',
          body: 'You have a meeting',
          data: {'meetingId': 'meeting-123'},
          createdAt: DateTime.now(),
        );

        expect(notification.targetRoute, equals('/meetings/meeting-123'));
      });

      test('returns correct route for new announcement', () {
        final notification = NotificationModel(
          id: 'notif-1',
          userId: 'user-1',
          type: NotificationType.newAnnouncement,
          title: 'New Announcement',
          body: 'Check it out',
          data: {'announcementId': 'announcement-123'},
          createdAt: DateTime.now(),
        );

        expect(notification.targetRoute, equals('/announcements/announcement-123'));
      });

      test('returns correct route for initiative update', () {
        final notification = NotificationModel(
          id: 'notif-1',
          userId: 'user-1',
          type: NotificationType.initiativeUpdate,
          title: 'Initiative Update',
          body: 'Status changed',
          data: {'initiativeId': 'initiative-123'},
          createdAt: DateTime.now(),
        );

        expect(notification.targetRoute, equals('/initiatives/initiative-123'));
      });

      test('returns correct route for poll reminder', () {
        final notification = NotificationModel(
          id: 'notif-1',
          userId: 'user-1',
          type: NotificationType.pollReminder,
          title: 'Poll Reminder',
          body: 'Vote now',
          data: {'pollId': 'poll-123'},
          createdAt: DateTime.now(),
        );

        expect(notification.targetRoute, equals('/polls/poll-123'));
      });

      test('returns correct route for warning issued', () {
        final notification = NotificationModel(
          id: 'notif-1',
          userId: 'user-1',
          type: NotificationType.warningIssued,
          title: 'Warning Issued',
          body: 'You received a warning',
          data: {'warningType': 'verbal'},
          createdAt: DateTime.now(),
        );

        expect(notification.targetRoute, equals('/my-warnings'));
      });

      test('returns correct route for absence recorded', () {
        final notification = NotificationModel(
          id: 'notif-1',
          userId: 'user-1',
          type: NotificationType.absenceRecorded,
          title: 'Absence Recorded',
          body: 'Unexcused absence',
          data: {'meetingTitle': 'Meeting'},
          createdAt: DateTime.now(),
        );

        expect(notification.targetRoute, equals('/my-warnings'));
      });

      test('returns null for system alert', () {
        final notification = NotificationModel(
          id: 'notif-1',
          userId: 'user-1',
          type: NotificationType.systemAlert,
          title: 'System Alert',
          body: 'System message',
          data: {},
          createdAt: DateTime.now(),
        );

        expect(notification.targetRoute, isNull);
      });

      test('returns null when data is null', () {
        final notification = NotificationModel(
          id: 'notif-1',
          userId: 'user-1',
          type: NotificationType.meetingReminder,
          title: 'Meeting Reminder',
          body: 'You have a meeting',
          createdAt: DateTime.now(),
        );

        expect(notification.targetRoute, isNull);
      });
    });
  });

  group('NotificationType', () {
    test('displayName returns correct Romanian names', () {
      expect(NotificationType.meetingReminder.displayName, equals('Reminder ședință'));
      expect(NotificationType.newAnnouncement.displayName, equals('Comunicat nou'));
      expect(NotificationType.initiativeUpdate.displayName, equals('Actualizare inițiativă'));
      expect(NotificationType.pollReminder.displayName, equals('Sondaj activ'));
      expect(NotificationType.systemAlert.displayName, equals('Alertă sistem'));
      expect(NotificationType.warningIssued.displayName, equals('Avertisment primit'));
      expect(NotificationType.absenceRecorded.displayName, equals('Absență înregistrată'));
    });
  });
}
