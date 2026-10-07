import 'package:flutter_test/flutter_test.dart';
import 'package:cje/controllers/meetings/meeting_controller.dart';
import 'package:cje/core/constants/enums.dart';
import 'package:cje/models/meeting_model.dart';

/// Garda impotriva stergerii unei sedinte cu prezenta inregistrata.
///
/// Pe prezenta se sprijina absentele si avertismentele, deci stergerea ei ar
/// distruge probele care sustin masuri disciplinare.
///
/// Garda traieste in cod, nu in regulile Firestore, si nu din comoditate: a sti
/// daca exista vreo prezenta pentru o sedinta cere o INTEROGARE pe
/// meeting_attendance, iar regulile pot face doar `get()` si `exists()` pe cai
/// cunoscute dinainte. Id-urile de prezenta sunt `{meetingId}_{userId}`, deci ar
/// trebui stiut fiecare userId in avans.
void main() {
  group('MeetingController.blocajStergere', () {
    test('sedinta fara prezenta poate fi stearsa', () {
      final blocaj = MeetingController.blocajStergere(
        prezenteInregistrate: 0,
        esteSuperadmin: false,
      );

      expect(blocaj, isNull);
    });

    test('sedinta cu prezenta nu poate fi stearsa', () {
      final blocaj = MeetingController.blocajStergere(
        prezenteInregistrate: 12,
        esteSuperadmin: false,
      );

      expect(blocaj, isNotNull);
    });

    test('mesajul spune cate prezente blocheaza si ce alternativa exista', () {
      final blocaj = MeetingController.blocajStergere(
        prezenteInregistrate: 12,
        esteSuperadmin: false,
      )!;

      expect(blocaj, contains('12'));
      expect(blocaj, contains('Anuleaza'));
    });

    test('o singura prezenta este suficienta ca sa blocheze', () {
      final blocaj = MeetingController.blocajStergere(
        prezenteInregistrate: 1,
        esteSuperadmin: false,
      );

      expect(blocaj, isNotNull);
    });

    test('superadmin poate sterge o sedinta cu prezenta', () {
      final blocaj = MeetingController.blocajStergere(
        prezenteInregistrate: 12,
        esteSuperadmin: true,
      );

      expect(blocaj, isNull);
    });

    test('superadmin poate sterge si o sedinta fara prezenta', () {
      final blocaj = MeetingController.blocajStergere(
        prezenteInregistrate: 0,
        esteSuperadmin: true,
      );

      expect(blocaj, isNull);
    });
  });

  group('MeetingStatus', () {
    test('o sedinta noua este scheduled', () {
      final meeting = MeetingModel(
        id: 'm1',
        title: 'Sedinta',
        type: MeetingType.school,
        dateTime: DateTime(2026, 3, 1),
        createdById: 'u1',
        createdByName: 'Organizator',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(meeting.status, MeetingStatus.scheduled);
      expect(meeting.status.isCancelled, isFalse);
    });

    test('anularea pastreaza sedinta, schimband doar starea', () {
      final meeting = MeetingModel(
        id: 'm1',
        title: 'Sedinta',
        type: MeetingType.school,
        dateTime: DateTime(2026, 3, 1),
        createdById: 'u1',
        createdByName: 'Organizator',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final anulata = meeting.copyWith(status: MeetingStatus.cancelled);

      expect(anulata.status.isCancelled, isTrue);
      expect(anulata.id, meeting.id);
      expect(anulata.title, meeting.title);
      expect(anulata.dateTime, meeting.dateTime);
    });

    test('starea ajunge in Firestore si se citeste inapoi', () {
      final meeting = MeetingModel(
        id: 'm1',
        title: 'Sedinta',
        type: MeetingType.school,
        dateTime: DateTime(2026, 3, 1),
        createdById: 'u1',
        createdByName: 'Organizator',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        status: MeetingStatus.cancelled,
      );

      expect(meeting.toFirestore()['status'], 'cancelled');
      expect(MeetingStatus.fromFirestore('cancelled'),
          MeetingStatus.cancelled);
    });

    test('o valoare necunoscuta din baza cade pe scheduled', () {
      expect(MeetingStatus.fromFirestore('ceva_nou'), MeetingStatus.scheduled);
    });
  });
}
