export interface SeedCategory {
  id: string;
  kind: string;
  groupCode?: string;
  name: string;
  needOrWant?: string;
  isDeduction: boolean;
  isSystem: boolean;
  sortOrder: number;
}

export const seedCategories: SeedCategory[] = [
  // INCOME
  { id: 'inc-01', kind: 'income', name: 'Person 1 Salary & Allowance', isDeduction: false, isSystem: false, sortOrder: 1 },
  { id: 'inc-02', kind: 'income', name: 'Person 2 Salary & Allowance', isDeduction: false, isSystem: false, sortOrder: 2 },
  { id: 'inc-03', kind: 'income', name: 'Parents Pension', isDeduction: false, isSystem: false, sortOrder: 3 },
  { id: 'inc-04', kind: 'income', name: 'Bonus', isDeduction: false, isSystem: false, sortOrder: 4 },
  { id: 'inc-05', kind: 'income', name: 'From Donors/Others', isDeduction: false, isSystem: false, sortOrder: 5 },
  { id: 'inc-06', kind: 'income', name: 'Bank Interest', isDeduction: false, isSystem: false, sortOrder: 6 },
  { id: 'inc-07', kind: 'income', name: 'Income from Insurance', isDeduction: false, isSystem: false, sortOrder: 7 },
  { id: 'inc-08', kind: 'income', name: 'Income from Investments', isDeduction: false, isSystem: false, sortOrder: 8 },
  { id: 'inc-09', kind: 'income', name: 'Rental Income', isDeduction: false, isSystem: false, sortOrder: 9 },
  { id: 'inc-10', kind: 'income', name: 'Dividend', isDeduction: false, isSystem: false, sortOrder: 10 },
  { id: 'inc-11', kind: 'income', name: 'Cashbacks', isDeduction: false, isSystem: false, sortOrder: 11 },
  { id: 'inc-12', kind: 'income', name: 'Unlisted Income/Spending(-)', isDeduction: false, isSystem: false, sortOrder: 12 },
  // Deductions
  { id: 'ded-01', kind: 'incomeDeduction', name: 'Income Tax', isDeduction: true, isSystem: false, sortOrder: 1 },
  { id: 'ded-02', kind: 'incomeDeduction', name: 'Other Deduction', isDeduction: true, isSystem: false, sortOrder: 2 },

  // ADJUSTMENTS
  { id: 'adj-01', kind: 'adjustment', name: 'Credit Card Borrow/Payment', isDeduction: false, isSystem: false, sortOrder: 1 },
  { id: 'adj-02', kind: 'adjustment', name: 'Borrow/Return(-)', isDeduction: false, isSystem: false, sortOrder: 2 },
  { id: 'adj-03', kind: 'adjustment', name: 'Temporary In/Out(-)', isDeduction: false, isSystem: false, sortOrder: 3 },
  { id: 'adj-04', kind: 'adjustment', name: 'Others(Inflow)', isDeduction: false, isSystem: false, sortOrder: 4 },
  { id: 'adj-05', kind: 'adjustment', name: 'Lending/Return(-)', isDeduction: false, isSystem: false, sortOrder: 5 },
  { id: 'adj-06', kind: 'adjustment', name: 'Others(Outflow)', isDeduction: false, isSystem: false, sortOrder: 6 },

  // SPENDING - fees
  { id: 'spd-f01', kind: 'spending', groupCode: 'fees', name: 'Electricity Bill 1', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 1 },
  { id: 'spd-f02', kind: 'spending', groupCode: 'fees', name: 'Electricity Bill 2', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 2 },
  { id: 'spd-f03', kind: 'spending', groupCode: 'fees', name: 'Telephone/Internet', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 3 },
  { id: 'spd-f04', kind: 'spending', groupCode: 'fees', name: 'Apartment Maintenance', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 4 },
  { id: 'spd-f05', kind: 'spending', groupCode: 'fees', name: 'DTH/OTT Subscriptions', needOrWant: 'want', isDeduction: false, isSystem: false, sortOrder: 5 },
  { id: 'spd-f06', kind: 'spending', groupCode: 'fees', name: 'Schooling/Education Fees', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 6 },
  { id: 'spd-f07', kind: 'spending', groupCode: 'fees', name: 'LPG/Cooking Gas', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 7 },
  { id: 'spd-f08', kind: 'spending', groupCode: 'fees', name: 'Credit Card Annual Fees', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 8 },
  { id: 'spd-f09', kind: 'spending', groupCode: 'fees', name: 'Property Tax', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 9 },
  { id: 'spd-f10', kind: 'spending', groupCode: 'fees', name: 'Water/Sewage Bill', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 10 },
  { id: 'spd-f11', kind: 'spending', groupCode: 'fees', name: 'Other Utility', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 11 },

  // SPENDING - needs
  { id: 'spd-n01', kind: 'spending', groupCode: 'needs', name: 'Temple/Pooja/Religious', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 1 },
  { id: 'spd-n02', kind: 'spending', groupCode: 'needs', name: 'Vegetables & Fruits', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 2 },
  { id: 'spd-n03', kind: 'spending', groupCode: 'needs', name: 'Meat & Fish', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 3 },
  { id: 'spd-n04', kind: 'spending', groupCode: 'needs', name: 'Milk & Dairy', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 4 },
  { id: 'spd-n05', kind: 'spending', groupCode: 'needs', name: 'Grocery - Edible', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 5 },
  { id: 'spd-n06', kind: 'spending', groupCode: 'needs', name: 'Grocery - Non Edible', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 6 },
  { id: 'spd-n07', kind: 'spending', groupCode: 'needs', name: 'Medical/Pharmacy', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 7 },
  { id: 'spd-n08', kind: 'spending', groupCode: 'needs', name: 'Cooking Oil', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 8 },
  { id: 'spd-n09', kind: 'spending', groupCode: 'needs', name: 'Domestic Help', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 9 },
  { id: 'spd-n10', kind: 'spending', groupCode: 'needs', name: 'Baby/Child Needs', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 10 },
  { id: 'spd-n11', kind: 'spending', groupCode: 'needs', name: 'Personal Care', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 11 },
  { id: 'spd-n12', kind: 'spending', groupCode: 'needs', name: 'Clothing - Basic', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 12 },
  { id: 'spd-n13', kind: 'spending', groupCode: 'needs', name: 'Other Needs', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 13 },

  // SPENDING - wants
  { id: 'spd-w01', kind: 'spending', groupCode: 'wants', name: 'Charity/Donations', needOrWant: 'want', isDeduction: false, isSystem: false, sortOrder: 1 },
  { id: 'spd-w02', kind: 'spending', groupCode: 'wants', name: 'Hotel/Restaurant Food', needOrWant: 'want', isDeduction: false, isSystem: false, sortOrder: 2 },
  { id: 'spd-w03', kind: 'spending', groupCode: 'wants', name: 'Outing/Entertainment', needOrWant: 'want', isDeduction: false, isSystem: false, sortOrder: 3 },
  { id: 'spd-w04', kind: 'spending', groupCode: 'wants', name: 'Snacks/Beverages', needOrWant: 'want', isDeduction: false, isSystem: false, sortOrder: 4 },
  { id: 'spd-w05', kind: 'spending', groupCode: 'wants', name: 'Fitness/Sports', needOrWant: 'want', isDeduction: false, isSystem: false, sortOrder: 5 },
  { id: 'spd-w06', kind: 'spending', groupCode: 'wants', name: 'Toys/Games', needOrWant: 'want', isDeduction: false, isSystem: false, sortOrder: 6 },
  { id: 'spd-w07', kind: 'spending', groupCode: 'wants', name: 'Books/Courses', needOrWant: 'want', isDeduction: false, isSystem: false, sortOrder: 7 },
  { id: 'spd-w08', kind: 'spending', groupCode: 'wants', name: 'Salon/Beauty', needOrWant: 'want', isDeduction: false, isSystem: false, sortOrder: 8 },
  { id: 'spd-w09', kind: 'spending', groupCode: 'wants', name: 'Streaming/Apps', needOrWant: 'want', isDeduction: false, isSystem: false, sortOrder: 9 },
  { id: 'spd-w10', kind: 'spending', groupCode: 'wants', name: 'Party/Celebrations', needOrWant: 'want', isDeduction: false, isSystem: false, sortOrder: 10 },
  { id: 'spd-w11', kind: 'spending', groupCode: 'wants', name: 'Other Wants', needOrWant: 'want', isDeduction: false, isSystem: false, sortOrder: 11 },

  // SPENDING - travel
  { id: 'spd-t01', kind: 'spending', groupCode: 'travel', name: 'Outstation - Fare', needOrWant: 'want', isDeduction: false, isSystem: false, sortOrder: 1 },
  { id: 'spd-t02', kind: 'spending', groupCode: 'travel', name: 'Outstation - Food', needOrWant: 'want', isDeduction: false, isSystem: false, sortOrder: 2 },
  { id: 'spd-t03', kind: 'spending', groupCode: 'travel', name: 'Outstation - Fuel', needOrWant: 'want', isDeduction: false, isSystem: false, sortOrder: 3 },
  { id: 'spd-t04', kind: 'spending', groupCode: 'travel', name: 'Local Travel/Auto/Cab', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 4 },
  { id: 'spd-t05', kind: 'spending', groupCode: 'travel', name: 'Petrol/Fuel', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 5 },
  { id: 'spd-t06', kind: 'spending', groupCode: 'travel', name: 'Vehicle Maintenance', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 6 },
  { id: 'spd-t07', kind: 'spending', groupCode: 'travel', name: 'Road Tolls/Parking', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 7 },
  { id: 'spd-t08', kind: 'spending', groupCode: 'travel', name: 'Train/Bus Pass', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 8 },
  { id: 'spd-t09', kind: 'spending', groupCode: 'travel', name: 'Other Travel', needOrWant: 'want', isDeduction: false, isSystem: false, sortOrder: 9 },

  // SPENDING - honorarium
  { id: 'spd-h01', kind: 'spending', groupCode: 'honorarium', name: 'Beneficiary 1', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 1 },
  { id: 'spd-h02', kind: 'spending', groupCode: 'honorarium', name: 'Beneficiary 2', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 2 },
  { id: 'spd-h03', kind: 'spending', groupCode: 'honorarium', name: 'Beneficiary 3', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 3 },
  { id: 'spd-h04', kind: 'spending', groupCode: 'honorarium', name: 'Beneficiary 4', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 4 },

  // SPENDING - unplanned
  { id: 'spd-u01', kind: 'spending', groupCode: 'unplanned', name: 'Unplanned Exp 1', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 1 },
  { id: 'spd-u02', kind: 'spending', groupCode: 'unplanned', name: 'Unplanned Exp 2', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 2 },
  { id: 'spd-u03', kind: 'spending', groupCode: 'unplanned', name: 'Unplanned Exp 3', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 3 },
  { id: 'spd-u04', kind: 'spending', groupCode: 'unplanned', name: 'Unplanned Exp 4', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 4 },
  { id: 'spd-u05', kind: 'spending', groupCode: 'unplanned', name: 'Unplanned Exp 5', needOrWant: 'need', isDeduction: false, isSystem: false, sortOrder: 5 },
  { id: 'spd-u06', kind: 'spending', groupCode: 'unplanned', name: 'Untallied Amount', isDeduction: false, isSystem: true, sortOrder: 6 },

  // SPENDING - purchase_misc
  { id: 'spd-m01', kind: 'spending', groupCode: 'purchase_misc', name: 'Gadgets/Electronics', needOrWant: 'want', isDeduction: false, isSystem: false, sortOrder: 1 },
  { id: 'spd-m02', kind: 'spending', groupCode: 'purchase_misc', name: 'Dress/Clothing', needOrWant: 'want', isDeduction: false, isSystem: false, sortOrder: 2 },
  { id: 'spd-m03', kind: 'spending', groupCode: 'purchase_misc', name: 'Gifts', needOrWant: 'want', isDeduction: false, isSystem: false, sortOrder: 3 },
  { id: 'spd-m04', kind: 'spending', groupCode: 'purchase_misc', name: 'Gold/Jewellery', needOrWant: 'want', isDeduction: false, isSystem: false, sortOrder: 4 },
  { id: 'spd-m05', kind: 'spending', groupCode: 'purchase_misc', name: 'Festivals/Occasions', needOrWant: 'want', isDeduction: false, isSystem: false, sortOrder: 5 },
  { id: 'spd-m06', kind: 'spending', groupCode: 'purchase_misc', name: 'Home Furnishings', needOrWant: 'want', isDeduction: false, isSystem: false, sortOrder: 6 },
  { id: 'spd-m07', kind: 'spending', groupCode: 'purchase_misc', name: 'Appliances', needOrWant: 'want', isDeduction: false, isSystem: false, sortOrder: 7 },
  { id: 'spd-m08', kind: 'spending', groupCode: 'purchase_misc', name: 'Other Purchases', needOrWant: 'want', isDeduction: false, isSystem: false, sortOrder: 8 },

  // PROTECTION
  { id: 'pro-i01', kind: 'protection', groupCode: 'insurance', name: 'To MF for Insurance', isDeduction: false, isSystem: false, sortOrder: 1 },
  { id: 'pro-i02', kind: 'protection', groupCode: 'insurance', name: 'Spending for Insurance', isDeduction: false, isSystem: false, sortOrder: 2 },
  { id: 'pro-d01', kind: 'protection', groupCode: 'depreciating_assets', name: 'To MF for Depreciating Assets', isDeduction: false, isSystem: false, sortOrder: 1 },
  { id: 'pro-d02', kind: 'protection', groupCode: 'depreciating_assets', name: 'Spending for Depreciating Assets', isDeduction: false, isSystem: false, sortOrder: 2 },
  { id: 'pro-g01', kind: 'protection', groupCode: 'good_bad_events', name: 'To MF for Good/Bad Events', isDeduction: false, isSystem: false, sortOrder: 1 },
  { id: 'pro-g02', kind: 'protection', groupCode: 'good_bad_events', name: 'Spending for Good/Bad Events', isDeduction: false, isSystem: false, sortOrder: 2 },
  { id: 'pro-v01', kind: 'protection', groupCode: 'vacation', name: 'To MF for Vacation', isDeduction: false, isSystem: false, sortOrder: 1 },
  { id: 'pro-v02', kind: 'protection', groupCode: 'vacation', name: 'Spending for Vacation', isDeduction: false, isSystem: false, sortOrder: 2 },
  { id: 'pro-m01', kind: 'protection', groupCode: 'medical_emergency', name: 'To MF for Medical Emergency', isDeduction: false, isSystem: false, sortOrder: 1 },
  { id: 'pro-m02', kind: 'protection', groupCode: 'medical_emergency', name: 'Spending for Medical Emergency', isDeduction: false, isSystem: false, sortOrder: 2 },
  { id: 'pro-p01', kind: 'protection', groupCode: 'property_maintenance', name: 'To MF for Property Maintenance', isDeduction: false, isSystem: false, sortOrder: 1 },
  { id: 'pro-p02', kind: 'protection', groupCode: 'property_maintenance', name: 'Spending for Property Maintenance', isDeduction: false, isSystem: false, sortOrder: 2 },
  { id: 'pro-o01', kind: 'protection', groupCode: 'others_emergency', name: 'To MF for Others Emergency', isDeduction: false, isSystem: false, sortOrder: 1 },
  { id: 'pro-o02', kind: 'protection', groupCode: 'others_emergency', name: 'Spending for Others Emergency', isDeduction: false, isSystem: false, sortOrder: 2 },
  { id: 'pro-b01', kind: 'protection', groupCode: 'buffer', name: 'To MF for Buffer', isDeduction: false, isSystem: false, sortOrder: 1 },
  { id: 'pro-b02', kind: 'protection', groupCode: 'buffer', name: 'Spending from Buffer', isDeduction: false, isSystem: false, sortOrder: 2 },

  // SAVING
  { id: 'sav-r01', kind: 'saving', groupCode: 'retirement', name: 'EPF/PPF Contribution', isDeduction: false, isSystem: false, sortOrder: 1 },
  { id: 'sav-r02', kind: 'saving', groupCode: 'retirement', name: 'NPS Contribution', isDeduction: false, isSystem: false, sortOrder: 2 },
  { id: 'sav-r03', kind: 'saving', groupCode: 'retirement', name: 'Retirement MF SIP', isDeduction: false, isSystem: false, sortOrder: 3 },
  { id: 'sav-r04', kind: 'saving', groupCode: 'retirement', name: 'Other Retirement', isDeduction: false, isSystem: false, sortOrder: 4 },
  { id: 'sav-c01', kind: 'saving', groupCode: 'children', name: 'Child 1 Higher Education', isDeduction: false, isSystem: false, sortOrder: 1 },
  { id: 'sav-c02', kind: 'saving', groupCode: 'children', name: 'Child 2 Higher Education', isDeduction: false, isSystem: false, sortOrder: 2 },
  { id: 'sav-c03', kind: 'saving', groupCode: 'children', name: 'Child 1 Marriage', isDeduction: false, isSystem: false, sortOrder: 3 },
  { id: 'sav-c04', kind: 'saving', groupCode: 'children', name: 'Child 2 Marriage', isDeduction: false, isSystem: false, sortOrder: 4 },
  { id: 'sav-c05', kind: 'saving', groupCode: 'children', name: 'Gold/Jewellery for Children', isDeduction: false, isSystem: false, sortOrder: 5 },
  { id: 'sav-g01', kind: 'saving', groupCode: 'other_goals', name: 'Car Fund', isDeduction: false, isSystem: false, sortOrder: 1 },
  { id: 'sav-g02', kind: 'saving', groupCode: 'other_goals', name: 'Dream Home Fund', isDeduction: false, isSystem: false, sortOrder: 2 },
  { id: 'sav-g03', kind: 'saving', groupCode: 'other_goals', name: 'Other Investment 1', isDeduction: false, isSystem: false, sortOrder: 3 },
  { id: 'sav-g04', kind: 'saving', groupCode: 'other_goals', name: 'Other Investment 2', isDeduction: false, isSystem: false, sortOrder: 4 },
  { id: 'sav-g05', kind: 'saving', groupCode: 'other_goals', name: 'Other Investment 3', isDeduction: false, isSystem: false, sortOrder: 5 },
];
