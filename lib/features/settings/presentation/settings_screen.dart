import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' hide Column;

import '../../../core/utils/csv_exporter/csv_exporter.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../providers/settings_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../data/local/database.dart';
import '../../../core/services/sync_service.dart';

final biometricLockProvider = StateProvider<bool>((ref) => false);
final householdNameProvider = StateProvider<String>((ref) => 'Smith Family');

/// S18 — Settings / Profile / Household (doc 09 S18).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authStateNotifierProvider).valueOrNull;
    final biometricLock = ref.watch(biometricLockProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Profile card
          if (authState != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: cs.primaryContainer,
                      child: Text(
                        (authState.displayName ?? 'U').substring(0, 1).toUpperCase(),
                        style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authState.displayName ?? 'User',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            authState.email ?? '',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                          ),
                          if (authState.authProvider == 'google') ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4285F4).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF4285F4).withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: const [
                                      Text('G ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF4285F4))),
                                      Text(
                                        'Google Authenticated',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF4285F4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),

          // Appearance
          const _SectionHeader('Appearance'),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Theme',
            subtitle: _themeModeLabel(themeMode),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showThemePicker(context, ref, themeMode),
          ),

          // Household
          const SizedBox(height: 12),
          const _SectionHeader('Household'),
          _SettingsTile(
            icon: Icons.home_outlined,
            title: 'Manage Household',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showHouseholdDialog(context, ref),
          ),
          const SizedBox(height: 6),
          _SettingsTile(
            icon: Icons.people_outlined,
            title: 'Members',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              if (authState != null) {
                _showMembersDialog(context, ref, authState);
              }
            },
          ),

          // Categories
          const SizedBox(height: 12),
          const _SectionHeader('Categories'),
          _SettingsTile(
            icon: Icons.category_outlined,
            title: 'Manage Categories',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showCategoriesDialog(context, ref),
          ),

          // Data
          const SizedBox(height: 12),
          const _SectionHeader('Data'),
          _SettingsTile(
            icon: Icons.download_outlined,
            title: 'Export as CSV',
            onTap: () => _exportToCsv(context, ref),
          ),
          const SizedBox(height: 6),
          _SettingsTile(
            icon: Icons.sync_outlined,
            title: 'Force Sync',
            onTap: () => _forceSync(context, ref),
          ),

          // Server Connection
          const SizedBox(height: 12),
          const _SectionHeader('Server Connection'),
          _SettingsTile(
            icon: Icons.cloud_queue_outlined,
            title: 'Backend Server URL',
            subtitle: ref.watch(serverUrlProvider),
            trailing: const Icon(Icons.edit_outlined, size: 18),
            onTap: () => _showServerUrlDialog(context, ref),
          ),

          // Security
          const SizedBox(height: 12),
          const _SectionHeader('Security'),
          Card(
            child: ListTile(
              leading: Icon(Icons.fingerprint_rounded, color: cs.primary),
              title: const Text('Biometric Lock', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: Switch(
                value: biometricLock,
                onChanged: (v) {
                  ref.read(biometricLockProvider.notifier).state = v;
                },
              ),
            ),
          ),

          // Sign out
          const SizedBox(height: 16),
          Card(
            color: cs.errorContainer.withValues(alpha: 0.2),
            child: PressableScale(
              borderRadius: BorderRadius.circular(18),
              onTap: () async {
                await ref.read(authStateNotifierProvider.notifier).logout();
                if (context.mounted) context.go('/auth/login');
              },
              child: ListTile(
                leading: Icon(Icons.logout_rounded, color: cs.error),
                title: Text(
                  'Sign Out',
                  style: TextStyle(color: cs.error, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showHouseholdDialog(BuildContext context, WidgetRef ref) {
    final currentName = ref.read(householdNameProvider);
    final ctrl = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Manage Household'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Household ID: demo-household', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Household Name',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(householdNameProvider.notifier).state = ctrl.text.trim();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showMembersDialog(BuildContext context, WidgetRef ref, AuthState authState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Household Members'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
              title: Text(authState.displayName ?? 'User'),
              subtitle: Text('${authState.email ?? ""} (Owner)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCategoriesDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final db = ref.watch(appDatabaseProvider);
            return FutureBuilder<List<CategoriesTableData>>(
              future: db.select(db.categoriesTable).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final cats = snapshot.data!;
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Household Categories', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_rounded),
                            onPressed: () => _showAddCategoryDialog(context, ref),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: cats.length,
                        itemBuilder: (context, i) {
                          final c = cats[i];
                          final isSystem = c.isSystem ?? false;
                          return ListTile(
                            title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${c.kind.toUpperCase()} ${c.needOrWant != null ? "• ${c.needOrWant}" : ""}'),
                            leading: const Icon(Icons.category_rounded),
                            trailing: !isSystem
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 20),
                                        onPressed: () => _showEditCategoryDialog(context, ref, c),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Delete Category'),
                                              content: Text('Delete custom category "${c.name}"?'),
                                              actions: [
                                                TextButton(
                                                    onPressed: () => Navigator.pop(ctx, false),
                                                    child: const Text('Cancel')),
                                                FilledButton(
                                                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await (db.delete(db.categoriesTable)..where((cat) => cat.id.equals(c.id))).go();
                                            if (context.mounted) Navigator.pop(context);
                                          }
                                        },
                                      ),
                                    ],
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showEditCategoryDialog(BuildContext context, WidgetRef ref, CategoriesTableData cat) {
    final nameCtrl = TextEditingController(text: cat.name);
    String kind = cat.kind;
    String needOrWant = cat.needOrWant ?? 'need';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Custom Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Category Name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: kind,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'spending', child: Text('Expense')),
                  DropdownMenuItem(value: 'income', child: Text('Income')),
                  DropdownMenuItem(value: 'adjustment', child: Text('Adjustment')),
                  DropdownMenuItem(value: 'protection', child: Text('Protection')),
                  DropdownMenuItem(value: 'saving', child: Text('Saving')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => kind = v);
                },
              ),
              if (kind == 'spending') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: needOrWant,
                  decoration: const InputDecoration(labelText: 'Need / Want'),
                  items: const [
                    DropdownMenuItem(value: 'need', child: Text('Need')),
                    DropdownMenuItem(value: 'want', child: Text('Want')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => needOrWant = v);
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                final db = ref.read(appDatabaseProvider);
                await (db.update(db.categoriesTable)..where((c) => c.id.equals(cat.id)))
                    .write(CategoriesTableCompanion(
                  name: Value(name),
                  kind: Value(kind),
                  needOrWant: kind == 'spending' ? Value(needOrWant) : const Value.absent(),
                ));

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    String kind = 'spending';
    String needOrWant = 'need';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Add Custom Category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Category Name'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: kind,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(value: 'spending', child: Text('Expense')),
                      DropdownMenuItem(value: 'income', child: Text('Income')),
                      DropdownMenuItem(value: 'adjustment', child: Text('Adjustment')),
                      DropdownMenuItem(value: 'protection', child: Text('Protection')),
                      DropdownMenuItem(value: 'saving', child: Text('Saving')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => kind = v);
                    },
                  ),
                  if (kind == 'spending') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: needOrWant,
                      decoration: const InputDecoration(labelText: 'Need / Want'),
                      items: const [
                        DropdownMenuItem(value: 'need', child: Text('Need')),
                        DropdownMenuItem(value: 'want', child: Text('Want')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => needOrWant = v);
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;

                    final db = ref.read(appDatabaseProvider);
                    final auth = ref.read(authStateProvider).valueOrNull;
                    final householdId = auth?.householdId ?? 'demo-household';

                    await db.categoryDao.upsertAll([
                      CategoriesTableCompanion.insert(
                        id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
                        householdId: householdId,
                        kind: kind,
                        name: name,
                        needOrWant: kind == 'spending' ? Value(needOrWant) : const Value.absent(),
                        isDeduction: const Value(false),
                        isSystem: const Value(false),
                        sortOrder: const Value(100),
                      )
                    ]);

                    if (context.mounted) {
                      Navigator.pop(context); // Close add category dialog
                      Navigator.pop(context); // Close bottom sheet
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Custom category added!')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportToCsv(BuildContext context, WidgetRef ref) async {
    final db = ref.read(appDatabaseProvider);
    final entries = await db.select(db.entriesTable).get();

    if (entries.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No entries found to export.')),
        );
      }
      return;
    }

    final csvBuffer = StringBuffer();
    csvBuffer.writeln('ID,Date,Category,Type,Amount (Paise),Note');
    for (final e in entries) {
      csvBuffer.writeln('${e.id},${e.entryDate.toIso8601String().split('T').first},${e.categoryId},${e.kind},${e.amountPaise},${e.note ?? ""}');
    }

    try {
      final resultPath = await exportCsv(csvBuffer.toString());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported: $resultPath'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _forceSync(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final count = await ref.read(syncServiceProvider).syncAllQueue();
      if (context.mounted) {
        Navigator.pop(context); // Pop loading spinner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Force sync completed! Synced $count entries.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    }
  }

  void _showServerUrlDialog(BuildContext context, WidgetRef ref) {
    final currentUrl = ref.read(serverUrlProvider);
    final ctrl = TextEditingController(text: currentUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Server Connection URL'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'e.g. http://10.0.2.2:3000',
            helperText: 'Host IP address for physical devices',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(serverUrlProvider.notifier).state = ctrl.text.trim();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode m) => switch (m) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        ThemeMode.system => 'System default',
      };

  void _showThemePicker(BuildContext context, WidgetRef ref, ThemeMode current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map(
            (m) => ListTile(
              title: Text(_themeModeLabel(m), style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: m == current ? Icon(Icons.check_rounded, color: Theme.of(context).colorScheme.primary) : null,
              onTap: () {
                ref.read(themeModeProvider.notifier).state = m;
                Navigator.pop(context);
              },
            ),
          ).toList(),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PressableScale(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Card(
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: cs.primary),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(color: cs.onSurfaceVariant)) : null,
          trailing: trailing,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
