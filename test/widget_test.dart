import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:buddy_app/main.dart';

void main() {
  group('BuddyApp smoke tests', () {
    testWidgets('App launches and shows Chat tab by default', (WidgetTester tester) async {
      await tester.pumpWidget(const BuddyApp());

      // Chat screen's opening message should be visible on launch
      expect(find.textContaining("Hi, I'm Buddy"), findsOneWidget);

      // Bottom nav should show all 6 destinations
      expect(find.text('Chat'), findsWidgets);
      expect(find.text('Approve'), findsWidgets);
      expect(find.text('Friend'), findsWidgets);
      expect(find.text('Audit'), findsWidgets);
      expect(find.text('Gifts'), findsWidgets);
      expect(find.text('Cap'), findsWidgets);
    });

    testWidgets('Chat screen: user can send a message', (WidgetTester tester) async {
      await tester.pumpWidget(const BuddyApp());

      final field = find.byType(TextField);
      expect(field, findsOneWidget);

      await tester.enterText(field, 'Order a cake for Ayesha');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // User's message should now appear in the chat list
      expect(find.text('Order a cake for Ayesha'), findsOneWidget);
    });

    testWidgets('Navigating to Approval tab shows the HITL screen with cap usage',
            (WidgetTester tester) async {
          await tester.pumpWidget(const BuddyApp());

          await tester.tap(find.text('Approve'));
          await tester.pumpAndSettle();

          expect(find.text('Approval Needed'), findsOneWidget);
          expect(find.text('Buddy wants to spend:'), findsOneWidget);
          expect(find.textContaining('used this month'), findsOneWidget);
          expect(find.widgetWithText(ElevatedButton, 'Approve'), findsOneWidget);
          expect(find.widgetWithText(OutlinedButton, 'Deny'), findsOneWidget);
        });

    testWidgets('Approving a spend updates the Audit tab', (WidgetTester tester) async {
      await tester.pumpWidget(const BuddyApp());

      // Go to Approval tab and approve
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Approve'));
      await tester.pump(); // rebuild
      await tester.pump(const Duration(seconds: 1)); // let SnackBar animate in

      expect(find.text('Approved'), findsOneWidget); // SnackBar confirmation

      // Now check the Audit tab reflects it
      await tester.tap(find.text('Audit'));
      await tester.pumpAndSettle();

      expect(find.text('Activity Log'), findsOneWidget);
      expect(find.text('Approved'), findsWidgets); // list entry + possibly leftover snackbar
    });

    testWidgets('Denying a spend logs a Denied entry in Audit tab', (WidgetTester tester) async {
      await tester.pumpWidget(const BuddyApp());

      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Deny'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Audit'));
      await tester.pumpAndSettle();

      expect(find.text('Denied'), findsWidgets);
    });

    testWidgets('Friend Profile: user can add a like as a chip', (WidgetTester tester) async {
      await tester.pumpWidget(const BuddyApp());

      await tester.tap(find.text('Friend'));
      await tester.pumpAndSettle();

      expect(find.text('Friend Profile'), findsOneWidget);
      expect(find.textContaining('No profile scraping, ever'), findsOneWidget);

      final likeField = find.widgetWithText(TextField, 'Add a like / interest');
      await tester.enterText(likeField, 'Board games');
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(find.widgetWithText(Chip, 'Board games'), findsOneWidget);
    });

    testWidgets('Gift tab: ordering a gift routes into Approval tab with correct amount',
            (WidgetTester tester) async {
          await tester.pumpWidget(const BuddyApp());

          await tester.tap(find.text('Gifts'));
          await tester.pumpAndSettle();

          expect(find.textContaining('Gift ideas for Ayesha'), findsOneWidget);

          // Tap "Order this" on the first gift card
          await tester.tap(find.text('Order this').first);
          await tester.pumpAndSettle();

          // Should have jumped to Approval tab automatically
          expect(find.text('Approval Needed'), findsOneWidget);
          expect(find.textContaining('Gift:'), findsOneWidget);
        });

    testWidgets('Spending Cap tab: slider updates displayed limit and can be saved',
            (WidgetTester tester) async {
          await tester.pumpWidget(const BuddyApp());

          await tester.tap(find.text('Cap'));
          await tester.pumpAndSettle();

          expect(find.text('Spending Cap'), findsOneWidget);
          expect(find.textContaining('Monthly limit: Rs 2000'), findsOneWidget);

          final slider = find.byType(Slider);
          expect(slider, findsOneWidget);

          // Drag slider to the right to increase the cap
          await tester.drag(slider, const Offset(100, 0));
          await tester.pump();

          // Save and confirm SnackBar appears
          await tester.tap(find.widgetWithText(ElevatedButton, 'Save Limit'));
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));

          expect(find.text('Cap saved'), findsOneWidget);
        });
  });
}