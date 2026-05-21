import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kali_studio/auth/new_password_screen.dart';

void main() {
  group('NewPasswordScreen validation', () {
    testWidgets('shows error when both fields are empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: NewPasswordScreen()));

      await tester.tap(find.text('Guardar contraseña'));
      await tester.pump();

      expect(find.text('Completá ambos campos.'), findsOneWidget);
    });

    testWidgets('shows error when password is shorter than 8 characters',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: NewPasswordScreen()));

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'short1');
      await tester.enterText(fields.at(1), 'short1');

      await tester.tap(find.text('Guardar contraseña'));
      await tester.pump();

      expect(
        find.text('La contraseña debe tener al menos 8 caracteres.'),
        findsOneWidget,
      );
    });

    testWidgets('accepts exactly 8 characters and proceeds to mismatch check',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: NewPasswordScreen()));

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'exactlyy');
      await tester.enterText(fields.at(1), 'diffrent');

      await tester.tap(find.text('Guardar contraseña'));
      await tester.pump();

      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
      expect(
        find.text('La contraseña debe tener al menos 8 caracteres.'),
        findsNothing,
      );
    });

    testWidgets('shows error when passwords do not match',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: NewPasswordScreen()));

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'password123');
      await tester.enterText(fields.at(1), 'different456');

      await tester.tap(find.text('Guardar contraseña'));
      await tester.pump();

      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
    });

    testWidgets('no snackbar shown when only first field is filled',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: NewPasswordScreen()));

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'password123');

      await tester.tap(find.text('Guardar contraseña'));
      await tester.pump();

      expect(find.text('Completá ambos campos.'), findsOneWidget);
    });
  });
}
