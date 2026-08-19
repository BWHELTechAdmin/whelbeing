import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whelbeing/widgets/password_requirements.dart';

void main() {
  testWidgets('marks every requirement when the password is valid', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PasswordRequirementsChecklist(
            controller: controller,
            vw: 3.75,
            vh: 8,
          ),
        ),
      ),
    );

    expect(find.text('Password requirements'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

    controller.text = 'Password1!';
    await tester.pump();

    expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(4));
  });
}
