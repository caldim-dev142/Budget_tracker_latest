import 'package:flutter/material.dart';

/// Single source of truth for every category's visual identity.
///
/// Keyed by stable category ID (never by display name, which is editable).
/// Use this map everywhere a category icon or color is needed:
///   - Category picker
///   - Transaction list
///   - Budget bars
///   - Reports
///
/// Icon conventions:
///   Selected state  → `Icons.*_rounded` (filled)
///   Unselected state → swap to `Icons.*_outlined` where Material provides both
///
/// Wrap icon-only renders in `Semantics(label: category.name)` for accessibility.
class CategoryVisual {
  final IconData icon;
  final Color color;
  const CategoryVisual(this.icon, this.color);
}

// ─── Semantic group colors ────────────────────────────────────────────────────
const _kIncomeGreen      = Color(0xFF2E7D32);  // Green 800
const _kDeductionRed     = Color(0xFFC62828);  // Red 800
const _kAdjustmentBlueGrey = Color(0xFF546E7A); // BlueGrey 600
const _kFeesAmber        = Color(0xFFF57F17);  // Amber 900
const _kNeedsTeal        = Color(0xFF00897B);  // Teal 600
const _kWantsPurple      = Color(0xFF7B1FA2);  // Purple 700
const _kTravelIndigo     = Color(0xFF283593);  // Indigo 800
const _kHonorariumBrown  = Color(0xFF5D4037);  // Brown 600
const _kUnplannedOrange  = Color(0xFFE65100);  // DeepOrange 900
const _kPurchasePink     = Color(0xFFAD1457);  // Pink 800
const _kProtectionCyan   = Color(0xFF00838F);  // Cyan 800
const _kSavRetirement    = Color(0xFF4527A0);  // DeepPurple 800
const _kSavChildren      = Color(0xFF1565C0);  // Blue 800
const _kSavGoals         = Color(0xFFE65100);  // Orange 900

