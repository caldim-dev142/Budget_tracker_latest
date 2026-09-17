import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/secure_store.dart';

/// State model representing locked percentages in Plan Distribution.
class PlanDistributionLockState {
  final bool spendingLocked;
  final bool savingLocked;
  final bool protectionLocked;
  final double? lockedSpendingPct;
  final double? lockedSavingPct;
  final double? lockedProtectionPct;

  const PlanDistributionLockState({
    this.spendingLocked = false,
    this.savingLocked = false,
    this.protectionLocked = false,
    this.lockedSpendingPct,
    this.lockedSavingPct,
    this.lockedProtectionPct,
  });

  PlanDistributionLockState copyWith({
    bool? spendingLocked,
    bool? savingLocked,
    bool? protectionLocked,
    double? Function()? lockedSpendingPct,
    double? Function()? lockedSavingPct,
    double? Function()? lockedProtectionPct,
  }) {
    return PlanDistributionLockState(
      spendingLocked: spendingLocked ?? this.spendingLocked,
      savingLocked: savingLocked ?? this.savingLocked,
      protectionLocked: protectionLocked ?? this.protectionLocked,
      lockedSpendingPct: lockedSpendingPct != null
          ? lockedSpendingPct()
          : this.lockedSpendingPct,
      lockedSavingPct:
          lockedSavingPct != null ? lockedSavingPct() : this.lockedSavingPct,
      lockedProtectionPct: lockedProtectionPct != null
          ? lockedProtectionPct()
          : this.lockedProtectionPct,
    );
  }

  Map<String, dynamic> toJson() => {
        'spendingLocked': spendingLocked,
        'savingLocked': savingLocked,
        'protectionLocked': protectionLocked,
        'lockedSpendingPct': lockedSpendingPct,
        'lockedSavingPct': lockedSavingPct,
        'lockedProtectionPct': lockedProtectionPct,
      };

  factory PlanDistributionLockState.fromJson(Map<String, dynamic> json) {
    return PlanDistributionLockState(
      spendingLocked: json['spendingLocked'] as bool? ?? false,
      savingLocked: json['savingLocked'] as bool? ?? false,
      protectionLocked: json['protectionLocked'] as bool? ?? false,
      lockedSpendingPct: (json['lockedSpendingPct'] as num?)?.toDouble(),
      lockedSavingPct: (json['lockedSavingPct'] as num?)?.toDouble(),
      lockedProtectionPct: (json['lockedProtectionPct'] as num?)?.toDouble(),
    );
  }
}

class PlanDistributionLockNotifier
    extends StateNotifier<PlanDistributionLockState> {
  final String householdId;

  PlanDistributionLockNotifier(this.householdId)
      : super(const PlanDistributionLockState()) {
    _loadFromStorage();
  }

  String get _storageKey => 'plan_dist_locks_$householdId';

  Future<void> _loadFromStorage() async {
    try {
      final raw = await SecureStore.read(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        state = PlanDistributionLockState.fromJson(map);
      }
    } catch (_) {
      // Fallback to default unlocked state
    }
  }

  Future<void> _persist() async {
    try {
      final jsonStr = jsonEncode(state.toJson());
      await SecureStore.write(_storageKey, jsonStr);
    } catch (_) {}
  }

  void toggleLock(String layer, double currentPct) {
    if (layer == 'spending') {
      final newLock = !state.spendingLocked;
      state = state.copyWith(
        spendingLocked: newLock,
        lockedSpendingPct: () => newLock ? currentPct : null,
      );
    } else if (layer == 'saving') {
      final newLock = !state.savingLocked;
      state = state.copyWith(
        savingLocked: newLock,
        lockedSavingPct: () => newLock ? currentPct : null,
      );
    } else if (layer == 'protection') {
      final newLock = !state.protectionLocked;
      state = state.copyWith(
        protectionLocked: newLock,
        lockedProtectionPct: () => newLock ? currentPct : null,
      );
    }
    _persist();
  }

  void setLockedValue(String layer, double pct) {
    if (layer == 'spending' && state.spendingLocked) {
      state = state.copyWith(lockedSpendingPct: () => pct);
    } else if (layer == 'saving' && state.savingLocked) {
      state = state.copyWith(lockedSavingPct: () => pct);
    } else if (layer == 'protection' && state.protectionLocked) {
      state = state.copyWith(lockedProtectionPct: () => pct);
    }
    _persist();
  }

  void unlockAll() {
    state = const PlanDistributionLockState();
    _persist();
  }
}

/// Household-scoped provider for PlanDistributionLockState.
final planDistributionLockProvider = StateNotifierProvider.family<
    PlanDistributionLockNotifier, PlanDistributionLockState, String>(
  (ref, householdId) {
    return PlanDistributionLockNotifier(householdId);
  },
);
