import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edge_bench/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: EdgeBenchApp()));

    // Verify that the title is present.
    expect(find.text('EDGEBENCH'), findsOneWidget);
  });
}
