import 'package:flutter_test/flutter_test.dart';
import 'package:budget_tracker/features/reports/providers/plan_distribution_lock_provider.dart';

void main() {
  group('PlanDistributionLockState & Notifier Tests', () {
    test('Default state has all locks false and null percentages', () {
      const state = PlanDistributionLockState();
      expect(state.spendingLocked, isFalse);
      expect(state.savingLocked, isFalse);
      expect(state.protectionLocked, isFalse);
      expect(state.lockedSpendingPct, isNull);
      expect(state.lockedSavingPct, isNull);
      expect(state.lockedProtectionPct, isNull);
    });

    test('toJson and fromJson preserves all lock states and percentages', () {
      const original = PlanDistributionLockState(
        spendingLocked: true,
        savingLocked: false,
        protectionLocked: true,
        lockedSpendingPct: 50.0,
        lockedSavingPct: null,
        lockedProtectionPct: 20.0,
      );

      final jsonMap = original.toJson();
      final restored = PlanDistributionLockState.fromJson(jsonMap);

      expect(restored.spendingLocked, isTrue);
      expect(restored.savingLocked, isFalse);
      expect(restored.protectionLocked, isTrue);
      expect(restored.lockedSpendingPct, 50.0);
      expect(restored.lockedSavingPct, isNull);
      expect(restored.lockedProtectionPct, 20.0);
    });

    test('toggleLock sets locked status and stores locked percentage', () {
      final notifier = PlanDistributionLockNotifier('test-hh');

      // Lock spending at 48%
      notifier.toggleLock('spending', 48.0);
      expect(notifier.state.spendingLocked, isTrue);
      expect(notifier.state.lockedSpendingPct, 48.0);

      // Lock saving at 32%
      notifier.toggleLock('saving', 32.0);
      expect(notifier.state.savingLocked, isTrue);
      expect(notifier.state.lockedSavingPct, 32.0);

      // Unlock spending
      notifier.toggleLock('spending', 48.0);
      expect(notifier.state.spendingLocked, isFalse);
      expect(notifier.state.lockedSpendingPct, isNull);
      // saving remains locked
      expect(notifier.state.savingLocked, isTrue);
      expect(notifier.state.lockedSavingPct, 32.0);
    });

    test('setLockedValue updates locked percentage if layer is locked', () {
      final notifier = PlanDistributionLockNotifier('test-hh');

      notifier.toggleLock('spending', 40.0);
      expect(notifier.state.lockedSpendingPct, 40.0);

      notifier.setLockedValue('spending', 55.0);
      expect(notifier.state.lockedSpendingPct, 55.0);

      // Does not update unlocked layer
      notifier.setLockedValue('saving', 25.0);
      expect(notifier.state.lockedSavingPct, isNull);
    });

    test('unlockAll resets all locks and percentages to default', () {
      final notifier = PlanDistributionLockNotifier('test-hh');

      notifier.toggleLock('spending', 50.0);
      notifier.toggleLock('saving', 30.0);
      notifier.toggleLock('protection', 20.0);

      expect(notifier.state.spendingLocked, isTrue);
      expect(notifier.state.savingLocked, isTrue);
      expect(notifier.state.protectionLocked, isTrue);

      notifier.unlockAll();

      expect(notifier.state.spendingLocked, isFalse);
      expect(notifier.state.savingLocked, isFalse);
      expect(notifier.state.protectionLocked, isFalse);
      expect(notifier.state.lockedSpendingPct, isNull);
      expect(notifier.state.lockedSavingPct, isNull);
      expect(notifier.state.lockedProtectionPct, isNull);
    });
  });
}
