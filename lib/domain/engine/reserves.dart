import '../../core/utils/money.dart';

/// Reserves calculation engine (doc 01 §4, doc 15 §1).
/// Factored out for testability.
class ReservesEngine {
  ReservesEngine._();

  /// Closing reserve formula (doc 01 §4):
  ///   closingReserve = openingReserve + Σ(contributions) − Σ(withdrawals)
  ///
  /// CAN be negative — flag but allow (doc 02 §5 edge 5).
  static Money closingReserve({
    required Money openingReserve,
    required Money contributions,
    required Money withdrawals,
  }) {
    return openingReserve + contributions - withdrawals;
  }

  /// Total reserves set aside across all funds at month close.
  /// Used to feed the Annexure / waterfall Reserves layer.
  static Money totalReserves(
    List<Money> closingReserves,
  ) {
    return closingReserves.fold(Money.zero, (s, r) => s + r);
  }
}
