import 'package:equatable/equatable.dart';
import '../../core/utils/money.dart';

/// Credit card ledger (Credit card sheet, doc 01 §9).
///
/// Outstanding = previousOutstanding + Σ(txn.amount)
/// Payments have negative amount; spends positive; cashbacks negative.
///
/// Card delta feeds the Adjustments block automatically (doc 01 §2.2):
///   adjustment = currentOutstanding − previousOutstanding
class CreditCard extends Equatable {
  final String id;
  final String householdId;
  final String name;
  final Money previousOutstanding; // seed (CAN be negative: doc 02 §5 edge 6)
  final List<CardTransaction> txns;
  final bool isActive;

  const CreditCard({
    required this.id,
    required this.householdId,
    required this.name,
    required this.previousOutstanding,
    this.txns = const [],
    this.isActive = true,
  });

  /// Current outstanding = previous + Σ(all txn amounts, signed).
  Money get currentOutstanding =>
      previousOutstanding + txns.fold(Money.zero, (s, t) => s + t.amount);

  /// Month delta = current − previous (feeds Adjustments, doc 01 §2.2).
  Money get monthDelta => currentOutstanding - previousOutstanding;

  @override
  List<Object?> get props => [id, name, previousOutstanding, txns, isActive];
}

class CardTransaction extends Equatable {
  final String id;
  final String cardId;
  final DateTime txnDate;
  final String description;
  final Money amount;    // payment < 0, spend > 0, cashback < 0 (doc 07)
  final int? sNo;

  const CardTransaction({
    required this.id,
    required this.cardId,
    required this.txnDate,
    required this.description,
    required this.amount,
    this.sNo,
  });

  @override
  List<Object?> get props => [id, cardId, txnDate, amount];
}
