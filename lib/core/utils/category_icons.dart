import 'package:flutter/material.dart';

/// Returns a semantically relevant [IconData] for a given category.
///
/// Matching priority:
/// 1. Name-based lookup (case-insensitive, token and substring match).
/// 2. GroupCode/Subcategory-based lookup.
/// 3. Combined text lookup.
/// 4. Kind-level curated modern fallback.
IconData categoryIcon(String name, String kind, [String? groupCode]) {
  // 1. Try matching against category name
  final iconFromName = _matchSemanticIcon(name);
  if (iconFromName != null) return iconFromName;

  // 2. Try matching against groupCode/subcategory if provided
  if (groupCode != null && groupCode.trim().isNotEmpty) {
    final iconFromGroup = _matchSemanticIcon(groupCode);
    if (iconFromGroup != null) return iconFromGroup;

    // Try combined
    final iconFromCombined = _matchSemanticIcon('$name $groupCode');
    if (iconFromCombined != null) return iconFromCombined;
  }

  // 3. GroupCode fallback legacy keys
  if (groupCode != null) {
    final g = groupCode.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    switch (g) {
      case 'fees':
      case 'fee':                 return Icons.receipt_rounded;
      case 'needs':
      case 'need':                return Icons.shopping_cart_rounded;
      case 'wants':
      case 'want':                return Icons.star_rounded;
      case 'travel':              return Icons.luggage_rounded;
      case 'honorarium':          return Icons.handshake_rounded;
      case 'unplanned':           return Icons.warning_amber_rounded;
      case 'purchasemisc':        return Icons.shopping_bag_rounded;
      case 'insurance':           return Icons.shield_rounded;
      case 'depreciatingassets':  return Icons.trending_down_rounded;
      case 'goodbadevents':       return Icons.event_rounded;
      case 'vacation':            return Icons.beach_access_rounded;
      case 'medicalemergency':    return Icons.emergency_rounded;
      case 'propertymaintenance': return Icons.build_rounded;
      case 'othersemergency':     return Icons.people_rounded;
      case 'buffer':              return Icons.account_balance_wallet_rounded;
      case 'retirement':          return Icons.account_balance_rounded;
      case 'children':            return Icons.child_care_rounded;
      case 'othergoals':          return Icons.flag_rounded;
    }
  }

  // 4. Kind-level final curated fallback (modern icons, never file/sheet)
  switch (kind.toLowerCase()) {
    case 'income':           return Icons.trending_up_rounded;
    case 'incomededuction':  return Icons.remove_circle_outline_rounded;
    case 'spending':         return _deterministicIcon(name, const [
      Icons.shopping_bag_rounded,
      Icons.local_offer_rounded,
      Icons.storefront_rounded,
      Icons.shopping_basket_rounded,
      Icons.category_rounded,
      Icons.loyalty_rounded,
    ]);
    case 'saving':           return Icons.savings_rounded;
    case 'protection':       return Icons.shield_rounded;
    case 'adjustment':       return Icons.swap_horiz_rounded;
    default:                 return Icons.category_rounded;
  }
}

