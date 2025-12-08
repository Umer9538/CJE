// ignore_for_file: avoid_print
/// Script to seed Firebase with sample data
/// Run this script once to populate the database with realistic data
///
/// To run: flutter run -t lib/scripts/seed_data.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print('Starting data seeding...\n');

  final seeder = DataSeeder();
  await seeder.seedAll();

  print('\n✅ Data seeding completed!');
}

class DataSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> seedAll() async {
    await seedSchools();
    await seedAnnouncements();
    await seedPolls();
    await seedMeetings();
    await seedDocuments();
    await seedInitiatives();
    await seedGDS();
  }

  /// Seed Schools
  Future<void> seedSchools() async {
    print('📚 Seeding schools...');

    final schools = [
      {
        'name': 'Colegiul National "Mihai Viteazul"',
        'address': 'Strada Mihai Viteazul 12, Bucharest',
        'city': 'Bucharest',
        'county': 'Bucharest',
        'isActive': true,
        'studentCount': 1250,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Liceul Teoretic "Ion Creanga"',
        'address': 'Bulevardul Unirii 45, Bucharest',
        'city': 'Bucharest',
        'county': 'Bucharest',
        'isActive': true,
        'studentCount': 980,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Colegiul National "Gheorghe Lazar"',
        'address': 'Strada Gheorghe Lazar 8, Timisoara',
        'city': 'Timisoara',
        'county': 'Timis',
        'isActive': true,
        'studentCount': 1100,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Liceul Teoretic "Nichita Stanescu"',
        'address': 'Calea Victoriei 100, Cluj-Napoca',
        'city': 'Cluj-Napoca',
        'county': 'Cluj',
        'isActive': true,
        'studentCount': 850,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Colegiul National "Alexandru Ioan Cuza"',
        'address': 'Strada Cuza Voda 22, Iasi',
        'city': 'Iasi',
        'county': 'Iasi',
        'isActive': true,
        'studentCount': 1050,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Liceul Teoretic "Ovidius"',
        'address': 'Bulevardul Tomis 55, Constanta',
        'city': 'Constanta',
        'county': 'Constanta',
        'isActive': true,
        'studentCount': 920,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
    ];

    for (final school in schools) {
      await _firestore.collection('schools').add(school);
    }
    print('   ✓ Added ${schools.length} schools');
  }

  /// Seed Announcements
  Future<void> seedAnnouncements() async {
    print('📢 Seeding announcements...');

    final announcements = [
      {
        'title': 'Adunarea Generala CJE - Decembrie 2025',
        'content': 'Dragi colegi,\n\nVa invitam la Adunarea Generala a Consiliului Judetean al Elevilor care va avea loc in data de 15 decembrie 2025, ora 14:00.\n\nOrdine de zi:\n1. Raport de activitate semestrul I\n2. Alegeri pentru pozitiile vacante\n3. Planificarea activitatilor pentru semestrul II\n4. Diverse\n\nParticiparea este obligatorie pentru toti reprezentantii scolari.',
        'type': 'county',
        'priority': 'high',
        'schoolId': null,
        'schoolName': null,
        'createdById': 'system',
        'createdByName': 'CJE Bucharest',
        'isPublished': true,
        'isPinned': true,
        'viewCount': 156,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
        'updatedAt': Timestamp.now(),
        'publishedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
      },
      {
        'title': 'Inscrieri Proiect Educational "Lider de Maine"',
        'content': 'CJE lanseaza proiectul educational "Lider de Maine" destinat elevilor din clasele IX-XII.\n\nProiectul include:\n- Workshop-uri de leadership\n- Sesiuni de mentorat\n- Proiecte practice in comunitate\n- Certificat de participare\n\nInscrierile sunt deschise pana pe 20 decembrie 2025.\n\nPentru inscrieri, accesati formularul din sectiunea Documente.',
        'type': 'county',
        'priority': 'normal',
        'schoolId': null,
        'schoolName': null,
        'createdById': 'system',
        'createdByName': 'CJE Bucharest',
        'isPublished': true,
        'isPinned': false,
        'viewCount': 89,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
        'updatedAt': Timestamp.now(),
        'publishedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
      },
      {
        'title': 'Rezultate Olimpiada Nationala de Dezbateri',
        'content': 'Felicitari echipei CJE Bucharest pentru rezultatele exceptionale obtinute la Olimpiada Nationala de Dezbateri!\n\nLocul I - Echipa Seniorilor\nLocul III - Echipa Juniorilor\nPremiul pentru Cel Mai Bun Vorbitor - Maria Popescu\n\nMultumim tuturor participantilor si profesorilor coordonatori!',
        'type': 'county',
        'priority': 'normal',
        'schoolId': null,
        'schoolName': null,
        'createdById': 'system',
        'createdByName': 'CJE Bucharest',
        'isPublished': true,
        'isPinned': false,
        'viewCount': 234,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 10))),
        'updatedAt': Timestamp.now(),
        'publishedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 10))),
      },
      {
        'title': 'Program Vacanta de Iarna 2025',
        'content': 'Va informam ca in perioada vacantei de iarna (23 decembrie 2025 - 7 ianuarie 2026), secretariatul CJE va functiona cu program redus.\n\nProgram:\n- Luni-Vineri: 10:00 - 14:00\n- Sambata-Duminica: Inchis\n\nPentru urgente, contactati-ne la email: cje.bucharest@edu.ro',
        'type': 'county',
        'priority': 'low',
        'schoolId': null,
        'schoolName': null,
        'createdById': 'system',
        'createdByName': 'CJE Bucharest',
        'isPublished': true,
        'isPinned': false,
        'viewCount': 67,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        'updatedAt': Timestamp.now(),
        'publishedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
      },
      {
        'title': 'Concurs de Proiecte Sociale - Editia 2025',
        'content': 'CJE organizeaza concursul anual de proiecte sociale!\n\nTema acestui an: "Educatie pentru toti"\n\nPremii:\n- Locul I: 5000 RON pentru implementarea proiectului\n- Locul II: 3000 RON\n- Locul III: 2000 RON\n\nTermenlimita pentru depunerea proiectelor: 15 ianuarie 2026\n\nDetalii complete in regulament.',
        'type': 'county',
        'priority': 'high',
        'schoolId': null,
        'schoolName': null,
        'createdById': 'system',
        'createdByName': 'CJE Bucharest',
        'isPublished': true,
        'isPinned': true,
        'viewCount': 312,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
        'updatedAt': Timestamp.now(),
        'publishedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
      },
    ];

    for (final announcement in announcements) {
      await _firestore.collection('announcements').add(announcement);
    }
    print('   ✓ Added ${announcements.length} announcements');
  }

  /// Seed Polls
  Future<void> seedPolls() async {
    print('📊 Seeding polls...');

    final polls = [
      {
        'question': 'Care ar trebui sa fie tema Balului Bobocilor 2025?',
        'description': 'Votati pentru tema preferata pentru evenimentul anual al bobocilor.',
        'type': 'county',
        'options': [
          {'id': 'opt1', 'text': 'Hollywood Glamour', 'voteCount': 145},
          {'id': 'opt2', 'text': 'Neon Party', 'voteCount': 98},
          {'id': 'opt3', 'text': 'Masquerade Ball', 'voteCount': 167},
          {'id': 'opt4', 'text': 'Retro 80s', 'voteCount': 72},
        ],
        'createdById': 'system',
        'createdByName': 'CJE Bucharest',
        'schoolId': null,
        'schoolName': null,
        'isAnonymous': true,
        'allowMultipleVotes': false,
        'totalVotes': 482,
        'voterIds': <String>[],
        'startDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7))),
        'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7))),
        'updatedAt': Timestamp.now(),
      },
      {
        'question': 'Preferati sedintele CJE online sau fizic?',
        'description': 'Ajutati-ne sa planificam formatul sedintelor viitoare.',
        'type': 'county',
        'options': [
          {'id': 'opt1', 'text': 'Online (Zoom/Meet)', 'voteCount': 89},
          {'id': 'opt2', 'text': 'Fizic (la sediu)', 'voteCount': 156},
          {'id': 'opt3', 'text': 'Hibrid (alternativ)', 'voteCount': 203},
        ],
        'createdById': 'system',
        'createdByName': 'CJE Bucharest',
        'schoolId': null,
        'schoolName': null,
        'isAnonymous': true,
        'allowMultipleVotes': false,
        'totalVotes': 448,
        'voterIds': <String>[],
        'startDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 14))),
        'endDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 14))),
        'updatedAt': Timestamp.now(),
      },
      {
        'question': 'Ce tip de workshop-uri doriti in semestrul II?',
        'description': 'Puteti selecta mai multe optiuni.',
        'type': 'county',
        'options': [
          {'id': 'opt1', 'text': 'Public Speaking', 'voteCount': 234},
          {'id': 'opt2', 'text': 'Project Management', 'voteCount': 189},
          {'id': 'opt3', 'text': 'Social Media Marketing', 'voteCount': 156},
          {'id': 'opt4', 'text': 'Fundraising', 'voteCount': 98},
          {'id': 'opt5', 'text': 'Event Planning', 'voteCount': 145},
        ],
        'createdById': 'system',
        'createdByName': 'CJE Bucharest',
        'schoolId': null,
        'schoolName': null,
        'isAnonymous': true,
        'allowMultipleVotes': true,
        'totalVotes': 822,
        'voterIds': <String>[],
        'startDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
        'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 14))),
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
        'updatedAt': Timestamp.now(),
      },
      {
        'question': 'Sunteti de acord cu propunerea de modificare a regulamentului intern?',
        'description': 'Votati pentru sau impotriva modificarilor propuse la articolul 15.',
        'type': 'county',
        'options': [
          {'id': 'opt1', 'text': 'Da, sunt de acord', 'voteCount': 287},
          {'id': 'opt2', 'text': 'Nu, nu sunt de acord', 'voteCount': 45},
          {'id': 'opt3', 'text': 'Ma abtin', 'voteCount': 23},
        ],
        'createdById': 'system',
        'createdByName': 'CJE Bucharest',
        'schoolId': null,
        'schoolName': null,
        'isAnonymous': false,
        'allowMultipleVotes': false,
        'totalVotes': 355,
        'voterIds': <String>[],
        'startDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
        'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 2))),
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
        'updatedAt': Timestamp.now(),
      },
    ];

    for (final poll in polls) {
      await _firestore.collection('polls').add(poll);
    }
    print('   ✓ Added ${polls.length} polls');
  }

  /// Seed Meetings
  Future<void> seedMeetings() async {
    print('📅 Seeding meetings...');

    final meetings = [
      {
        'title': 'Adunarea Generala CJE - Decembrie',
        'description': 'Adunarea generala lunara a Consiliului Judetean al Elevilor.\n\nOrdine de zi:\n1. Raport activitati\n2. Planificare evenimente\n3. Discutii si propuneri',
        'type': 'county',
        'location': 'Sala de Conferinte CJE, Etaj 2',
        'onlineLink': 'https://meet.google.com/abc-defg-hij',
        'isOnline': false,
        'schoolId': null,
        'schoolName': null,
        'createdById': 'system',
        'createdByName': 'CJE Bucharest',
        'attendeeIds': <String>[],
        'attendeeCount': 45,
        'maxAttendees': 100,
        'startTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 12, hours: 14))),
        'endTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 12, hours: 16))),
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
        'updatedAt': Timestamp.now(),
      },
      {
        'title': 'Workshop: Public Speaking pentru Lideri',
        'description': 'Workshop interactiv de public speaking destinat reprezentantilor de clase si membrilor CJE.\n\nVeti invata:\n- Tehnici de comunicare eficienta\n- Gestionarea emotiilor\n- Structurarea discursurilor',
        'type': 'county',
        'location': 'Online',
        'onlineLink': 'https://zoom.us/j/123456789',
        'isOnline': true,
        'schoolId': null,
        'schoolName': null,
        'createdById': 'system',
        'createdByName': 'CJE Bucharest',
        'attendeeIds': <String>[],
        'attendeeCount': 78,
        'maxAttendees': 100,
        'startTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 5, hours: 10))),
        'endTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 5, hours: 12))),
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 10))),
        'updatedAt': Timestamp.now(),
      },
      {
        'title': 'Sedinta Biroul Executiv',
        'description': 'Sedinta saptamanala a Biroului Executiv CJE.\n\nPuncte de discutie:\n- Statusul proiectelor in derulare\n- Buget si finante\n- Comunicare externa',
        'type': 'county',
        'location': 'Sala Consiliu, Etaj 3',
        'onlineLink': null,
        'isOnline': false,
        'schoolId': null,
        'schoolName': null,
        'createdById': 'system',
        'createdByName': 'CJE Bucharest',
        'attendeeIds': <String>[],
        'attendeeCount': 12,
        'maxAttendees': 15,
        'startTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 2, hours: 15))),
        'endTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 2, hours: 17))),
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
        'updatedAt': Timestamp.now(),
      },
      {
        'title': 'Training: Managementul Proiectelor',
        'description': 'Sesiune de training pentru coordonatorii de proiecte CJE.\n\nTopicuri:\n- Planificarea proiectelor\n- Gestionarea echipelor\n- Monitorizare si evaluare\n- Raportare',
        'type': 'county',
        'location': 'Centrul de Conferinte Universitar',
        'onlineLink': null,
        'isOnline': false,
        'schoolId': null,
        'schoolName': null,
        'createdById': 'system',
        'createdByName': 'CJE Bucharest',
        'attendeeIds': <String>[],
        'attendeeCount': 34,
        'maxAttendees': 50,
        'startTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 8, hours: 9))),
        'endTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 8, hours: 17))),
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7))),
        'updatedAt': Timestamp.now(),
      },
      {
        'title': 'Intalnire Coordonatori GDS',
        'description': 'Intalnire lunara a coordonatorilor Grupurilor de Suport.',
        'type': 'county',
        'location': 'Online',
        'onlineLink': 'https://meet.google.com/xyz-uvwx-rst',
        'isOnline': true,
        'schoolId': null,
        'schoolName': null,
        'createdById': 'system',
        'createdByName': 'CJE Bucharest',
        'attendeeIds': <String>[],
        'attendeeCount': 18,
        'maxAttendees': 25,
        'startTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3, hours: 16))),
        'endTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3, hours: 18))),
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
        'updatedAt': Timestamp.now(),
      },
    ];

    for (final meeting in meetings) {
      await _firestore.collection('meetings').add(meeting);
    }
    print('   ✓ Added ${meetings.length} meetings');
  }

  /// Seed Documents
  Future<void> seedDocuments() async {
    print('📄 Seeding documents...');

    final documents = [
      {
        'title': 'Statutul Elevului - Editia 2025',
        'description': 'Documentul oficial care reglementeaza drepturile si obligatiile elevilor.',
        'category': 'statutElevului',
        'fileType': 'pdf',
        'fileUrl': 'https://edu.ro/sites/default/files/statut_elev_2025.pdf',
        'fileSize': 2456000,
        'schoolId': null,
        'createdById': 'system',
        'createdByName': 'CJE Bucharest',
        'downloadCount': 567,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 60))),
        'updatedAt': Timestamp.now(),
      },
      {
        'title': 'Regulamentul de Organizare si Functionare CJE',
        'description': 'Regulamentul intern al Consiliului Judetean al Elevilor.',
        'category': 'regulamente',
        'fileType': 'pdf',
        'fileUrl': 'https://edu.ro/sites/default/files/rof_cje_2025.pdf',
        'fileSize': 1890000,
        'schoolId': null,
        'createdById': 'system',
        'createdByName': 'CJE Bucharest',
        'downloadCount': 234,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 90))),
        'updatedAt': Timestamp.now(),
      },
      {
        'title': 'Metodologia Alegerii Reprezentantilor',
        'description': 'Ghid pentru organizarea alegerilor la nivel de clasa, scoala si judet.',
        'category': 'metodologii',
        'fileType': 'pdf',
        'fileUrl': 'https://edu.ro/sites/default/files/metodologie_alegeri.pdf',
        'fileSize': 1234000,
        'schoolId': null,
        'createdById': 'system',
        'createdByName': 'CJE Bucharest',
        'downloadCount': 445,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 120))),
        'updatedAt': Timestamp.now(),
      },
      {
        'title': 'Formular Inscriere Proiect Educational',
        'description': 'Formular de inscriere pentru proiectele educationale CJE.',
        'category': 'formulare',
        'fileType': 'docx',
        'fileUrl': 'https://edu.ro/sites/default/files/formular_proiect.docx',
        'fileSize': 45000,
        'schoolId': null,
        'createdById': 'system',
        'createdByName': 'CJE Bucharest',
        'downloadCount': 189,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30))),
        'updatedAt': Timestamp.now(),
      },
      {
        'title': 'Model Proces Verbal Sedinta',
        'description': 'Model de proces verbal pentru sedintele consiliilor elevilor.',
        'category': 'formulare',
        'fileType': 'docx',
        'fileUrl': 'https://edu.ro/sites/default/files/proces_verbal_model.docx',
        'fileSize': 38000,
        'schoolId': null,
        'createdById': 'system',
        'createdByName': 'CJE Bucharest',
        'downloadCount': 312,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 45))),
        'updatedAt': Timestamp.now(),
      },
      {
        'title': 'Regulament Concurs Proiecte Sociale 2025',
        'description': 'Regulamentul oficial al concursului anual de proiecte sociale.',
        'category': 'regulamente',
        'fileType': 'pdf',
        'fileUrl': 'https://edu.ro/sites/default/files/regulament_concurs_2025.pdf',
        'fileSize': 890000,
        'schoolId': null,
        'createdById': 'system',
        'createdByName': 'CJE Bucharest',
        'downloadCount': 156,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 10))),
        'updatedAt': Timestamp.now(),
      },
      {
        'title': 'Ghid Organizare Evenimente',
        'description': 'Manual practic pentru organizarea evenimentelor CJE.',
        'category': 'metodologii',
        'fileType': 'pdf',
        'fileUrl': 'https://edu.ro/sites/default/files/ghid_evenimente.pdf',
        'fileSize': 3450000,
        'schoolId': null,
        'createdById': 'system',
        'createdByName': 'CJE Bucharest',
        'downloadCount': 278,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 75))),
        'updatedAt': Timestamp.now(),
      },
      {
        'title': 'Formular Raport Activitate Lunara',
        'description': 'Formular pentru raportarea activitatilor lunare ale CSE.',
        'category': 'formulare',
        'fileType': 'xlsx',
        'fileUrl': 'https://edu.ro/sites/default/files/raport_activitate.xlsx',
        'fileSize': 67000,
        'schoolId': null,
        'createdById': 'system',
        'createdByName': 'CJE Bucharest',
        'downloadCount': 423,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 20))),
        'updatedAt': Timestamp.now(),
      },
    ];

    for (final document in documents) {
      await _firestore.collection('documents').add(document);
    }
    print('   ✓ Added ${documents.length} documents');
  }

  /// Seed Initiatives
  Future<void> seedInitiatives() async {
    print('💡 Seeding initiatives...');

    final initiatives = [
      {
        'title': 'Program de Mentorat pentru Boboci',
        'description': 'Propun implementarea unui program de mentorat in care elevii din clasele XI-XII sa ghideze bobocii in primele luni de liceu.\n\nObiective:\n- Integrarea mai rapida a bobocilor\n- Crearea de legaturi intre generatii\n- Reducerea abandonului scolar',
        'category': 'educational',
        'status': 'approved',
        'authorId': 'user1',
        'authorName': 'Maria Popescu',
        'schoolId': null,
        'schoolName': null,
        'supportCount': 89,
        'supporterIds': <String>[],
        'adminNotes': 'Initiativa excelenta! Vom implementa in semestrul II.',
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30))),
        'updatedAt': Timestamp.now(),
        'reviewedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 25))),
        'reviewedBy': 'CJE Admin',
      },
      {
        'title': 'Spatiu de Relaxare in Scoli',
        'description': 'Propun crearea unui spatiu dedicat relaxarii elevilor in fiecare scoala, echipat cu canapele, plante si muzica ambientala.\n\nBeneficii:\n- Reducerea stresului\n- Imbunatatirea starii de bine\n- Cresterea productivitatii',
        'category': 'wellbeing',
        'status': 'pending',
        'authorId': 'user2',
        'authorName': 'Andrei Ionescu',
        'schoolId': null,
        'schoolName': null,
        'supportCount': 156,
        'supporterIds': <String>[],
        'adminNotes': null,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
        'updatedAt': Timestamp.now(),
        'reviewedAt': null,
        'reviewedBy': null,
      },
      {
        'title': 'Zi fara Telefoane',
        'description': 'O zi pe luna in care elevii sunt incurajati sa nu foloseasca telefoanele in scoala, promovand interactiunea fata in fata.',
        'category': 'social',
        'status': 'inReview',
        'authorId': 'user3',
        'authorName': 'Elena Dumitrescu',
        'schoolId': null,
        'schoolName': null,
        'supportCount': 45,
        'supporterIds': <String>[],
        'adminNotes': 'In analiza - necesita consultare cu directiunea.',
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 15))),
        'updatedAt': Timestamp.now(),
        'reviewedAt': null,
        'reviewedBy': null,
      },
      {
        'title': 'Program de Reciclare in Scoli',
        'description': 'Implementarea unui sistem de reciclare in toate scolile din judet, cu puncte de colectare separata si competitii intre clase.\n\nPropuneri:\n- Cosuri separate pentru hartie, plastic, sticla\n- Punctaj pe clase pentru reciclare\n- Premii lunare',
        'category': 'environmental',
        'status': 'approved',
        'authorId': 'user4',
        'authorName': 'Mihai Stanescu',
        'schoolId': null,
        'schoolName': null,
        'supportCount': 234,
        'supporterIds': <String>[],
        'adminNotes': 'Aprobat! Parteneriat cu Primaria pentru implementare.',
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 45))),
        'updatedAt': Timestamp.now(),
        'reviewedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 40))),
        'reviewedBy': 'CJE Admin',
      },
      {
        'title': 'Club de Dezbateri in Fiecare Scoala',
        'description': 'Propun infiintarea unui club de dezbateri in fiecare scoala, cu intalniri saptamanale si competitii inter-scolare.',
        'category': 'educational',
        'status': 'rejected',
        'authorId': 'user5',
        'authorName': 'Ana Maria Popa',
        'schoolId': null,
        'schoolName': null,
        'supportCount': 67,
        'supporterIds': <String>[],
        'adminNotes': 'Exista deja cluburi de dezbateri in majoritatea scolilor. Propunem participarea la cele existente.',
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 60))),
        'updatedAt': Timestamp.now(),
        'reviewedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 55))),
        'reviewedBy': 'CJE Admin',
      },
    ];

    for (final initiative in initiatives) {
      await _firestore.collection('initiatives').add(initiative);
    }
    print('   ✓ Added ${initiatives.length} initiatives');
  }

  /// Seed GDS (Support Groups)
  Future<void> seedGDS() async {
    print('👥 Seeding GDS (Support Groups)...');

    final gdsGroups = [
      {
        'name': 'GDS Comunicare si PR',
        'description': 'Grupul responsabil cu comunicarea externa, social media si relatiile publice ale CJE.',
        'category': 'communication',
        'coordinatorId': 'coord1',
        'coordinatorName': 'Alexandra Marin',
        'memberIds': <String>[],
        'memberCount': 15,
        'maxMembers': 20,
        'isActive': true,
        'meetingSchedule': 'Marti, 16:00-18:00',
        'achievements': ['Crestere 50% followeri Instagram', 'Campanie "Vocea Elevului" - 10k reach'],
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 180))),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'GDS Evenimente',
        'description': 'Grupul care coordoneaza organizarea evenimentelor CJE - conferinte, workshop-uri, baluri.',
        'category': 'events',
        'coordinatorId': 'coord2',
        'coordinatorName': 'Cristian Neagu',
        'memberIds': <String>[],
        'memberCount': 22,
        'maxMembers': 25,
        'isActive': true,
        'meetingSchedule': 'Joi, 15:00-17:00',
        'achievements': ['Organizare Bal Boboci 2024 - 500 participanti', 'Conferinta Nationala CJE'],
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 200))),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'GDS Educatie si Formare',
        'description': 'Grupul dedicat programelor educationale, training-urilor si formarii membrilor CJE.',
        'category': 'education',
        'coordinatorId': 'coord3',
        'coordinatorName': 'Diana Florescu',
        'memberIds': <String>[],
        'memberCount': 12,
        'maxMembers': 15,
        'isActive': true,
        'meetingSchedule': 'Miercuri, 14:00-16:00',
        'achievements': ['Program Leadership - 100 absolventi', 'Parteneriat cu 3 universitati'],
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 150))),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'GDS Proiecte Sociale',
        'description': 'Grupul care initiaza si coordoneaza proiectele cu impact social in comunitate.',
        'category': 'social',
        'coordinatorId': 'coord4',
        'coordinatorName': 'Radu Georgescu',
        'memberIds': <String>[],
        'memberCount': 18,
        'maxMembers': 20,
        'isActive': true,
        'meetingSchedule': 'Luni, 16:00-18:00',
        'achievements': ['Proiect "Scoala pentru Toti" - 50 beneficiari', 'Strangere fonduri - 15000 RON'],
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 120))),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'GDS Advocacy si Legislatie',
        'description': 'Grupul care monitorizeaza legislatia educationala si reprezinta interesele elevilor.',
        'category': 'advocacy',
        'coordinatorId': 'coord5',
        'coordinatorName': 'Ioana Vasilescu',
        'memberIds': <String>[],
        'memberCount': 8,
        'maxMembers': 12,
        'isActive': true,
        'meetingSchedule': 'Vineri, 15:00-17:00',
        'achievements': ['Participare la 5 consultari publice', 'Propunere modificare Statut Elev'],
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 100))),
        'updatedAt': Timestamp.now(),
      },
    ];

    for (final gds in gdsGroups) {
      await _firestore.collection('gds').add(gds);
    }
    print('   ✓ Added ${gdsGroups.length} GDS groups');
  }
}
