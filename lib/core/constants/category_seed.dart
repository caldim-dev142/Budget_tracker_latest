import '../../domain/entities/category.dart';
import '../../domain/entities/entry.dart';

/// Complete category taxonomy seeded from the workbook (doc 01 §2–5, doc 05 §categories).
/// A new household starts with this full structure.
///
/// Total: 14 income + 6 adjustment + ~80 spending + ~24 protection + ~17 saving = ~141 categories.
const String _systemHouseholdId = 'seed';

List<Category> buildSeedCategories(String householdId) {
  return [
    // ─── INCOME (doc 01 §2.1) ───────────────────────────────────────────────
    _cat(householdId, 'inc-01', EntryKind.income, null, 'Person 1 Salary & Allowance', sortOrder: 1),
    _cat(householdId, 'inc-02', EntryKind.income, null, 'Person 2 Salary & Allowance', sortOrder: 2),
    _cat(householdId, 'inc-03', EntryKind.income, null, 'Parents Pension', sortOrder: 3),
    _cat(householdId, 'inc-04', EntryKind.income, null, 'Bonus', sortOrder: 4),
    _cat(householdId, 'inc-05', EntryKind.income, null, 'From Donors/Others', sortOrder: 5),
    _cat(householdId, 'inc-06', EntryKind.income, null, 'Bank Interest', sortOrder: 6),
    _cat(householdId, 'inc-07', EntryKind.income, null, 'Income from Insurance', sortOrder: 7),
    _cat(householdId, 'inc-08', EntryKind.income, null, 'Income from Investments', sortOrder: 8),
    _cat(householdId, 'inc-09', EntryKind.income, null, 'Rental Income', sortOrder: 9),
    _cat(householdId, 'inc-10', EntryKind.income, null, 'Dividend', sortOrder: 10),
    _cat(householdId, 'inc-11', EntryKind.income, null, 'Cashbacks', sortOrder: 11),
    _cat(householdId, 'inc-12', EntryKind.income, null, 'Unlisted Income/Spending(-)', sortOrder: 12),
    // Income deductions (doc 01 §2.1)
    _cat(householdId, 'ded-01', EntryKind.incomeDeduction, null, 'Income Tax', sortOrder: 1, isDeduction: true),
    _cat(householdId, 'ded-02', EntryKind.incomeDeduction, null, 'Other Deduction', sortOrder: 2, isDeduction: true),

    // ─── ADJUSTMENTS (doc 01 §2.2) ──────────────────────────────────────────
    _cat(householdId, 'adj-01', EntryKind.adjustment, null, 'Credit Card Borrow/Payment', sortOrder: 1),
    _cat(householdId, 'adj-02', EntryKind.adjustment, null, 'Borrow/Return(-)', sortOrder: 2),
    _cat(householdId, 'adj-03', EntryKind.adjustment, null, 'Temporary In/Out(-)', sortOrder: 3),
    _cat(householdId, 'adj-04', EntryKind.adjustment, null, 'Others(Inflow)', sortOrder: 4),
    _cat(householdId, 'adj-05', EntryKind.adjustment, null, 'Lending/Return(-)', sortOrder: 5, isDeduction: true),
    _cat(householdId, 'adj-06', EntryKind.adjustment, null, 'Others(Outflow)', sortOrder: 6, isDeduction: true),

    // ─── SPENDING — Fees & Utility Payments (doc 01 §3) ────────────────────
    _spend(householdId, 'spd-f01', 'fees', 'Electricity Bill 1', NeedOrWant.need, 1),
    _spend(householdId, 'spd-f02', 'fees', 'Electricity Bill 2', NeedOrWant.need, 2),
    _spend(householdId, 'spd-f03', 'fees', 'Telephone/Internet', NeedOrWant.need, 3),
    _spend(householdId, 'spd-f04', 'fees', 'Apartment Maintenance', NeedOrWant.need, 4),
    _spend(householdId, 'spd-f05', 'fees', 'DTH/OTT Subscriptions', NeedOrWant.want, 5),
    _spend(householdId, 'spd-f06', 'fees', 'Schooling/Education Fees', NeedOrWant.need, 6),
    _spend(householdId, 'spd-f07', 'fees', 'LPG/Cooking Gas', NeedOrWant.need, 7),
    _spend(householdId, 'spd-f08', 'fees', 'Credit Card Annual Fees', NeedOrWant.need, 8),
    _spend(householdId, 'spd-f09', 'fees', 'Property Tax', NeedOrWant.need, 9),
    _spend(householdId, 'spd-f10', 'fees', 'Water/Sewage Bill', NeedOrWant.need, 10),
    _spend(householdId, 'spd-f11', 'fees', 'Other Utility', NeedOrWant.need, 11),

    // ─── SPENDING — Living Expenses / Needs (doc 01 §3) ────────────────────
    _spend(householdId, 'spd-n01', 'needs', 'Temple/Pooja/Religious', NeedOrWant.need, 1),
    _spend(householdId, 'spd-n02', 'needs', 'Vegetables & Fruits', NeedOrWant.need, 2),
    _spend(householdId, 'spd-n03', 'needs', 'Meat & Fish', NeedOrWant.need, 3),
    _spend(householdId, 'spd-n04', 'needs', 'Milk & Dairy', NeedOrWant.need, 4),
    _spend(householdId, 'spd-n05', 'needs', 'Grocery - Edible', NeedOrWant.need, 5),
    _spend(householdId, 'spd-n06', 'needs', 'Grocery - Non Edible', NeedOrWant.need, 6),
    _spend(householdId, 'spd-n07', 'needs', 'Medical/Pharmacy', NeedOrWant.need, 7),
    _spend(householdId, 'spd-n08', 'needs', 'Cooking Oil', NeedOrWant.need, 8),
    _spend(householdId, 'spd-n09', 'needs', 'Domestic Help', NeedOrWant.need, 9),
    _spend(householdId, 'spd-n10', 'needs', 'Baby/Child Needs', NeedOrWant.need, 10),
    _spend(householdId, 'spd-n11', 'needs', 'Personal Care', NeedOrWant.need, 11),
    _spend(householdId, 'spd-n12', 'needs', 'Clothing - Basic', NeedOrWant.need, 12),
    _spend(householdId, 'spd-n13', 'needs', 'Other Needs', NeedOrWant.need, 13),

    // ─── SPENDING — Lifestyle / Wants (doc 01 §3) ──────────────────────────
    _spend(householdId, 'spd-w01', 'wants', 'Charity/Donations', NeedOrWant.want, 1),
    _spend(householdId, 'spd-w02', 'wants', 'Hotel/Restaurant Food', NeedOrWant.want, 2),
    _spend(householdId, 'spd-w03', 'wants', 'Outing/Entertainment', NeedOrWant.want, 3),
    _spend(householdId, 'spd-w04', 'wants', 'Snacks/Beverages', NeedOrWant.want, 4),
    _spend(householdId, 'spd-w05', 'wants', 'Fitness/Sports', NeedOrWant.want, 5),
    _spend(householdId, 'spd-w06', 'wants', 'Toys/Games', NeedOrWant.want, 6),
    _spend(householdId, 'spd-w07', 'wants', 'Books/Courses', NeedOrWant.want, 7),
    _spend(householdId, 'spd-w08', 'wants', 'Salon/Beauty', NeedOrWant.want, 8),
    _spend(householdId, 'spd-w09', 'wants', 'Streaming/Apps', NeedOrWant.want, 9),
    _spend(householdId, 'spd-w10', 'wants', 'Party/Celebrations', NeedOrWant.want, 10),
    _spend(householdId, 'spd-w11', 'wants', 'Other Wants', NeedOrWant.want, 11),

    // ─── SPENDING — Travel (doc 01 §3) ─────────────────────────────────────
    _spend(householdId, 'spd-t01', 'travel', 'Outstation - Fare', NeedOrWant.want, 1),
    _spend(householdId, 'spd-t02', 'travel', 'Outstation - Food', NeedOrWant.want, 2),
    _spend(householdId, 'spd-t03', 'travel', 'Outstation - Fuel', NeedOrWant.want, 3),
    _spend(householdId, 'spd-t04', 'travel', 'Local Travel/Auto/Cab', NeedOrWant.need, 4),
    _spend(householdId, 'spd-t05', 'travel', 'Petrol/Fuel', NeedOrWant.need, 5),
    _spend(householdId, 'spd-t06', 'travel', 'Vehicle Maintenance', NeedOrWant.need, 6),
    _spend(householdId, 'spd-t07', 'travel', 'Road Tolls/Parking', NeedOrWant.need, 7),
    _spend(householdId, 'spd-t08', 'travel', 'Train/Bus Pass', NeedOrWant.need, 8),
    _spend(householdId, 'spd-t09', 'travel', 'Other Travel', NeedOrWant.want, 9),

    // ─── SPENDING — Honorariums (doc 01 §3) ────────────────────────────────
    _spend(householdId, 'spd-h01', 'honorarium', 'Beneficiary 1', NeedOrWant.need, 1),
    _spend(householdId, 'spd-h02', 'honorarium', 'Beneficiary 2', NeedOrWant.need, 2),
    _spend(householdId, 'spd-h03', 'honorarium', 'Beneficiary 3', NeedOrWant.need, 3),
    _spend(householdId, 'spd-h04', 'honorarium', 'Beneficiary 4', NeedOrWant.need, 4),

    // ─── SPENDING — Unplanned (doc 01 §3) ──────────────────────────────────
    _spend(householdId, 'spd-u01', 'unplanned', 'Unplanned Exp 1', NeedOrWant.need, 1),
    _spend(householdId, 'spd-u02', 'unplanned', 'Unplanned Exp 2', NeedOrWant.need, 2),
    _spend(householdId, 'spd-u03', 'unplanned', 'Unplanned Exp 3', NeedOrWant.need, 3),
    _spend(householdId, 'spd-u04', 'unplanned', 'Unplanned Exp 4', NeedOrWant.need, 4),
    _spend(householdId, 'spd-u05', 'unplanned', 'Unplanned Exp 5', NeedOrWant.need, 5),
    _cat(householdId, 'spd-u06', EntryKind.spending, 'unplanned', 'Untallied Amount',
        sortOrder: 6, isSystem: true),

    // ─── SPENDING — Purchase & Miscellaneous (doc 01 §3) ───────────────────
    _spend(householdId, 'spd-m01', 'purchase_misc', 'Gadgets/Electronics', NeedOrWant.want, 1),
    _spend(householdId, 'spd-m02', 'purchase_misc', 'Dress/Clothing', NeedOrWant.want, 2),
    _spend(householdId, 'spd-m03', 'purchase_misc', 'Gifts', NeedOrWant.want, 3),
    _spend(householdId, 'spd-m04', 'purchase_misc', 'Gold/Jewellery', NeedOrWant.want, 4),
    _spend(householdId, 'spd-m05', 'purchase_misc', 'Festivals/Occasions', NeedOrWant.want, 5),
    _spend(householdId, 'spd-m06', 'purchase_misc', 'Home Furnishings', NeedOrWant.want, 6),
    _spend(householdId, 'spd-m07', 'purchase_misc', 'Appliances', NeedOrWant.want, 7),
    _spend(householdId, 'spd-m08', 'purchase_misc', 'Other Purchases', NeedOrWant.want, 8),

    // ─── PROTECTION — Insurance Premiums (doc 01 §4) ────────────────────────
    _cat(householdId, 'pro-i01', EntryKind.protection, 'insurance', 'To MF for Insurance', sortOrder: 1),
    _cat(householdId, 'pro-i02', EntryKind.protection, 'insurance', 'Spending for Insurance', sortOrder: 2),

    // ─── PROTECTION — Depreciating Assets (doc 01 §4) ──────────────────────
    _cat(householdId, 'pro-d01', EntryKind.protection, 'depreciating_assets', 'To MF for Depreciating Assets', sortOrder: 1),
    _cat(householdId, 'pro-d02', EntryKind.protection, 'depreciating_assets', 'Spending for Depreciating Assets', sortOrder: 2),

    // ─── PROTECTION — Good/Bad Events (doc 01 §4) ──────────────────────────
    _cat(householdId, 'pro-g01', EntryKind.protection, 'good_bad_events', 'To MF for Good/Bad Events', sortOrder: 1),
    _cat(householdId, 'pro-g02', EntryKind.protection, 'good_bad_events', 'Spending for Good/Bad Events', sortOrder: 2),

    // ─── PROTECTION — Vacation (doc 01 §4) ─────────────────────────────────
    _cat(householdId, 'pro-v01', EntryKind.protection, 'vacation', 'To MF for Vacation', sortOrder: 1),
    _cat(householdId, 'pro-v02', EntryKind.protection, 'vacation', 'Spending for Vacation', sortOrder: 2),

    // ─── PROTECTION — Medical Emergency (doc 01 §4) ─────────────────────────
    _cat(householdId, 'pro-m01', EntryKind.protection, 'medical_emergency', 'To MF for Medical Emergency', sortOrder: 1),
    _cat(householdId, 'pro-m02', EntryKind.protection, 'medical_emergency', 'Spending for Medical Emergency', sortOrder: 2),

    // ─── PROTECTION — Property Maintenance (doc 01 §4) ─────────────────────
    _cat(householdId, 'pro-p01', EntryKind.protection, 'property_maintenance', 'To MF for Property Maintenance', sortOrder: 1),
    _cat(householdId, 'pro-p02', EntryKind.protection, 'property_maintenance', 'Spending for Property Maintenance', sortOrder: 2),

    // ─── PROTECTION — Others' Emergency (doc 01 §4) ─────────────────────────
    _cat(householdId, 'pro-o01', EntryKind.protection, 'others_emergency', 'To MF for Others Emergency', sortOrder: 1),
    _cat(householdId, 'pro-o02', EntryKind.protection, 'others_emergency', 'Spending for Others Emergency', sortOrder: 2),

    // ─── PROTECTION — Buffer Protection (doc 01 §4) ─────────────────────────
    _cat(householdId, 'pro-b01', EntryKind.protection, 'buffer', 'To MF for Buffer', sortOrder: 1),
    _cat(householdId, 'pro-b02', EntryKind.protection, 'buffer', 'Spending from Buffer', sortOrder: 2),

    // ─── SAVING — For Retirement (doc 01 §5) ────────────────────────────────
    _cat(householdId, 'sav-r01', EntryKind.saving, 'retirement', 'EPF/PPF Contribution', sortOrder: 1),
    _cat(householdId, 'sav-r02', EntryKind.saving, 'retirement', 'NPS Contribution', sortOrder: 2),
    _cat(householdId, 'sav-r03', EntryKind.saving, 'retirement', 'Retirement MF SIP', sortOrder: 3),
    _cat(householdId, 'sav-r04', EntryKind.saving, 'retirement', 'Other Retirement', sortOrder: 4),

    // ─── SAVING — For Children (doc 01 §5) ──────────────────────────────────
    _cat(householdId, 'sav-c01', EntryKind.saving, 'children', 'Child 1 Higher Education', sortOrder: 1),
    _cat(householdId, 'sav-c02', EntryKind.saving, 'children', 'Child 2 Higher Education', sortOrder: 2),
    _cat(householdId, 'sav-c03', EntryKind.saving, 'children', 'Child 1 Marriage', sortOrder: 3),
    _cat(householdId, 'sav-c04', EntryKind.saving, 'children', 'Child 2 Marriage', sortOrder: 4),
    _cat(householdId, 'sav-c05', EntryKind.saving, 'children', 'Gold/Jewellery for Children', sortOrder: 5),

    // ─── SAVING — For Other Goals (doc 01 §5) ───────────────────────────────
    _cat(householdId, 'sav-g01', EntryKind.saving, 'other_goals', 'Car Fund', sortOrder: 1),
    _cat(householdId, 'sav-g02', EntryKind.saving, 'other_goals', 'Dream Home Fund', sortOrder: 2),
    _cat(householdId, 'sav-g03', EntryKind.saving, 'other_goals', 'Other Investment 1', sortOrder: 3),
    _cat(householdId, 'sav-g04', EntryKind.saving, 'other_goals', 'Other Investment 2', sortOrder: 4),
    _cat(householdId, 'sav-g05', EntryKind.saving, 'other_goals', 'Other Investment 3', sortOrder: 5),
  ];
}

Category _cat(
  String householdId,
  String id,
  EntryKind kind,
  String? groupCode,
  String name, {
  int sortOrder = 0,
  bool isDeduction = false,
  bool isSystem = false,
}) {
  return Category(
    id: id,
    householdId: householdId,
    kind: kind,
    groupCode: groupCode,
    name: name,
    isDeduction: isDeduction,
    isSystem: isSystem,
    sortOrder: sortOrder,
  );
}

Category _spend(
  String householdId,
  String id,
  String groupCode,
  String name,
  NeedOrWant needOrWant,
  int sortOrder,
) {
  return Category(
    id: id,
    householdId: householdId,
    kind: EntryKind.spending,
    groupCode: groupCode,
    name: name,
    needOrWant: needOrWant,
    sortOrder: sortOrder,
  );
}