/// Matches a string to a curated [IconData] based on semantic keywords and tokens.
IconData? _matchSemanticIcon(String input) {
  if (input.trim().isEmpty) return null;
  final n = input.toLowerCase();

  // ── Income ────────────────────────────────────────────────────────────────
  if (_contains(n, ['salary', 'payroll', 'wages', 'wage', 'paycheck'])) return Icons.payments_rounded;
  if (_contains(n, ['freelance', 'consulting', 'contract', 'gig', 'upwork', 'fiverr'])) return Icons.work_outline_rounded;
  if (_contains(n, ['bonus', 'incentive', 'reward', 'award', 'prize'])) return Icons.card_giftcard_rounded;
  if (_contains(n, ['dividend', 'investment return', 'capital gain', 'interest receive', 'interest credited', 'mutual fund return'])) return Icons.trending_up_rounded;
  if (_contains(n, ['rental', 'rent income', 'lease income', 'tenant'])) return Icons.apartment_rounded;
  if (_contains(n, ['pension', 'annuity', 'retirement income', 'provident fund payout', 'epf'])) return Icons.elderly_rounded;
  if (_contains(n, ['tax refund', 'tax deduction', 'gst refund', 'cashback', 'reimbursement'])) return Icons.receipt_rounded;
  if (_contains(n, ['allowance', 'stipend', 'pocket money'])) return Icons.account_balance_wallet_rounded;
  if (_contains(n, ['business', 'profit', 'revenue', 'turnover', 'sales'])) return Icons.store_rounded;

  // ── Food & Dining & Groceries ─────────────────────────────────────────────
  if (_contains(n, ['groceries', 'grocery', 'supermarket', 'market', 'vegetable', 'fruit', 'milk', 'dairy', 'provisions', 'kirana', 'non edible', 'ration'])) return Icons.local_grocery_store_rounded;
  if (_contains(n, ['oil', 'cooking oil', 'ghee', 'spices', 'staples', 'grain', 'rice', 'flour', 'cereal', 'atta', 'pulses', 'dal'])) return Icons.kitchen_rounded;
  if (_contains(n, ['bakery', 'bread', 'cake', 'pastry', 'snack', 'biscuit', 'cookies'])) return Icons.bakery_dining_rounded;
  if (_contains(n, ['meat', 'chicken', 'mutton', 'fish', 'seafood', 'prawn', 'egg', 'eggs'])) return Icons.set_meal_rounded;
  if (_contains(n, ['dining', 'restaurant', 'eating out', 'takeout', 'cafe', 'coffee', 'tea', 'chai', 'food', 'swiggy', 'zomato', 'ubereats', 'doordash', 'bistro', 'diner', 'lunch', 'dinner', 'breakfast', 'brunch', 'fast food', 'burger', 'pizza', 'sandwich'])) return Icons.restaurant_rounded;
  if (_contains(n, ['beverage', 'drink', 'soda', 'juice', 'liquor', 'wine', 'beer', 'alcohol', 'bar', 'pub', 'cocktail'])) return Icons.local_bar_rounded;

  // ── Housing & Maintenance ─────────────────────────────────────────────────
  if (_contains(n, ['rent', 'lease', 'landlord', 'mortgage', 'housing', 'house rent', 'flat rent'])) return Icons.home_rounded;
  if (_contains(n, ['maintenance', 'society fee', 'society', 'repair', 'plumb', 'electrician', 'carpenter', 'fix', 'painting'])) return Icons.build_rounded;
  if (_contains(n, ['property', 'real estate', 'plot', 'land', 'villa', 'apartment'])) return Icons.real_estate_agent_rounded;
  if (_contains(n, ['furnishing', 'furniture', 'home appliance', 'decor', 'bed', 'sofa', 'mattress', 'curtain'])) return Icons.chair_rounded;
  if (_contains(n, ['housekeeping', 'maid', 'cleaning', 'cleaner', 'sweeper', 'cook', 'domestic help', 'househelp', 'servant', 'driver', 'gardener'])) return Icons.cleaning_services_rounded;

  // ── Personal & Family Care ────────────────────────────────────────────────
  if (_contains(n, ['personal care', 'salon', 'barber', 'haircut', 'spa', 'cosmetics', 'grooming', 'beauty', 'toiletries', 'parlour', 'makeup', 'skincare', 'shampoo', 'soap', 'perfume'])) return Icons.face_retouching_natural_rounded;
  if (_contains(n, ['baby', 'child needs', 'infant', 'toddler', 'diaper', 'nursery', 'stroller', 'toys', 'daycare'])) return Icons.child_friendly_rounded;
  if (_contains(n, ['pet', 'dog', 'cat', 'veterinary', 'vet', 'pet food', 'aquarium'])) return Icons.pets_rounded;
  if (_contains(n, ['other needs', 'basic needs', 'daily need', 'essential', 'need'])) return Icons.shopping_basket_rounded;
  if (_contains(n, ['want', 'lifestyle', 'luxury', 'pleasure'])) return Icons.star_rounded;

  // ── Transport & Vehicle ───────────────────────────────────────────────────
  if (_contains(n, ['fuel', 'petrol', 'diesel', 'cng', 'gas station', 'ev charging', 'charging station'])) return Icons.local_gas_station_rounded;
  if (_contains(n, ['car', 'vehicle', 'auto', 'bike', 'motorcycle', 'scooter', 'two wheeler', 'four wheeler'])) return Icons.directions_car_rounded;
  if (_contains(n, ['transport', 'commute', 'fare', 'uber', 'grab', 'taxi', 'cab', 'ola', 'lyft', 'auto rickshaw', 'rickshaw'])) return Icons.directions_car_filled_rounded;
  if (_contains(n, ['parking', 'toll', 'fastag', 'tollway'])) return Icons.local_parking_rounded;
  if (_contains(n, ['bus', 'train', 'metro', 'subway', 'mrt', 'railway', 'irctc', 'tram'])) return Icons.directions_transit_rounded;
  if (_contains(n, ['flight', 'airfare', 'airline', 'airport', 'plane', 'indigo', 'air india', 'boarding'])) return Icons.flight_rounded;

  // ── Utilities & Bills ─────────────────────────────────────────────────────
  if (_contains(n, ['electricity', 'power', 'electric bill', 'current bill', 'light bill', 'eb bill'])) return Icons.bolt_rounded;
  if (_contains(n, ['water', 'sewage', 'water bill', 'tanker'])) return Icons.water_drop_rounded;
  if (_contains(n, ['gas', 'cooking gas', 'lpg', 'cylinder', 'piped gas', 'indane', 'hp gas', 'bharat gas'])) return Icons.local_fire_department_rounded;
  if (_contains(n, ['internet', 'broadband', 'wifi', 'data plan', 'fiber', 'jiofiber', 'airtel extreme'])) return Icons.wifi_rounded;
  if (_contains(n, ['phone', 'mobile', 'telephone', 'telecom', 'postpaid', 'prepaid', 'recharge', 'cell'])) return Icons.phone_android_rounded;
  if (_contains(n, ['utilities', 'utility', 'bills', 'bill', 'cable tv', 'dth', 'dish tv', 'tata sky'])) return Icons.receipt_long_rounded;

  // ── Health & Medical ──────────────────────────────────────────────────────
  if (_contains(n, ['medical', 'hospital', 'clinic', 'doctor', 'physician', 'consultation fee', 'opd'])) return Icons.local_hospital_rounded;
  if (_contains(n, ['medicine', 'pharmacy', 'drugs', 'prescription', 'tablets', 'syrup', 'chemist', 'apollo', 'pharmeasy'])) return Icons.medication_rounded;
  if (_contains(n, ['dental', 'dentist', 'teeth', 'braces'])) return Icons.medical_services_rounded;
  if (_contains(n, ['eye', 'optician', 'optical', 'glasses', 'spectacles', 'lenses'])) return Icons.visibility_rounded;
  if (_contains(n, ['health', 'wellness', 'checkup', 'healthcare', 'lab test', 'blood test', 'pathology', 'scan', 'mri', 'x-ray'])) return Icons.health_and_safety_rounded;
  if (_contains(n, ['gym', 'fitness', 'workout', 'sport', 'yoga', 'crossfit', 'trainer', 'swimming'])) return Icons.fitness_center_rounded;

  // ── Education & Learning ──────────────────────────────────────────────────
  if (_contains(n, ['school', 'tuition', 'college', 'university', 'education', 'course', 'training', 'coaching', 'udemy', 'coursera', 'academy', 'degree', 'exam fee'])) return Icons.school_rounded;
  if (_contains(n, ['books', 'stationery', 'supplies', 'notebook', 'pen', 'paper', 'textbook', 'library'])) return Icons.menu_book_rounded;

  // ── Entertainment & Lifestyle ─────────────────────────────────────────────
  if (_contains(n, ['movie', 'cinema', 'theatre', 'streaming', 'netflix', 'disney', 'prime video', 'hbo', 'hotstar', 'pvr', 'inox', 'ticket'])) return Icons.movie_rounded;
  if (_contains(n, ['music', 'spotify', 'concert', 'apple music', 'soundcloud', 'guitar', 'instrument'])) return Icons.music_note_rounded;
  if (_contains(n, ['game', 'gaming', 'xbox', 'playstation', 'steam', 'nintendo', 'pubg', 'esports'])) return Icons.sports_esports_rounded;
  if (_contains(n, ['hobby', 'craft', 'art', 'drawing', 'painting', 'photography', 'camera'])) return Icons.palette_rounded;
  if (_contains(n, ['entertainment', 'recreation', 'leisure', 'fun', 'amusement park', 'outing', 'party', 'club'])) return Icons.celebration_rounded;
  if (_contains(n, ['subscription', 'membership', 'annual fee', 'saas', 'software', 'app store', 'play store', 'chatgpt', 'cloud'])) return Icons.subscriptions_rounded;

  // ── Shopping & Clothing ───────────────────────────────────────────────────
  if (_contains(n, ['clothing', 'clothes', 'apparel', 'fashion', 'wear', 'shirt', 'dress', 'jeans', 't-shirt', 'jacket', 'saree', 'kurta', 'shoes', 'footwear', 'sneakers'])) return Icons.checkroom_rounded;
  if (_contains(n, ['electronics', 'gadget', 'device', 'phone purchase', 'smartphone', 'laptop', 'tablet', 'ipad', 'headphones', 'earphones', 'charger', 'tv', 'monitor'])) return Icons.devices_rounded;
  if (_contains(n, ['shopping', 'purchase', 'buy', 'online shop', 'amazon', 'flipkart', 'myntra', 'mall'])) return Icons.shopping_bag_rounded;
  if (_contains(n, ['accessories', 'jewellery', 'jewelry', 'gold', 'silver', 'diamond', 'ring', 'necklace', 'watch', 'wrist watch'])) return Icons.diamond_rounded;
  if (_contains(n, ['gift', 'presents', 'gifting', 'surprise'])) return Icons.card_giftcard_rounded;

  // ── Travel & Vacation ─────────────────────────────────────────────────────
  if (_contains(n, ['vacation', 'holiday', 'tour', 'trip', 'travel', 'sightseeing', 'getaway'])) return Icons.luggage_rounded;
  if (_contains(n, ['hotel', 'accommodation', 'lodging', 'airbnb', 'resort', 'homestay', 'hostel'])) return Icons.hotel_rounded;
  if (_contains(n, ['beach', 'sea', 'island', 'cruise', 'mountain', 'hill station', 'trek', 'camping'])) return Icons.beach_access_rounded;

  // ── Insurance & Protection ────────────────────────────────────────────────
  if (_contains(n, ['life insurance', 'term insurance', 'life plan', 'lic', 'endowment'])) return Icons.favorite_rounded;
  if (_contains(n, ['health insurance', 'medical insurance', 'mediclaim', 'star health', 'care insurance'])) return Icons.health_and_safety_rounded;
  if (_contains(n, ['vehicle insurance', 'car insurance', 'motor insurance', 'bike insurance'])) return Icons.car_crash_rounded;
  if (_contains(n, ['insurance', 'premium', 'policy', 'protect', 'coverage'])) return Icons.shield_rounded;

  // ── Savings, Goals & Investments ──────────────────────────────────────────
  if (_contains(n, ['retirement', 'pension fund', 'epf', 'provident', 'nps', 'annuity fund'])) return Icons.account_balance_rounded;
  if (_contains(n, ['children', 'child', 'kids', 'education fund', 'sukanya'])) return Icons.child_care_rounded;
  if (_contains(n, ['emergency fund', 'emergency', 'rainy day'])) return Icons.emergency_rounded;
  if (_contains(n, ['buffer', 'contingency', 'liquidity'])) return Icons.account_balance_wallet_rounded;
  if (_contains(n, ['investment', 'mutual fund', 'sip', 'stocks', 'shares', 'equity', 'demat', 'trading', 'crypto', 'bitcoin', 'index fund', 'etf', 'gold bond', 'fd', 'fixed deposit', 'rd'])) return Icons.show_chart_rounded;
  if (_contains(n, ['saving', 'savings', 'goal', 'piggy bank', 'deposit'])) return Icons.savings_rounded;

  // ── Depreciating Assets & Sinking Funds ──────────────────────────────────
  if (_contains(n, ['vehicle maintenance', 'car repair', 'bike service', 'mechanic', 'car wash', 'bike repair'])) return Icons.car_repair_rounded;
  if (_contains(n, ['computer replacement', 'laptop repair', 'phone replacement', 'screen replacement'])) return Icons.computer_rounded;
  if (_contains(n, ['appliance', 'fridge', 'refrigerator', 'washing machine', 'ac service', 'air conditioner', 'microwave'])) return Icons.kitchen_rounded;
  if (_contains(n, ['asset', 'depreciating', 'sinking fund'])) return Icons.trending_down_rounded;

  // ── Loans & Debt ──────────────────────────────────────────────────────────
  if (_contains(n, ['loan', 'emi', 'debt', 'credit card payment', 'repayment', 'home loan', 'personal loan', 'car loan', 'education loan', 'interest payment'])) return Icons.credit_score_rounded;
  if (_contains(n, ['borrow', 'lend', 'lending', 'debtor', 'creditor', 'udhar', 'loan given', 'loan taken'])) return Icons.handshake_rounded;

  // ── Charity, Social & Spiritual ───────────────────────────────────────────
  if (_contains(n, ['charity', 'donation', 'tithe', 'zakat', 'social', 'ngo', 'aid', 'temple', 'church', 'mosque', 'puja', 'worship', 'religious'])) return Icons.volunteer_activism_rounded;

  // ── Taxes & Fees ──────────────────────────────────────────────────────────
  if (_contains(n, ['tax', 'income tax', 'gst', 'vat', 'tds', 'advance tax', 'property tax', 'corporation tax'])) return Icons.receipt_rounded;
  if (_contains(n, ['fee', 'charge', 'penalty', 'fine', 'late fee', 'convenience fee'])) return Icons.price_change_rounded;
  if (_contains(n, ['bank', 'banking', 'service charge', 'atm charge', 'annual fee'])) return Icons.account_balance_rounded;

  // ── Adjustment / Unplanned ────────────────────────────────────────────────
  if (_contains(n, ['unplanned', 'unexpected', 'surprise', 'urgency'])) return Icons.warning_amber_rounded;
  if (_contains(n, ['adjustment', 'correction', 'reconcile', 'tally'])) return Icons.tune_rounded;
  if (_contains(n, ['untallied', 'uncategorized', 'unknown', 'misc', 'miscellaneous', 'other'])) return Icons.help_outline_rounded;

  return null;
}

