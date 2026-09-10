import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/category_icons.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/month.dart';
import '../../../data/local/database.dart';
import '../../../domain/entities/entry.dart';
import '../../../domain/usecases/add_entry.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../providers/transactions_providers.dart';

/// S5/S6 — Add / Edit Expense, Income, Adjustment (doc 09 S5, S6).
/// Hot path: Amount keypad hero → CategoryPicker → DatePicker → Note → Save.
/// Optimistic insert → queued sync. Target: <5 seconds total flow (doc 02 WF-1).
class AddEntryScreen extends ConsumerStatefulWidget {
  final String? entryId; // null = new entry
  final String? initialKind;

  const AddEntryScreen({super.key, this.entryId, this.initialKind});

  @override
  ConsumerState<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends ConsumerState<AddEntryScreen> {
  String _amountStr = '';
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  DateTime _entryDate = DateTime.now();
  final _noteCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _amountFocusNode = FocusNode();
  EntryKind _kind = EntryKind.spending;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialKind != null) {
      _kind = _kindFromString(widget.initialKind!);
    }
    if (widget.entryId != null) {
      Future.microtask(() => _loadExistingEntry());
    } else {
      Future.microtask(() => _autoPreselectCategory());
      // Auto-open keyboard on new entry so user can type immediately
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _amountFocusNode.requestFocus();
      });
    }
    // Keep _amountStr and _amountCtrl in sync when keyboard is dismissed
    _amountFocusNode.addListener(() {
      if (!_amountFocusNode.hasFocus) {
        final text = _amountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
        if (text != _amountStr) {
          setState(() => _amountStr = text);
        }
      }
    });
  }

  Future<void> _autoPreselectCategory() async {
    try {
      final categories = await ref.read(activeCategoriesProvider(_kind).future);
      if (categories.isNotEmpty && mounted && _selectedCategoryId == null) {
        setState(() {
          _selectedCategoryId = categories.first.id;
          _selectedCategoryName = categories.first.name;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadExistingEntry() async {
    final db = ref.read(appDatabaseProvider);
    final entry = await db.entryDao.getById(widget.entryId!);
    if (entry != null && mounted) {
      final category = await (db.select(db.categoriesTable)..where((c) => c.id.equals(entry.categoryId))).getSingleOrNull();
      final amountStr = (entry.amountPaise / 100.0).toStringAsFixed(0);
      setState(() {
        _amountStr = amountStr;
        _amountCtrl.text = amountStr;
        _selectedCategoryId = entry.categoryId;
        _selectedCategoryName = category?.name ?? entry.categoryId;
        _entryDate = entry.entryDate;
        _noteCtrl.text = entry.note ?? '';
        _kind = _kindFromString(entry.kind);
      });
    }
  }

  EntryKind _kindFromString(String s) {
    return switch (s) {
      'income' => EntryKind.income,
      'incomeDeduction' => EntryKind.incomeDeduction,
      'adjustment' => EntryKind.adjustment,
      'protection' => EntryKind.protection,
      'saving' => EntryKind.saving,
      _ => EntryKind.spending,
    };
  }

  String get _kindLabel => switch (_kind) {
        EntryKind.income || EntryKind.incomeDeduction => 'Income',
        EntryKind.spending => 'Expense',
        EntryKind.adjustment => 'Adjustment',
        EntryKind.protection => 'Protection',
        EntryKind.saving => 'Saving',
      };
  
  Money? get _parsedAmount {
    if (_amountStr.isEmpty) return null;
    try {
      return Money.fromRupees(double.parse(_amountStr));
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    if (_parsedAmount == null || _parsedAmount!.isZero) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter an amount greater than zero.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a category.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final draft = EntryDraft(
      categoryId: _selectedCategoryId!,
      kind: _kind,
      entryDate: _entryDate,
      amount: _parsedAmount!,
      note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
    );

    final bool success;
    if (widget.entryId != null) {
      success = await ref
          .read(addEntryControllerProvider.notifier)
          .updateEntry(widget.entryId!, draft);
    } else {
      success = await ref
          .read(addEntryControllerProvider.notifier)
          .addEntry(draft);
    }

    if (mounted) {
      setState(() => _saving = false);
      if (success) {
        ref.read(selectedMonthProvider.notifier).select(YearMonth.fromDate(_entryDate));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_kindLabel saved!'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        context.pop();
      } else {
        final err = ref.read(addEntryControllerProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err?.toString() ?? 'Failed to save entry'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _amountCtrl.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entryId != null ? 'Edit $_kindLabel' : 'Add $_kindLabel'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Save',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: cs.primary,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Kind switcher / Context Banner ─────────────────────────────
            if (widget.initialKind != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_rounded, size: 18, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Category Context: $_kindLabel',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (_selectedCategoryName != null)
                      Chip(
                        label: Text(
                          _selectedCategoryName!,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<EntryKind>(
                    style: ButtonStyle(
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    segments: const [
                      ButtonSegment(value: EntryKind.spending, label: Text('Expense')),
                      ButtonSegment(value: EntryKind.income, label: Text('Income')),
                      ButtonSegment(value: EntryKind.protection, label: Text('Protection')),
                      ButtonSegment(value: EntryKind.saving, label: Text('Saving')),
                      ButtonSegment(value: EntryKind.adjustment, label: Text('Adjust')),
                    ],
                    selected: {_kind},
                    onSelectionChanged: (s) => setState(() {
                      _kind = s.first;
                      _selectedCategoryId = null;
                      _selectedCategoryName = null;
                      _autoPreselectCategory();
                    }),
                  ),
                ),
              ),

            // ─── Amount field (phone keyboard) ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '₹',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      focusNode: _amountFocusNode,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: _amountStr.isEmpty
                            ? cs.onSurfaceVariant.withValues(alpha: 0.4)
                            : cs.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 38,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w800,
                          fontSize: 38,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: cs.primary, width: 2),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (v) {
                        final filtered = v.replaceAll(RegExp(r'[^0-9.]'), '');
                        if (filtered != v) {
                          _amountCtrl.text = filtered;
                          _amountCtrl.selection = TextSelection.collapsed(
                            offset: filtered.length,
                          );
                        }
                        setState(() => _amountStr = filtered);
                      },
                      onTap: () {
                        _amountCtrl.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: _amountCtrl.text.length,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ─── Category picker ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: PressableScale(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _showCategoryPicker(context),
                child: OutlinedButton.icon(
                  onPressed: () => _showCategoryPicker(context),
                  icon: Icon(Icons.category_outlined, color: cs.primary),
                  label: Text(
                    _selectedCategoryName ?? 'Select Category *',
                    style: TextStyle(
                      color: _selectedCategoryName != null ? cs.onSurface : cs.onSurfaceVariant,
                      fontWeight: _selectedCategoryName != null ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    alignment: Alignment.centerLeft,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ─── Date picker ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: PressableScale(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _pickDate(context),
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(context),
                  icon: Icon(Icons.calendar_today_outlined, color: cs.primary),
                  label: Text(
                    _formatDate(_entryDate),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    alignment: Alignment.centerLeft,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ─── Note ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _noteCtrl,
                decoration: InputDecoration(
                  hintText: 'Add Note (optional)',
                  prefixIcon: Icon(Icons.notes_outlined, color: cs.onSurfaceVariant),
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final today = DateTime.now();
    if (d.year == today.year && d.month == today.month && d.day == today.day) {
      return 'Today';
    }
    return '${d.day}/${d.month}/${d.year}';
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _entryDate = picked);
  }

  void _showCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => _CategoryPickerSheet(
          kind: _kind,
          onSelected: (id, name, catKind) {
            final parsedKind = EntryKind.values.firstWhere(
              (k) => k.name == catKind,
              orElse: () => _kind,
            );
            setState(() {
              _selectedCategoryId = id;
              _selectedCategoryName = name;
              _kind = parsedKind;
            });
            Navigator.pop(context);
          },
          scrollController: scrollCtrl,
        ),
      ),
    );
  }
}

// ─── Category Picker Sheet ────────────────────────────────────────────────────

class _CategoryPickerSheet extends ConsumerStatefulWidget {
  final EntryKind kind;
  final void Function(String id, String name, String kind) onSelected;
  final ScrollController scrollController;

  const _CategoryPickerSheet({
    required this.kind,
    required this.onSelected,
    required this.scrollController,
  });

  @override
  ConsumerState<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends ConsumerState<_CategoryPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(activeCategoriesProvider(widget.kind));
    final cs = Theme.of(context).colorScheme;

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading categories: $err')),
      data: (categories) {
        final uniqueMap = <String, CategoriesTableData>{};
        for (final c in categories) {
           uniqueMap['${c.groupCode}_${c.name.toLowerCase()}'] = c;
        }
        final uniqueCategories = uniqueMap.values.toList();

        final filtered = uniqueCategories.where((c) {
          if (_query.isEmpty) return true;
          return c.name.toLowerCase().contains(_query.toLowerCase());
        }).toList();

        return Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search categories...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: widget.scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final cat = filtered[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: PressableScale(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => widget.onSelected(cat.id, cat.name, cat.kind),
                      child: ListTile(
                        title: Text(
                          cat.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: cat.groupCode != null
                            ? Text(cat.groupCode!, style: TextStyle(color: cs.onSurfaceVariant))
                            : null,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: categoryIconColor(cat.kind).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            categoryIcon(cat.name, cat.kind, cat.groupCode),
                            color: categoryIconColor(cat.kind),
                            size: 20,
                          ),
                        ),
                        onTap: () => widget.onSelected(cat.id, cat.name, cat.kind),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