const Map<String, CategoryVisual> categoryVisuals = {
  // ─── INCOME (green family) ────────────────────────────────────────────────
  'inc-01': CategoryVisual(Icons.work_outline_rounded,         _kIncomeGreen),
  'inc-02': CategoryVisual(Icons.work_outline_rounded,         _kIncomeGreen),
  'inc-03': CategoryVisual(Icons.elderly_rounded,              _kIncomeGreen),
  'inc-04': CategoryVisual(Icons.card_giftcard_rounded,        _kIncomeGreen),
  'inc-05': CategoryVisual(Icons.volunteer_activism_rounded,   _kIncomeGreen),
  'inc-06': CategoryVisual(Icons.account_balance_rounded,      _kIncomeGreen),
  'inc-07': CategoryVisual(Icons.health_and_safety_rounded,    _kIncomeGreen),
  'inc-08': CategoryVisual(Icons.trending_up_rounded,          _kIncomeGreen),
  'inc-09': CategoryVisual(Icons.home_work_rounded,            _kIncomeGreen),
  'inc-10': CategoryVisual(Icons.pie_chart_rounded,            _kIncomeGreen),
  'inc-11': CategoryVisual(Icons.redeem_rounded,               _kIncomeGreen),
  'inc-12': CategoryVisual(Icons.receipt_long_rounded,         _kIncomeGreen),

  // ─── INCOME DEDUCTIONS (red family) ───────────────────────────────────────
  'ded-01': CategoryVisual(Icons.gavel_rounded,                _kDeductionRed),
  'ded-02': CategoryVisual(Icons.remove_circle_outline_rounded, _kDeductionRed),

  // ─── ADJUSTMENTS (blue-grey family) ───────────────────────────────────────
  'adj-01': CategoryVisual(Icons.credit_card_rounded,          _kAdjustmentBlueGrey),
  'adj-02': CategoryVisual(Icons.swap_horiz_rounded,           _kAdjustmentBlueGrey),
  'adj-03': CategoryVisual(Icons.sync_alt_rounded,             _kAdjustmentBlueGrey),
  'adj-04': CategoryVisual(Icons.call_received_rounded,        _kAdjustmentBlueGrey),
  'adj-05': CategoryVisual(Icons.call_made_rounded,            _kAdjustmentBlueGrey),
  'adj-06': CategoryVisual(Icons.output_rounded,               _kAdjustmentBlueGrey),

  // ─── SPENDING — Fees & Utility Payments (amber) ───────────────────────────
  'spd-f01': CategoryVisual(Icons.bolt_rounded,                 _kFeesAmber),
  'spd-f02': CategoryVisual(Icons.bolt_rounded,                 _kFeesAmber),
  'spd-f03': CategoryVisual(Icons.wifi_rounded,                 _kFeesAmber),
  'spd-f04': CategoryVisual(Icons.apartment_rounded,            _kFeesAmber),
  'spd-f05': CategoryVisual(Icons.tv_rounded,                   _kFeesAmber),
  'spd-f06': CategoryVisual(Icons.school_rounded,               _kFeesAmber),
  'spd-f07': CategoryVisual(Icons.local_fire_department_rounded, _kFeesAmber),
  'spd-f08': CategoryVisual(Icons.credit_score_rounded,         _kFeesAmber),
  'spd-f09': CategoryVisual(Icons.receipt_rounded,              _kFeesAmber),
  'spd-f10': CategoryVisual(Icons.water_drop_rounded,           _kFeesAmber),
  'spd-f11': CategoryVisual(Icons.miscellaneous_services_rounded, _kFeesAmber),

  // ─── SPENDING — Living Expenses / Needs (teal) ────────────────────────────
  'spd-n01': CategoryVisual(Icons.spa_rounded,                  _kNeedsTeal),
  'spd-n02': CategoryVisual(Icons.eco_rounded,                  _kNeedsTeal),
  'spd-n03': CategoryVisual(Icons.set_meal_rounded,             _kNeedsTeal),
  'spd-n04': CategoryVisual(Icons.water_drop_rounded,           _kNeedsTeal),
  'spd-n05': CategoryVisual(Icons.local_grocery_store_rounded,  _kNeedsTeal),
  'spd-n06': CategoryVisual(Icons.shopping_basket_rounded,      _kNeedsTeal),
  'spd-n07': CategoryVisual(Icons.local_pharmacy_rounded,       _kNeedsTeal),
  'spd-n08': CategoryVisual(Icons.opacity_rounded,              _kNeedsTeal),
  'spd-n09': CategoryVisual(Icons.cleaning_services_rounded,    _kNeedsTeal),
  'spd-n10': CategoryVisual(Icons.child_friendly_rounded,       _kNeedsTeal),
  'spd-n11': CategoryVisual(Icons.face_rounded,                 _kNeedsTeal),
  'spd-n12': CategoryVisual(Icons.checkroom_rounded,            _kNeedsTeal),
  'spd-n13': CategoryVisual(Icons.more_horiz_rounded,           _kNeedsTeal),

  // ─── SPENDING — Lifestyle / Wants (purple) ────────────────────────────────
  'spd-w01': CategoryVisual(Icons.favorite_rounded,             _kWantsPurple),
  'spd-w02': CategoryVisual(Icons.restaurant_rounded,           _kWantsPurple),
  'spd-w03': CategoryVisual(Icons.celebration_rounded,          _kWantsPurple),
  'spd-w04': CategoryVisual(Icons.local_cafe_rounded,           _kWantsPurple),
  'spd-w05': CategoryVisual(Icons.fitness_center_rounded,       _kWantsPurple),
  'spd-w06': CategoryVisual(Icons.toys_rounded,                 _kWantsPurple),
  'spd-w07': CategoryVisual(Icons.menu_book_rounded,            _kWantsPurple),
  'spd-w08': CategoryVisual(Icons.content_cut_rounded,          _kWantsPurple),
  'spd-w09': CategoryVisual(Icons.play_circle_rounded,          _kWantsPurple),
  'spd-w10': CategoryVisual(Icons.cake_rounded,                 _kWantsPurple),
  'spd-w11': CategoryVisual(Icons.interests_rounded,            _kWantsPurple),

  // ─── SPENDING — Travel (indigo) ───────────────────────────────────────────
  'spd-t01': CategoryVisual(Icons.flight_takeoff_rounded,       _kTravelIndigo),
  'spd-t02': CategoryVisual(Icons.restaurant_menu_rounded,      _kTravelIndigo),
  'spd-t03': CategoryVisual(Icons.local_gas_station_rounded,    _kTravelIndigo),
  'spd-t04': CategoryVisual(Icons.local_taxi_rounded,           _kTravelIndigo),
  'spd-t05': CategoryVisual(Icons.local_gas_station_rounded,    _kTravelIndigo),
  'spd-t06': CategoryVisual(Icons.build_rounded,                _kTravelIndigo),
  'spd-t07': CategoryVisual(Icons.local_parking_rounded,        _kTravelIndigo),
  'spd-t08': CategoryVisual(Icons.directions_bus_rounded,       _kTravelIndigo),
  'spd-t09': CategoryVisual(Icons.two_wheeler_rounded,          _kTravelIndigo),

  // ─── SPENDING — Honorariums (brown) ───────────────────────────────────────
  'spd-h01': CategoryVisual(Icons.volunteer_activism_rounded,   _kHonorariumBrown),
  'spd-h02': CategoryVisual(Icons.volunteer_activism_rounded,   _kHonorariumBrown),
  'spd-h03': CategoryVisual(Icons.volunteer_activism_rounded,   _kHonorariumBrown),
  'spd-h04': CategoryVisual(Icons.volunteer_activism_rounded,   _kHonorariumBrown),

  // ─── SPENDING — Unplanned (deep orange) ───────────────────────────────────
  'spd-u01': CategoryVisual(Icons.warning_amber_rounded,        _kUnplannedOrange),
  'spd-u02': CategoryVisual(Icons.warning_amber_rounded,        _kUnplannedOrange),
  'spd-u03': CategoryVisual(Icons.warning_amber_rounded,        _kUnplannedOrange),
  'spd-u04': CategoryVisual(Icons.warning_amber_rounded,        _kUnplannedOrange),
  'spd-u05': CategoryVisual(Icons.warning_amber_rounded,        _kUnplannedOrange),
  'spd-u06': CategoryVisual(Icons.help_outline_rounded,         _kUnplannedOrange),

  // ─── SPENDING — Purchase & Miscellaneous (pink) ───────────────────────────
  'spd-m01': CategoryVisual(Icons.devices_rounded,              _kPurchasePink),
  'spd-m02': CategoryVisual(Icons.checkroom_rounded,            _kPurchasePink),
  'spd-m03': CategoryVisual(Icons.card_giftcard_rounded,        _kPurchasePink),
  'spd-m04': CategoryVisual(Icons.diamond_rounded,              _kPurchasePink),
  'spd-m05': CategoryVisual(Icons.event_rounded,                _kPurchasePink),
  'spd-m06': CategoryVisual(Icons.chair_rounded,                _kPurchasePink),
  'spd-m07': CategoryVisual(Icons.kitchen_rounded,              _kPurchasePink),
  'spd-m08': CategoryVisual(Icons.shopping_bag_rounded,         _kPurchasePink),

  // ─── PROTECTION — Insurance Premiums (cyan) ───────────────────────────────
  'pro-i01': CategoryVisual(Icons.security_rounded,             _kProtectionCyan),
  'pro-i02': CategoryVisual(Icons.shield_rounded,               _kProtectionCyan),

  // ─── PROTECTION — Depreciating Assets ─────────────────────────────────────
  'pro-d01': CategoryVisual(Icons.directions_car_filled_rounded, _kProtectionCyan),
  'pro-d02': CategoryVisual(Icons.car_repair_rounded,           _kProtectionCyan),

  // ─── PROTECTION — Good/Bad Events ─────────────────────────────────────────
  'pro-g01': CategoryVisual(Icons.event_available_rounded,      _kProtectionCyan),
  'pro-g02': CategoryVisual(Icons.event_busy_rounded,           _kProtectionCyan),

  // ─── PROTECTION — Vacation ────────────────────────────────────────────────
  'pro-v01': CategoryVisual(Icons.beach_access_rounded,         _kProtectionCyan),
  'pro-v02': CategoryVisual(Icons.luggage_rounded,              _kProtectionCyan),

  // ─── PROTECTION — Medical Emergency ───────────────────────────────────────
  'pro-m01': CategoryVisual(Icons.local_hospital_rounded,       _kProtectionCyan),
  'pro-m02': CategoryVisual(Icons.medical_services_rounded,     _kProtectionCyan),

  // ─── PROTECTION — Property Maintenance ────────────────────────────────────
  'pro-p01': CategoryVisual(Icons.home_repair_service_rounded,  _kProtectionCyan),
  'pro-p02': CategoryVisual(Icons.construction_rounded,         _kProtectionCyan),

  // ─── PROTECTION — Others' Emergency ───────────────────────────────────────
  'pro-o01': CategoryVisual(Icons.people_rounded,               _kProtectionCyan),
  'pro-o02': CategoryVisual(Icons.handshake_rounded,            _kProtectionCyan),

  // ─── PROTECTION — Buffer ──────────────────────────────────────────────────
  'pro-b01': CategoryVisual(Icons.savings_rounded,              _kProtectionCyan),
  'pro-b02': CategoryVisual(Icons.account_balance_wallet_rounded, _kProtectionCyan),

  // ─── SAVING — Retirement (deep purple) ────────────────────────────────────
  'sav-r01': CategoryVisual(Icons.savings_rounded,              _kSavRetirement),
  'sav-r02': CategoryVisual(Icons.account_balance_rounded,      _kSavRetirement),
  'sav-r03': CategoryVisual(Icons.trending_up_rounded,          _kSavRetirement),
  'sav-r04': CategoryVisual(Icons.elderly_rounded,              _kSavRetirement),

  // ─── SAVING — Children (blue) ─────────────────────────────────────────────
  'sav-c01': CategoryVisual(Icons.school_rounded,               _kSavChildren),
  'sav-c02': CategoryVisual(Icons.school_rounded,               _kSavChildren),
  'sav-c03': CategoryVisual(Icons.celebration_rounded,          _kSavChildren),
  'sav-c04': CategoryVisual(Icons.celebration_rounded,          _kSavChildren),
  'sav-c05': CategoryVisual(Icons.diamond_rounded,              _kSavChildren),

  // ─── SAVING — Other Goals (orange) ────────────────────────────────────────
  'sav-g01': CategoryVisual(Icons.directions_car_rounded,       _kSavGoals),
  'sav-g02': CategoryVisual(Icons.house_rounded,                _kSavGoals),
  'sav-g03': CategoryVisual(Icons.trending_up_rounded,          _kSavGoals),
  'sav-g04': CategoryVisual(Icons.trending_up_rounded,          _kSavGoals),
  'sav-g05': CategoryVisual(Icons.trending_up_rounded,          _kSavGoals),
};

