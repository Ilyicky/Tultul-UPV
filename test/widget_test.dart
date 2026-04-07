import 'package:flutter_test/flutter_test.dart';
import 'package:tultul_upv/main.dart';

void main() {
  testWidgets('shows initialization error when Firebase false', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp(firebaseInitialized: false));

    expect(find.text('Initialization Error'), findsOneWidget);
    expect(
      find.textContaining('Firebase failed to initialize'),
      findsOneWidget,
    );
  });
}
