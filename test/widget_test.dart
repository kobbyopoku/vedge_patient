// Smoke test for the Vedge Patient app.
//
// Keeps `flutter test` green while the W5.5 walking skeleton stabilizes.
// Full widget + integration tests land in W5.5b alongside real data.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MaterialApp smoke test boots', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Vedge for Patients'))),
      ),
    );
    expect(find.text('Vedge for Patients'), findsOneWidget);
  });
}
