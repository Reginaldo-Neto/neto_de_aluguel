import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neto_de_aluguel/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: NetoDeAluguelApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Neto de Aluguel'), findsOneWidget);
  });
}
