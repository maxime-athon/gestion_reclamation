import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reclamations_app/main.dart';

void main() {
  testWidgets('l application affiche un ecran d authentification au demarrage', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Bon retour !'), findsOneWidget);
    expect(find.text('Se connecter'), findsWidgets);
  });
}
