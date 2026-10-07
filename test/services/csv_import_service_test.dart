import 'package:flutter_test/flutter_test.dart';
import 'package:cje/core/constants/enums.dart';
import 'package:cje/core/services/csv_import_service.dart';

/// Validarea judetului la importul CSV.
///
/// Importul CSV este singura cale prin care `city` ajunge in baza ca text
/// liber; toate celelalte (register, profile_setup, add_user_dialog) aleg
/// dintr-o lista fixa. Valorile neconforme din productie -- 'sibiu' cu litera
/// mica, 'Cluj-Napoca' -- au intrat pe aici. Regulile Firestore compara
/// `city`/`countyId` cu `==`, deci o valoare gresita scoate tacit utilizatorul
/// din judetul lui.
void main() {
  late CSVImportService service;

  setUp(() {
    service = CSVImportService();
  });

  const antet = 'email,fullName,city';

  String csv(String city) => '$antet\nion@test.ro,Ion Popescu,$city';

  group('CSVImportService - validarea judetului', () {
    test('accepta un judet din lista fixa', () {
      final r = service.parseCSV(csv('Sibiu'));

      expect(r.errors, isEmpty);
      expect(r.successCount, 1);
      expect(r.successfulUsers.first.city, 'Sibiu');
    });

    test('respinge judetul scris cu litera mica', () {
      final r = service.parseCSV(csv('sibiu'));

      expect(r.successCount, 0);
      expect(r.errors, hasLength(1));
      expect(r.errors.first.message, contains('Invalid county: "sibiu"'));
    });

    test('respinge un oras folosit ca judet', () {
      final r = service.parseCSV(csv('Cluj-Napoca'));

      expect(r.successCount, 0);
      expect(r.errors.first.message, contains('Invalid county: "Cluj-Napoca"'));
    });

    test('respinge o valoare inventata', () {
      final r = service.parseCSV(csv('Judetul Meu'));

      expect(r.successCount, 0);
      expect(r.errors.first.message, contains('Invalid county: "Judetul Meu"'));
    });

    test('mesajul de eroare enumera valorile acceptate', () {
      final r = service.parseCSV(csv('sibiu'));
      final mesaj = r.errors.first.message;

      expect(mesaj, contains('Accepted values'));
      expect(mesaj, contains('Sibiu'));
      expect(mesaj, contains('Cluj'));
      expect(mesaj, contains('Timiș'));
    });

    test('nu ghiceste si nu corecteaza automat valoarea gresita', () {
      final r = service.parseCSV(csv('sibiu'));

      // randul e respins, nu importat cu valoarea corectata
      expect(r.successfulUsers, isEmpty);
    });

    test('respinge doar randul invalid, nu tot importul', () {
      final r = service.parseCSV(
        '$antet\n'
        'bun@test.ro,Utilizator Bun,Sibiu\n'
        'rau@test.ro,Utilizator Rau,sibiu\n'
        'bun2@test.ro,Alt Utilizator Bun,Cluj',
      );

      expect(r.successCount, 2);
      expect(r.errorCount, 1);
      expect(r.errors.first.rowNumber, 3);
      expect(
        r.successfulUsers.map((u) => u.city),
        containsAll(<String>['Sibiu', 'Cluj']),
      );
    });

    test('accepta toate cele 42 de judete din lista', () {
      for (final judet in romanianCounties) {
        final r = service.parseCSV(csv(judet));
        expect(
          r.errors,
          isEmpty,
          reason: 'judetul "$judet" ar trebui acceptat',
        );
        expect(r.successfulUsers.first.city, judet);
      }
    });
  });

  group('CSVImportService - judet obligatoriu', () {
    test('respinge fisierul fara coloana city', () {
      final r = service.parseCSV('email,fullName\nion@test.ro,Ion Popescu');

      expect(r.successCount, 0);
      expect(r.errors.first.message, contains('Missing required header: city'));
    });

    test('respinge randul cu city gol', () {
      final r = service.parseCSV(csv(''));

      expect(r.successCount, 0);
      expect(r.errors.first.message, 'County is required');
    });
  });

  group('CSVImportService - roluri privilegiate', () {
    test('respinge rolul BEX', () {
      final r = service.parseCSV(
        'email,fullName,city,role\nion@test.ro,Ion Popescu,Sibiu,bex',
      );

      expect(r.successCount, 0);
      expect(r.errors.first.message, contains('Cannot import BEX'));
    });

    test('respinge rolul superadmin', () {
      final r = service.parseCSV(
        'email,fullName,city,role\nion@test.ro,Ion Popescu,Sibiu,superadmin',
      );

      expect(r.successCount, 0);
      expect(r.errors.first.message, contains('Cannot import BEX'));
    });
  });
}
