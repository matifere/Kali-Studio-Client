import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kali_studio/auth/log_in.dart';

void main() {
  group('LogIn validation', () {
    setUp(() {});

    testWidgets('shows error snackbar when both fields are empty',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(480, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: LogIn()));

      await tester.tap(find.text('Iniciar Sesión'));
      await tester.pump();

      expect(find.text('Ingresa email y contraseña.'), findsOneWidget);
    });

    testWidgets('shows error snackbar when only email is empty',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(480, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: LogIn()));

      final fields = find.byType(TextField);
      await tester.enterText(fields.last, 'password123');

      await tester.tap(find.text('Iniciar Sesión'));
      await tester.pump();

      expect(find.text('Ingresa email y contraseña.'), findsOneWidget);
    });

    testWidgets('shows error snackbar when only password is empty',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(480, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: LogIn()));

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'usuario@ejemplo.com');

      await tester.tap(find.text('Iniciar Sesión'));
      await tester.pump();

      expect(find.text('Ingresa email y contraseña.'), findsOneWidget);
    });

    testWidgets('login button is enabled on initial render',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(480, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: LogIn()));

      final button = tester.widget<FilledButton>(find.byType(FilledButton).first);
      expect(button.onPressed, isNotNull);
    });
  });
}