/// Returns a color tint suitable for a category icon background based on kind.
Color categoryIconColor(String kind) {
  switch (kind.toLowerCase()) {
    case 'income':           return const Color(0xFF00A887);
    case 'incomededuction':  return const Color(0xFFEF4444);
    case 'spending':         return const Color(0xFF8B5CF6);
    case 'saving':           return const Color(0xFF10B981);
    case 'protection':       return const Color(0xFFF59E0B);
    case 'adjustment':       return const Color(0xFF3B82F6);
    default:                 return const Color(0xFF78909C);
  }
}

/// Returns a semantically relevant [IconData] for a category group (e.g. Fees, Needs, Wants, Travel).
IconData categoryGroupIcon(String groupName) {
  final match = _matchSemanticIcon(groupName);
  if (match != null) return match;

  final g = groupName.toLowerCase();
  if (g.contains('fee') || g.contains('utility') || g.contains('bill')) return Icons.receipt_long_rounded;
  if (g.contains('need') || g.contains('essential')) return Icons.shopping_basket_rounded;
  if (g.contains('want') || g.contains('lifestyle')) return Icons.star_rounded;
  if (g.contains('travel') || g.contains('commute')) return Icons.directions_car_rounded;
  if (g.contains('honorarium') || g.contains('beneficiary')) return Icons.volunteer_activism_rounded;
  if (g.contains('unplanned') || g.contains('unexpected')) return Icons.warning_amber_rounded;
  if (g.contains('insurance') || g.contains('protect')) return Icons.shield_rounded;
  if (g.contains('retire')) return Icons.elderly_rounded;
  if (g.contains('child') || g.contains('kids')) return Icons.child_care_rounded;
  if (g.contains('saving') || g.contains('goal')) return Icons.savings_rounded;
  if (g.contains('income') || g.contains('salary')) return Icons.payments_rounded;
  if (g.contains('depreciat') || g.contains('asset')) return Icons.precision_manufacturing_rounded;
  if (g.contains('event')) return Icons.event_rounded;
  if (g.contains('vacation') || g.contains('holiday')) return Icons.beach_access_rounded;
  if (g.contains('medical') || g.contains('emergency')) return Icons.medical_services_rounded;
  if (g.contains('maintenance') || g.contains('repair')) return Icons.build_rounded;
  if (g.contains('buffer') || g.contains('wallet')) return Icons.account_balance_wallet_rounded;
  if (g.contains('borrow') || g.contains('lend') || g.contains('debt')) return Icons.handshake_rounded;
  if (g.contains('misc') || g.contains('other')) return Icons.widgets_rounded;
  return Icons.grid_view_rounded;
}

