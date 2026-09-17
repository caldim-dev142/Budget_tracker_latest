import 'package:flutter_test/flutter_test.dart';
import 'package:budget_tracker/features/reports/providers/report_filters_provider.dart';

void main() {
  group('ReportFilterNotifier Tests', () {
    test('Default state has 8 months horizon and all filters as all/null', () {
      final notifier = ReportFilterNotifier();
      final state = notifier.state;

      expect(state.timeHorizonMonths, 8);
      expect(state.kindFilter, 'all');
      expect(state.needOrWantFilter, 'all');
      expect(state.categoryIdFilter, isNull);
      expect(state.isFiltered, isFalse);
    });

    test('Updating time horizon sets isFiltered to true if not 8', () {
      final notifier = ReportFilterNotifier();
      notifier.setTimeHorizon(3);
      expect(notifier.state.timeHorizonMonths, 3);
      expect(notifier.state.isFiltered, isTrue);

      notifier.setTimeHorizon(8);
      expect(notifier.state.isFiltered, isFalse);
    });

    test('Updating kindFilter filters correctly', () {
      final notifier = ReportFilterNotifier();
      notifier.setKind('spending');
      expect(notifier.state.kindFilter, 'spending');
      expect(notifier.state.isFiltered, isTrue);

      notifier.setKind('all');
      expect(notifier.state.isFiltered, isFalse);
    });

    test('Updating needOrWantFilter filters correctly', () {
      final notifier = ReportFilterNotifier();
      notifier.setNeedOrWant('need');
      expect(notifier.state.needOrWantFilter, 'need');
      expect(notifier.state.isFiltered, isTrue);
    });

    test('Updating categoryIdFilter filters correctly', () {
      final notifier = ReportFilterNotifier();
      notifier.setCategory('cat-groceries');
      expect(notifier.state.categoryIdFilter, 'cat-groceries');
      expect(notifier.state.isFiltered, isTrue);
    });

    test('applyFilters sets all filter values atomically', () {
      final notifier = ReportFilterNotifier();
      notifier.applyFilters(
        timeHorizonMonths: 12,
        kindFilter: 'saving',
        needOrWantFilter: 'want',
        categoryIdFilter: 'cat-vacation',
      );

      final state = notifier.state;
      expect(state.timeHorizonMonths, 12);
      expect(state.kindFilter, 'saving');
      expect(state.needOrWantFilter, 'want');
      expect(state.categoryIdFilter, 'cat-vacation');
      expect(state.isFiltered, isTrue);
    });

    test('reset clears all filters back to defaults', () {
      final notifier = ReportFilterNotifier();
      notifier.applyFilters(
        timeHorizonMonths: 6,
        kindFilter: 'spending',
        needOrWantFilter: 'need',
        categoryIdFilter: 'cat-rent',
      );
      expect(notifier.state.isFiltered, isTrue);

      notifier.reset();
      expect(notifier.state.timeHorizonMonths, 8);
      expect(notifier.state.kindFilter, 'all');
      expect(notifier.state.needOrWantFilter, 'all');
      expect(notifier.state.categoryIdFilter, isNull);
      expect(notifier.state.isFiltered, isFalse);
    });
  });
}