// ─── Fallback for unknown / future category IDs ─────────────────────────────

/// Returns the [CategoryVisual] for [categoryId], or a neutral grey fallback
/// if the ID isn't in the map (e.g. a user-created custom category).
CategoryVisual getCategoryVisual(String categoryId) {
  return categoryVisuals[categoryId] ??
      const CategoryVisual(Icons.category_rounded, Color(0xFF757575));
}

/// Convenience: returns a color for a category group code (used by reports
/// and charts that colour by group rather than individual category).
Color getGroupColor(String? groupCode) {
  return switch (groupCode) {
    'fees'                => _kFeesAmber,
    'needs'               => _kNeedsTeal,
    'wants'               => _kWantsPurple,
    'travel'              => _kTravelIndigo,
    'honorarium'          => _kHonorariumBrown,
    'unplanned'           => _kUnplannedOrange,
    'purchase_misc'       => _kPurchasePink,
    'insurance'           => _kProtectionCyan,
    'depreciating_assets' => _kProtectionCyan,
    'good_bad_events'     => _kProtectionCyan,
    'vacation'            => _kProtectionCyan,
    'medical_emergency'   => _kProtectionCyan,
    'property_maintenance'=> _kProtectionCyan,
    'others_emergency'    => _kProtectionCyan,
    'buffer'              => _kProtectionCyan,
    'retirement'          => _kSavRetirement,
    'children'            => _kSavChildren,
    'other_goals'         => _kSavGoals,
    _                     => const Color(0xFF757575),
  };
}
