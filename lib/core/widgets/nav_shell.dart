import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/pressable_scale.dart';

/// Bottom navigation shell wrapping all main screens (doc 09).
/// Tab order: Dashboard · Transactions · Budget · Reports · More
/// Includes animated page transitions between tabs and Toshl-inspired tactile action sheet.
class NavShell extends StatelessWidget {
  final Widget child;

  const NavShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(label: 'Dashboard', icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded, path: '/dashboard'),
    _TabItem(label: 'Transactions', icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, path: '/transactions'),
    _TabItem(label: 'Budget', icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, path: '/budget'),
    _TabItem(label: 'Reports', icon: Icons.pie_chart_outline_rounded, activeIcon: Icons.pie_chart_rounded, path: '/reports'),
    _TabItem(label: 'More', icon: Icons.more_horiz_outlined, activeIcon: Icons.more_horiz_rounded, path: '/more'),
  ];

  int _indexForLocation(String location) {
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return -1; // Not a main tab route — no FAB
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _indexForLocation(location);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: child,
      floatingActionButton: selectedIndex == 0 ? _GlobalFab() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).navigationBarTheme.backgroundColor,
          border: Border(
            top: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex.clamp(0, _tabs.length - 1),
          onDestinationSelected: (i) => context.go(_tabs[i].path),
          indicatorColor: const Color(0xFFE0F2F1),
          destinations: _tabs
              .map(
                (t) => NavigationDestination(
                  icon: Icon(t.icon, color: const Color(0xFF78909C)),
                  selectedIcon: Icon(t.activeIcon, color: const Color(0xFF00897B)),
                  label: t.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

/// Global FAB → sheet: Expense / Income / Fund / Goal / Card txn (doc 08 §5).
class _GlobalFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PressableScale(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _showAddSheet(context),
      child: FloatingActionButton(
        heroTag: 'global-fab',
        onPressed: null, // Gesture handled by PressableScale
        tooltip: 'Add',
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _AddSheet(),
    );
  }
}

class _AddSheet extends StatelessWidget {
  const _AddSheet();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final items = [
      _SheetItem('Expense', Icons.shopping_cart_outlined, cs.errorContainer, cs.onErrorContainer, () {
        Navigator.pop(context);
        context.push('/transactions/add?kind=spending');
      }),
      _SheetItem('Income', Icons.trending_up_rounded, cs.primaryContainer, cs.onPrimaryContainer, () {
        Navigator.pop(context);
        context.push('/transactions/add?kind=income');
      }),
      _SheetItem('Protection', Icons.shield_outlined, cs.secondaryContainer, cs.onSecondaryContainer, () {
        Navigator.pop(context);
        context.push('/transactions/add?kind=protection');
      }),
      _SheetItem('Savings', Icons.savings_outlined, cs.surfaceContainerHigh, cs.onSurfaceVariant, () {
        Navigator.pop(context);
        context.push('/transactions/add?kind=saving');
      }),
      _SheetItem('Adjustment', Icons.swap_horiz_rounded, cs.tertiaryContainer, cs.onTertiaryContainer, () {
        Navigator.pop(context);
        context.push('/transactions/add?kind=adjustment');
      }),
      _SheetItem('Card Transaction', Icons.credit_card_rounded, cs.surfaceContainerHigh, cs.onSurfaceVariant, () {
        Navigator.pop(context);
        context.go('/more/cards');
      }),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.add_circle_outline_rounded, color: cs.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Create Entry',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: items
                  .map(
                    (item) => _SheetButton(
                      label: item.label,
                      icon: item.icon,
                      bg: item.bgColor,
                      fg: item.fgColor,
                      onTap: item.onTap,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetItem {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color fgColor;
  final VoidCallback onTap;

  const _SheetItem(this.label, this.icon, this.bgColor, this.fgColor, this.onTap);
}

class _SheetButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const _SheetButton({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;
  const _TabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.path,
  });
}
