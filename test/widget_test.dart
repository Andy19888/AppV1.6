// widget_test.dart
// ... (comentarios omitidos)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:repocheck/main.dart'; // <-- IMPORTACIÓN CORREGIDA A LA RUTA DEL PAQUETE

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Asumo que ya hiciste el constructor de MyApp 'const' en main.dart
    await tester.pumpWidget(const MyApp()); 

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}