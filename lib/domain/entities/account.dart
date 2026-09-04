import 'package:equatable/equatable.dart';
import '../../core/utils/money.dart';

/// Bank account or cash-in-hand (Summary R14–R23, doc 01 §7.4).
/// Total Available = SUM(all account balances).
class Account extends Equatable {
  final String id;
  final String householdId;
  final String name;
  final AccountType type;
  final Money currentBalance;
  final bool isActive;
  final int sortOrder;

  const Account({
    required this.id,
    required this.householdId,
    required this.name,
    required this.type,
    required this.currentBalance,
    this.isActive = true,
    this.sortOrder = 0,
  });

  @override
  List<Object?> get props => [id, name, type, currentBalance, isActive];
}

enum AccountType { bank, cash }
