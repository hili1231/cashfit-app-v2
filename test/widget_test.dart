import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cashfit/providers/shopping_list_provider.dart';
import 'package:cashfit/screens/diets/shopping_list_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ShoppingListScreen widget test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ShoppingListProvider(),
        child: const MaterialApp(
          home: ShoppingListScreen(),
        ),
      ),
    );

    expect(find.text('GROCERY SHOPPING LIST'), findsOneWidget);
    expect(find.text('Your Shopping List is empty'), findsOneWidget);
  });
}
