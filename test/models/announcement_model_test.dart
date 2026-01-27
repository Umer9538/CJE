import 'package:flutter_test/flutter_test.dart';
import 'package:cje/models/announcement_model.dart';
import 'package:cje/core/constants/enums.dart';

void main() {
  group('AnnouncementModel', () {
    group('sorting', () {
      test('pinned announcements should come before non-pinned', () {
        final now = DateTime.now();

        final pinnedAnnouncement = AnnouncementModel(
          id: 'pinned-1',
          title: 'Pinned Announcement',
          content: 'Content',
          type: AnnouncementType.county,
          authorId: 'user-1',
          authorName: 'Test User',
          isPinned: true,
          isPublished: true,
          publishedAt: now.subtract(const Duration(days: 5)),
          createdAt: now.subtract(const Duration(days: 5)),
          updatedAt: now,
        );

        final recentAnnouncement = AnnouncementModel(
          id: 'recent-1',
          title: 'Recent Announcement',
          content: 'Content',
          type: AnnouncementType.county,
          authorId: 'user-1',
          authorName: 'Test User',
          isPinned: false,
          isPublished: true,
          publishedAt: now,
          createdAt: now,
          updatedAt: now,
        );

        final announcements = [recentAnnouncement, pinnedAnnouncement];

        // Sort: pinned first, then by publishedAt
        announcements.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return (b.publishedAt ?? b.createdAt)
              .compareTo(a.publishedAt ?? a.createdAt);
        });

        expect(announcements[0].id, equals('pinned-1'));
        expect(announcements[1].id, equals('recent-1'));
      });

      test('among pinned announcements, newer ones come first', () {
        final now = DateTime.now();

        final olderPinned = AnnouncementModel(
          id: 'pinned-old',
          title: 'Older Pinned',
          content: 'Content',
          type: AnnouncementType.county,
          authorId: 'user-1',
          authorName: 'Test User',
          isPinned: true,
          isPublished: true,
          publishedAt: now.subtract(const Duration(days: 5)),
          createdAt: now.subtract(const Duration(days: 5)),
          updatedAt: now,
        );

        final newerPinned = AnnouncementModel(
          id: 'pinned-new',
          title: 'Newer Pinned',
          content: 'Content',
          type: AnnouncementType.county,
          authorId: 'user-1',
          authorName: 'Test User',
          isPinned: true,
          isPublished: true,
          publishedAt: now,
          createdAt: now,
          updatedAt: now,
        );

        final announcements = [olderPinned, newerPinned];

        // Sort: pinned first, then by publishedAt
        announcements.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return (b.publishedAt ?? b.createdAt)
              .compareTo(a.publishedAt ?? a.createdAt);
        });

        expect(announcements[0].id, equals('pinned-new'));
        expect(announcements[1].id, equals('pinned-old'));
      });

      test('among non-pinned announcements, newer ones come first', () {
        final now = DateTime.now();

        final older = AnnouncementModel(
          id: 'old-1',
          title: 'Older',
          content: 'Content',
          type: AnnouncementType.county,
          authorId: 'user-1',
          authorName: 'Test User',
          isPinned: false,
          isPublished: true,
          publishedAt: now.subtract(const Duration(days: 5)),
          createdAt: now.subtract(const Duration(days: 5)),
          updatedAt: now,
        );

        final newer = AnnouncementModel(
          id: 'new-1',
          title: 'Newer',
          content: 'Content',
          type: AnnouncementType.county,
          authorId: 'user-1',
          authorName: 'Test User',
          isPinned: false,
          isPublished: true,
          publishedAt: now,
          createdAt: now,
          updatedAt: now,
        );

        final announcements = [older, newer];

        // Sort: pinned first, then by publishedAt
        announcements.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return (b.publishedAt ?? b.createdAt)
              .compareTo(a.publishedAt ?? a.createdAt);
        });

        expect(announcements[0].id, equals('new-1'));
        expect(announcements[1].id, equals('old-1'));
      });
    });

    group('getTitle', () {
      test('returns translated title when available', () {
        final now = DateTime.now();
        final announcement = AnnouncementModel(
          id: 'test-1',
          title: 'Default Title',
          titleTranslations: {'en': 'English Title', 'ro': 'Titlu Română'},
          content: 'Content',
          type: AnnouncementType.county,
          authorId: 'user-1',
          authorName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );

        expect(announcement.getTitle('en'), equals('English Title'));
        expect(announcement.getTitle('ro'), equals('Titlu Română'));
      });

      test('returns default title when translation not available', () {
        final now = DateTime.now();
        final announcement = AnnouncementModel(
          id: 'test-1',
          title: 'Default Title',
          content: 'Content',
          type: AnnouncementType.county,
          authorId: 'user-1',
          authorName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );

        expect(announcement.getTitle('fr'), equals('Default Title'));
      });
    });

    group('previewText', () {
      test('returns summary if available', () {
        final now = DateTime.now();
        final announcement = AnnouncementModel(
          id: 'test-1',
          title: 'Title',
          content: 'This is a very long content that should not be used',
          summary: 'Short summary',
          type: AnnouncementType.county,
          authorId: 'user-1',
          authorName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );

        expect(announcement.previewText, equals('Short summary'));
      });

      test('returns truncated content if summary not available', () {
        final now = DateTime.now();
        final longContent = 'A' * 200;
        final announcement = AnnouncementModel(
          id: 'test-1',
          title: 'Title',
          content: longContent,
          type: AnnouncementType.county,
          authorId: 'user-1',
          authorName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );

        expect(announcement.previewText.length, lessThanOrEqualTo(153)); // 150 + '...'
        expect(announcement.previewText.endsWith('...'), isTrue);
      });
    });
  });
}
