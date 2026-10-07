import 'package:cje/core/constants/app_strings.dart';
import 'package:cje/core/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final language in ['ro', 'en']) {
    test(
      'legal notice is complete in $language and keeps the real controller',
      () {
        for (var section = 1; section <= 9; section++) {
          final key = 'privacy_section_${section}_content';
          final content = AppLocalizations.translateForLocale(language, key);
          expect(content, isNot(key));
          expect(content, isNotEmpty);
        }
        final controller = AppLocalizations.translateForLocale(
          language,
          'privacy_section_1_content',
        );
        expect(controller, contains('Gavrilă Andrei-Zian'));
        expect(controller, contains('app.consiliulelevilor@gmail.com'));
        final basis = AppLocalizations.translateForLocale(
          language,
          'privacy_section_3_content',
        );
        expect(
          basis,
          contains(language == 'ro' ? 'contract valabil' : 'valid contract'),
        );
        expect(
          basis,
          contains(language == 'ro' ? 'pregătitor' : 'preparatory'),
        );
        final children = AppLocalizations.translateForLocale(
          language,
          'privacy_section_8_content',
        );
        expect(children, contains('13–17'));
        expect(
          children,
          contains(language == 'ro' ? 'dovadă suficientă' : 'sufficient proof'),
        );
      },
    );
  }

  test(
    'wording clarification does not desynchronise deployed onboarding IDs',
    () {
      expect(AppStrings.privacyNoticeVersion, '2026-09-30');
      expect(AppStrings.termsVersion, '2026-09-30');
    },
  );
}
