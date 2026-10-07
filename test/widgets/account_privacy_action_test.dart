import 'package:cje/core/l10n/app_localizations.dart';
import 'package:cje/views/widgets/common/account_privacy_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'account privacy action is available without consent or a profile',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [AppLocalizations.delegate],
          home: Scaffold(
            appBar: AppBar(actions: const [AccountPrivacyAction()]),
          ),
        ),
      );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.privacy_tip_outlined), findsOneWidget);
      expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
