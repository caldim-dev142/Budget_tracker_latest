import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Filter state for the Reports module.
///
/// Preserves user selections across navigation within the Reports screens.
class ReportFilterState {
  /// Number of months to display in trend/historical analyses (3, 6, 8, 12).
  final int timeHorizonMonths;

  /// Kind filter: 'all', 'spending', 'saving', 'protection'.
  final String kindFilter;

  /// Classification filter: 'all', 'need', 'want'.
  final String needOrWantFilter;

  /// Specific category filter: null = all categories, or categoryId.
  final String? categoryIdFilter;

  const ReportFilterState({
    this.timeHorizonMonths = 8,
    this.kindFilter = 'all',
    this.needOrWantFilter = 'all',
    this.categoryIdFilter,
  });

  bool get isFiltered =>
      timeHorizonMonths != 8 ||
      kindFilter != 'all' ||
      needOrWantFilter != 'all' ||
      categoryIdFilter != null;

  ReportFilterState copyWith({
    int? timeHorizonMonths,
    String? kindFilter,
    String? needOrWantFilter,
    String? Function()? categoryIdFilter,
  }) {
    return ReportFilterState(
      timeHorizonMonths: timeHorizonMonths ?? this.timeHorizonMonths,
      kindFilter: kindFilter ?? this.kindFilter,
      needOrWantFilter: needOrWantFilter ?? this.needOrWantFilter,
      categoryIdFilter: categoryIdFilter != null
          ? categoryIdFilter()
          : this.categoryIdFilter,
    );
  }
}

class ReportFilterNotifier extends StateNotifier<ReportFilterState> {
  ReportFilterNotifier() : super(const ReportFilterState());

  void setTimeHorizon(int months) {
    state = state.copyWith(timeHorizonMonths: months);
  }

  void setKind(String kind) {
    state = state.copyWith(kindFilter: kind);
  }

  void setNeedOrWant(String needOrWant) {
    state = state.copyWith(needOrWantFilter: needOrWant);
  }

  void setCategory(String? categoryId) {
    state = state.copyWith(categoryIdFilter: () => categoryId);
  }

  void applyFilters({
    required int timeHorizonMonths,
    required String kindFilter,
    required String needOrWantFilter,
    required String? categoryIdFilter,
  }) {
    state = ReportFilterState(
      timeHorizonMonths: timeHorizonMonths,
      kindFilter: kindFilter,
      needOrWantFilter: needOrWantFilter,
      categoryIdFilter: categoryIdFilter,
    );
  }

  void reset() {
    state = const ReportFilterState();
  }
}

/// Global provider for ReportFilterState so selections remain intact while
/// navigating between reports.
final reportFilterProvider =
    StateNotifierProvider<ReportFilterNotifier, ReportFilterState>((ref) {
  return ReportFilterNotifier();
});
