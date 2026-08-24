import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker_app/models/savings_goal_model.dart';

void main() {
  // ── JSON serialization ─────────────────────────────────────────────

  group('SavingsGoal JSON serialization', () {
    final date = DateTime(2026, 12, 31);
    final created = DateTime(2026, 8, 22, 10, 30);
    final goal = SavingsGoal(
      id: 'goal-123',
      name: 'Emergency Fund',
      targetAmount: 5000,
      currentAmount: 2500,
      targetDate: date,
      iconName: 'savings',
      isCompleted: false,
      createdAt: created,
    );

    test('toJson produces the expected map', () {
      final json = goal.toJson();
      expect(json['id'], 'goal-123');
      expect(json['name'], 'Emergency Fund');
      expect(json['targetAmount'], 5000);
      expect(json['currentAmount'], 2500);
      expect(json['targetDate'], date.toIso8601String());
      expect(json['iconName'], 'savings');
      expect(json['isCompleted'], false);
      expect(json['createdAt'], created.toIso8601String());
    });

    test('fromJson restores every field', () {
      final restored = SavingsGoal.fromJson(goal.toJson());
      expect(restored.id, goal.id);
      expect(restored.name, goal.name);
      expect(restored.targetAmount, goal.targetAmount);
      expect(restored.currentAmount, goal.currentAmount);
      expect(restored.targetDate, goal.targetDate);
      expect(restored.iconName, goal.iconName);
      expect(restored.isCompleted, goal.isCompleted);
      expect(restored.createdAt, goal.createdAt);
    });

    test('round-trip through JSON preserves every field', () {
      final restored =
          SavingsGoal.fromJson(SavingsGoal.fromJson(goal.toJson()).toJson());
      expect(restored.id, goal.id);
      expect(restored.name, goal.name);
      expect(restored.targetAmount, goal.targetAmount);
      expect(restored.currentAmount, goal.currentAmount);
      expect(restored.targetDate, goal.targetDate);
      expect(restored.iconName, goal.iconName);
      expect(restored.isCompleted, goal.isCompleted);
      expect(restored.createdAt, goal.createdAt);
    });
  });

  // ── Computed properties ──────────────────────────────────────────

  group('SavingsGoal computed properties', () {
    test('progress calculates correctly', () {
      final goal = SavingsGoal(
        id: '1',
        name: 'Goal',
        targetAmount: 1000,
        currentAmount: 250,
        targetDate: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
      );
      expect(goal.progress, 0.25);
    });

    test('progress caps at 1.0 when target exceeded', () {
      final goal = SavingsGoal(
        id: '1',
        name: 'Goal',
        targetAmount: 1000,
        currentAmount: 1500,
        targetDate: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
      );
      expect(goal.progress, greaterThanOrEqualTo(1.0));
    });

    test('progress returns 0 when target is 0', () {
      final goal = SavingsGoal(
        id: '1',
        name: 'Goal',
        targetAmount: 0,
        currentAmount: 100,
        targetDate: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
      );
      expect(goal.progress, 0);
    });

    test('remaining calculates correctly', () {
      final goal = SavingsGoal(
        id: '1',
        name: 'Goal',
        targetAmount: 1000,
        currentAmount: 300,
        targetDate: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
      );
      expect(goal.remaining, 700);
    });

    test('remaining is 0 when target reached', () {
      final goal = SavingsGoal(
        id: '1',
        name: 'Goal',
        targetAmount: 1000,
        currentAmount: 1000,
        targetDate: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
      );
      expect(goal.remaining, 0);
    });

    test('reachedTarget is true when current equals target', () {
      final goal = SavingsGoal(
        id: '1',
        name: 'Goal',
        targetAmount: 1000,
        currentAmount: 1000,
        targetDate: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
      );
      expect(goal.reachedTarget, true);
    });

    test('reachedTarget is true when current exceeds target', () {
      final goal = SavingsGoal(
        id: '1',
        name: 'Goal',
        targetAmount: 1000,
        currentAmount: 1200,
        targetDate: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
      );
      expect(goal.reachedTarget, true);
    });

    test('reachedTarget is false when current below target', () {
      final goal = SavingsGoal(
        id: '1',
        name: 'Goal',
        targetAmount: 1000,
        currentAmount: 500,
        targetDate: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
      );
      expect(goal.reachedTarget, false);
    });

    test('daysRemaining is positive for future dates', () {
      final goal = SavingsGoal(
        id: '1',
        name: 'Goal',
        targetAmount: 1000,
        currentAmount: 0,
        targetDate: DateTime.now().add(const Duration(days: 10)),
        createdAt: DateTime.now(),
      );
      expect(goal.daysRemaining, greaterThanOrEqualTo(9));
      expect(goal.daysRemaining, lessThanOrEqualTo(11));
    });

    test('daysRemaining is negative for past dates', () {
      final goal = SavingsGoal(
        id: '1',
        name: 'Goal',
        targetAmount: 1000,
        currentAmount: 0,
        targetDate: DateTime.now().subtract(const Duration(days: 5)),
        createdAt: DateTime.now(),
      );
      expect(goal.daysRemaining, lessThanOrEqualTo(-4));
    });
  });

  // ── Formatted helpers ─────────────────────────────────────────────

  group('SavingsGoal formatted helpers', () {
    test('formattedCurrentAmount formats correctly', () {
      final goal = SavingsGoal(
        id: '1',
        name: 'Goal',
        targetAmount: 1000,
        currentAmount: 250.5,
        targetDate: DateTime.now(),
        createdAt: DateTime.now(),
      );
      expect(goal.formattedCurrentAmount, '\$250.50');
    });

    test('formattedTargetAmount formats correctly', () {
      final goal = SavingsGoal(
        id: '1',
        name: 'Goal',
        targetAmount: 5000,
        currentAmount: 0,
        targetDate: DateTime.now(),
        createdAt: DateTime.now(),
      );
      expect(goal.formattedTargetAmount, '\$5000.00');
    });

    test('formattedRemaining formats correctly', () {
      final goal = SavingsGoal(
        id: '1',
        name: 'Goal',
        targetAmount: 1000,
        currentAmount: 300,
        targetDate: DateTime.now(),
        createdAt: DateTime.now(),
      );
      expect(goal.formattedRemaining, '\$700.00');
    });

    test('formattedTargetDate formats correctly', () {
      final goal = SavingsGoal(
        id: '1',
        name: 'Goal',
        targetAmount: 1000,
        currentAmount: 0,
        targetDate: DateTime(2026, 12, 25),
        createdAt: DateTime.now(),
      );
      expect(goal.formattedTargetDate, '25 Dec 2026');
    });

    test('daysRemainingText shows overdue for past dates', () {
      final goal = SavingsGoal(
        id: '1',
        name: 'Goal',
        targetAmount: 1000,
        currentAmount: 0,
        targetDate: DateTime.now().subtract(const Duration(days: 3)),
        createdAt: DateTime.now(),
      );
      expect(goal.daysRemainingText, contains('overdue'));
    });

    test('daysRemainingText shows "Due today" for today', () {
      final goal = SavingsGoal(
        id: '1',
        name: 'Goal',
        targetAmount: 1000,
        currentAmount: 0,
        targetDate: DateTime.now(),
        createdAt: DateTime.now(),
      );
      expect(goal.daysRemainingText, 'Due today');
    });

    test('daysRemainingText shows days left for future dates', () {
      final goal = SavingsGoal(
        id: '1',
        name: 'Goal',
        targetAmount: 1000,
        currentAmount: 0,
        targetDate: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now(),
      );
      expect(goal.daysRemainingText, contains('days left'));
    });
  });

  // ── copyWith ─────────────────────────────────────────────────────

  group('SavingsGoal.copyWith', () {
    test('copies with changes', () {
      final goal = SavingsGoal(
        id: '1',
        name: 'Goal',
        targetAmount: 1000,
        currentAmount: 0,
        targetDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final updated = goal.copyWith(
        name: 'New Name',
        currentAmount: 500,
      );

      expect(updated.name, 'New Name');
      expect(updated.currentAmount, 500);
      expect(updated.targetAmount, 1000); // unchanged
    });

    test('copies without changes keeps all fields', () {
      final goal = SavingsGoal(
        id: '1',
        name: 'Goal',
        targetAmount: 1000,
        currentAmount: 0,
        targetDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final copy = goal.copyWith();
      expect(copy.id, goal.id);
      expect(copy.name, goal.name);
      expect(copy.targetAmount, goal.targetAmount);
      expect(copy.currentAmount, goal.currentAmount);
    });
  });

  // ── Icon mapping ─────────────────────────────────────────────────

  group('SavingsGoal.iconFromName', () {
    test('maps known icons correctly', () {
      expect(SavingsGoal.iconFromName('savings'), Icons.savings_outlined);
      expect(SavingsGoal.iconFromName('flag'), Icons.flag_outlined);
      expect(SavingsGoal.iconFromName('home'), Icons.home_outlined);
      expect(SavingsGoal.iconFromName('car'), Icons.directions_car_outlined);
      expect(SavingsGoal.iconFromName('flight'), Icons.flight_outlined);
    });

    test('falls back to savings icon for unknown', () {
      expect(SavingsGoal.iconFromName('unknown'), Icons.savings_outlined);
    });
  });

  // ── Safe fromJson ────────────────────────────────────────────────

  group('SavingsGoal.fromJson safety', () {
    test('handles missing date fields gracefully', () {
      final json = {
        'id': '1',
        'name': 'Test',
        'targetAmount': 1000,
        'currentAmount': 0,
      };
      expect(() => SavingsGoal.fromJson(json), returnsNormally);
    });

    test('handles malformed date strings gracefully', () {
      final json = {
        'id': '1',
        'name': 'Test',
        'targetAmount': 1000,
        'currentAmount': 0,
        'targetDate': 'not-a-date',
        'createdAt': 'also-not-a-date',
      };
      expect(() => SavingsGoal.fromJson(json), returnsNormally);
    });

    test('defaults iconName when missing', () {
      final json = {
        'id': '1',
        'name': 'Test',
        'targetAmount': 1000,
        'currentAmount': 0,
        'targetDate': DateTime.now().toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      };
      final goal = SavingsGoal.fromJson(json);
      expect(goal.iconName, 'savings');
    });

    test('defaults isCompleted to false when missing', () {
      final json = {
        'id': '1',
        'name': 'Test',
        'targetAmount': 1000,
        'currentAmount': 0,
        'targetDate': DateTime.now().toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      };
      final goal = SavingsGoal.fromJson(json);
      expect(goal.isCompleted, false);
    });
  });

  // ── Available icons list ─────────────────────────────────────────

  group('SavingsGoal.availableIcons', () {
    test('contains expected icons', () {
      expect(SavingsGoal.availableIcons, contains('savings'));
      expect(SavingsGoal.availableIcons, contains('flag'));
      expect(SavingsGoal.availableIcons, contains('home'));
      expect(SavingsGoal.availableIcons, contains('car'));
    });

    test('all icons map to a valid IconData', () {
      for (final icon in SavingsGoal.availableIcons) {
        expect(
          SavingsGoal.iconFromName(icon),
          isNotNull,
          reason: '$icon should map to an IconData',
        );
      }
    });
  });
}
