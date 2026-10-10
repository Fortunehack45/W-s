import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets("W's App initializes and mounts root router", (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: WsApp(),
      ),
    );
    expect(find.byType(WsApp), findsOneWidget);
  });
}
