import 'package:cje/core/l10n/app_localizations.dart';
import 'package:cje/views/widgets/common/registration_privacy_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('policy acknowledgement does not imply terms acceptance', (
    tester,
  ) async {
    final form = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate],
        home: Scaffold(
          body: Form(
            key: form,
            child: RegistrationPrivacySection(
              isUnder16: false,
              privacyNoticeAcknowledged: true,
              termsAccepted: false,
              enabled: true,
              onAgeGroupChanged: (_) {},
              onPrivacyNoticeAcknowledgedChanged: (_) {},
              onTermsAcceptedChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.byType(CheckboxListTile), findsNWidgets(2));
    expect(find.text('You must accept the Terms of Use.'), findsOneWidget);
  });
}
