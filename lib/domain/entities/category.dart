import 'package:equatable/equatable.dart';
import 'entry.dart';

/// Spending group codes (doc 01 §3, doc 05 categories.group_code).
enum SpendGroup {
  fees,           // Fees & Utility Payments
  needs,          // Living Expenses (Needs)
  wants,          // Lifestyle Expenses (Wants)
  travel,         // Travel Expenses
  honorarium,     // Honorariums
  unplanned,      // Unplanned Expenses
  purchaseMisc,   // Purchase & Miscellaneous
}

/// Protection / sinking-fund group codes (doc 01 §4).
enum ProtectionGroup {
  insurance,          // Insurance Premiums
  depreciatingAssets, // Depreciating Assets
  goodBadEvents,      // Good/Bad Events
  vacation,           // Vacation
  medicalEmergency,   // Medical Emergency
  propertyMaintenance,// Property Maintenance
  othersEmergency,    // Funding for Others' Emergency
  buffer,             // Buffer Protection
}

/// Saving goal buckets (doc 01 §5).
enum SavingBucket {
  retirement,   // For Retirement
  children,     // For Children
  otherGoals,   // For Other Goals
}

/// Need/Want classification for spending categories (doc 01 §3, doc 02 §FR-SPD-3).
enum NeedOrWant { need, want }

/// A category record. Seeded from the workbook taxonomy.
class Category extends Equatable {
  final String id;
  final String householdId;
  final EntryKind kind;
  final String? groupCode;       // SpendGroup.name / ProtectionGroup.name / SavingBucket.name
  final String name;
  final NeedOrWant? needOrWant;  // only spending
  final bool isDeduction;        // Income Tax, Other Deduction
  final bool isSystem;           // e.g. Untallied amount
  final int sortOrder;
  final DateTime? archivedAt;    // soft-delete (doc 02 §5 edge 10)

  const Category({
    required this.id,
    required this.householdId,
    required this.kind,
    this.groupCode,
    required this.name,
    this.needOrWant,
    this.isDeduction = false,
    this.isSystem = false,
    this.sortOrder = 0,
    this.archivedAt,
  });

  bool get isArchived => archivedAt != null;

  @override
  List<Object?> get props => [id, kind, groupCode, name, isDeduction, isSystem, archivedAt];
}
