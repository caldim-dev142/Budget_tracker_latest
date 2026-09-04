import 'package:equatable/equatable.dart';
import '../../core/utils/money.dart';

/// Sinking fund / envelope (Protection sheet, doc 01 §4).
/// Each fund has a reserve that accumulates contributions and pays out withdrawals.
///
/// Classic sinking-fund formula (doc 01 §4):
///   Reserve_X(end) = Reserve_X(start) + Σ("To MF for X") − Σ("Spending for X")
class SinkingFund extends Equatable {
  final String id;
  final String householdId;
  final String name;
  final Money openingReserve;      // from Annexure register at month start
  final List<FundMovement> movements;
  final DateTime? archivedAt;

  const SinkingFund({
    required this.id,
    required this.householdId,
    required this.name,
    required this.openingReserve,
    this.movements = const [],
    this.archivedAt,
  });

  Money get contributions =>
      movements.where((m) => m.type == MovementType.contribution).fold(
        Money.zero,
        (s, m) => s + m.amount,
      );

  Money get withdrawals =>
      movements.where((m) => m.type == MovementType.withdrawal).fold(
        Money.zero,
        (s, m) => s + m.amount,
      );

  /// Closing reserve = opening + contributions − withdrawals (doc 01 §4).
  /// CAN be negative — flag but allow (doc 02 §5 edge 5).
  Money get closingReserve => openingReserve + contributions - withdrawals;

  bool get isNegativeReserve => closingReserve.isNegative;

  @override
  List<Object?> get props => [id, name, openingReserve, movements];
}

enum MovementType { contribution, withdrawal }

class FundMovement extends Equatable {
  final String id;
  final String fundId;
  final MovementType type;
  final Money amount;
  final DateTime movementDate;
  final String? note;

  const FundMovement({
    required this.id,
    required this.fundId,
    required this.type,
    required this.amount,
    required this.movementDate,
    this.note,
  });

  @override
  List<Object?> get props => [id, fundId, type, amount, movementDate];
}
