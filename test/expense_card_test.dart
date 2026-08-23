import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:expense_tracker_app/models/expense_model.dart';
import 'package:expense_tracker_app/widgets/expense_card.dart';

// Pure widget test — no Firebase initialization required.
void main() {
  // Prevent google_fonts from attempting network fetches during tests;
  // text falls back to the default font without affecting finders.
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final foodExpense = Expense(
    id: 'e1',
    title: 'Groceries',
    amount: 42.5,
    category: 'Food',
    date: DateTime(2026, 8, 22),
    isExpense: true,
  );

  testWidgets('renders title, category and formatted amount',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ExpenseCard(expense: foodExpense)),
      ),
    );

    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('-\$42.50'), findsOneWidget);
    expect(find.byIcon(Expense.categoryIcon('Food')), findsOneWidget);
  });

  testWidgets('shows a plus-prefixed amount for income entries',
      (WidgetTester tester) async {
    final income = Expense(
      id: 'i1',
      title: 'August Paycheck',
      amount: 2500,
      category: 'Salary',
      date: DateTime(2026, 8, 1),
      isExpense: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ExpenseCard(expense: income)),
      ),
    );

    expect(find.text('August Paycheck'), findsOneWidget);
    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('+\$2500.00'), findsOneWidget);
  });

  testWidgets('onLongPress fires when the card is long-pressed',
      (WidgetTester tester) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpenseCard(
            expense: foodExpense,
            onLongPress: () => pressed = true,
          ),
        ),
      ),
    );

    await tester.longPress(find.text('Groceries'));
    expect(pressed, isTrue);
  });
}