/// Returns an accent color for a category group header.
Color categoryGroupColor(String groupName) {
  final g = groupName.toLowerCase();
  if (g.contains('fee') || g.contains('bill')) return const Color(0xFF0284C7); // Sky Blue
  if (g.contains('need')) return const Color(0xFF10B981); // Emerald Green
  if (g.contains('want')) return const Color(0xFFEC4899); // Pink
  if (g.contains('travel')) return const Color(0xFFF97316); // Orange
  if (g.contains('honorarium')) return const Color(0xFF8B5CF6); // Violet
  if (g.contains('unplanned')) return const Color(0xFFEF4444); // Red
  if (g.contains('insurance') || g.contains('protect')) return const Color(0xFFF59E0B); // Amber
  if (g.contains('saving') || g.contains('goal')) return const Color(0xFF059669); // Green
  if (g.contains('income')) return const Color(0xFF00A887); // Teal
  return const Color(0xFF6366F1); // Indigo
}

bool _contains(String name, List<String> keywords) {
  return keywords.any((kw) => name.contains(kw));
}

IconData _deterministicIcon(String seed, List<IconData> icons) {
  if (seed.isEmpty || icons.isEmpty) return Icons.category_rounded;
  final hash = seed.codeUnits.fold<int>(0, (prev, elem) => prev + elem);
  return icons[hash % icons.length];
}
