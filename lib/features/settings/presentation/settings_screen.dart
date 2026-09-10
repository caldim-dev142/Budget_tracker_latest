import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' hide Column;

import '../../../core/utils/csv_exporter/csv_exporter.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/timezone_utils.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../providers/settings_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../data/local/database.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/security/app_lock_service.dart';
import '../../../core/constants/legal_constants.dart';
final householdNameProvider = StateProvider<String>((ref) => 'Smith Family');

/// S18 — Settings / Profile / Household (doc 09 S18).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authStateNotifierProvider).valueOrNull;
    final lockEnabled = ref.watch(appLockEnabledProvider);
    final selectedTzId = ref.watch(selectedTimezoneIdProvider);
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
                                  child: const Row(
                                    children: [
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
          const SizedBox(height: 6),
          _SettingsTile(
            icon: Icons.schedule_outlined,
            title: 'Timezone',
            subtitle: kTimezones.firstWhere((tz) => tz.id == selectedTzId, orElse: () => kTimezones.first).label,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showTimezonePicker(context, ref, selectedTzId),
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
              leading: Icon(Icons.lock_outline_rounded, color: cs.primary),
              title: const Text('Lock App', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                lockEnabled ? 'Uses device authentication' : 'Off',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              trailing: Switch(
                value: lockEnabled,
                onChanged: (v) async {
                  final svc = ref.read(appLockServiceProvider);
                  if (v) {
                    final supported = await svc.canAuthenticate();
                    if (!supported) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No lock screen configured on this device. Set up a PIN, pattern, or biometric first.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                      return;
                    }

                    final ok = await svc.authenticate(
                      reason: 'Authenticate to enable Lock App',
                    );
                    if (!ok) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Authentication failed or cancelled.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                      return;
                    }

                    await svc.setEnabled(true);
                    ref.read(appUnlockedProvider.notifier).state = true;
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lock App enabled.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } else {
                    final ok = await svc.authenticate(
                      reason: 'Authenticate to disable Lock App',
                    );
                    if (!ok) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Authentication failed. Lock App remains enabled.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                      return;
                    }

                    await svc.setEnabled(false);
                    ref.read(appUnlockedProvider.notifier).state = true;
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lock App disabled.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ),

          // Legal & About Section
          const SizedBox(height: 24),
          Text(
            'Legal & About',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  subtitle: const Text('Read how your data is protected'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => LegalConstants.showPrivacyPolicyDialog(context),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms of Service'),
                  subtitle: const Text('Terms and conditions of use'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => LegalConstants.showTermsDialog(context),
                ),
                const Divider(height: 1, indent: 56),
                const ListTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('App Version'),
                  subtitle: Text('1.0.0 (Build 1)'),
                ),
              ],
            ),
          ),

          // Sign out & Account Deletion
          const SizedBox(height: 24),
          Text(
            'Account Actions',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            color: cs.errorContainer.withValues(alpha: 0.15),
            child: Column(
              children: [
                PressableScale(
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
                if (authState != null && authState.isAuthenticated) ...[
                  const Divider(height: 1, indent: 56),
                  PressableScale(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _showDeleteAccountDialog(context, ref),
                    child: ListTile(
                      leading: Icon(Icons.delete_forever_rounded, color: cs.error),
                      title: Text(
                        'Delete Account',
                        style: TextStyle(color: cs.error, fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        'Permanently delete your profile and personal data',
                        style: TextStyle(color: cs.error.withValues(alpha: 0.8), fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Delete Account?'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete your account?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'This action is irreversible. All your profile information, authentication credentials, and personal data will be permanently removed.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              try {
                await ref.read(authStateNotifierProvider.notifier).deleteAccount();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account permanently deleted.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  context.go('/auth/login');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete account: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _showHouseholdDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => _ManageHouseholdDialog(ref: ref),
    );
  }

  void _showMembersDialog(BuildContext context, WidgetRef ref, AuthState authState) {
    _showHouseholdDialog(context, ref);
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
                          final isSystem = c.isSystem;
                          return ListTile(
                            title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${c.kind.toUpperCase()} ${c.needOrWant != null ? "• ${c.needOrWant}" : ""}'),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: categoryIconColor(c.kind).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                categoryIcon(c.name, c.kind, c.groupCode),
                                color: categoryIconColor(c.kind),
                                size: 20,
                              ),
                            ),
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
    final groupCtrl = TextEditingController(text: cat.groupCode ?? '');
    String kind = cat.kind;
    String needOrWant = cat.needOrWant ?? 'need';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final liveIcon = categoryIcon(nameCtrl.text, kind, groupCtrl.text);
          final liveColor = categoryIconColor(kind);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Edit Custom Category'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: liveColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: liveColor.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: liveColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(liveIcon, color: liveColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Generated Icon',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: liveColor,
                                ),
                              ),
                              Text(
                                nameCtrl.text.trim().isEmpty ? 'Type name to generate' : nameCtrl.text.trim(),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Category Name *',
                      hintText: 'e.g. Groceries, Fuel, Netflix',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: groupCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Subcategory / Group',
                      hintText: 'e.g. Food & Dining, Travel, Bills',
                    ),
                    onChanged: (_) => setState(() {}),
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
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final group = groupCtrl.text.trim();
                  if (name.isEmpty) return;

                  final db = ref.read(appDatabaseProvider);
                  await (db.update(db.categoriesTable)..where((c) => c.id.equals(cat.id)))
                      .write(CategoriesTableCompanion(
                    name: Value(name),
                    groupCode: group.isNotEmpty ? Value(group) : const Value.absent(),
                    kind: Value(kind),
                    needOrWant: kind == 'spending' ? Value(needOrWant) : const Value.absent(),
                  ));

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final groupCtrl = TextEditingController();
    String kind = 'spending';
    String needOrWant = 'need';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final liveIcon = categoryIcon(nameCtrl.text, kind, groupCtrl.text);
            final liveColor = categoryIconColor(kind);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Add Custom Category'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: liveColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: liveColor.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: liveColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(liveIcon, color: liveColor, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Generated Icon',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: liveColor,
                                  ),
                                ),
                                Text(
                                  nameCtrl.text.trim().isEmpty ? 'Type name to generate' : nameCtrl.text.trim(),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Category Name *',
                        hintText: 'e.g. Groceries, Fuel, Netflix',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: groupCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Subcategory / Group',
                        hintText: 'e.g. Food & Dining, Travel, Bills',
                      ),
                      onChanged: (_) => setState(() {}),
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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final group = groupCtrl.text.trim();
                    if (name.isEmpty) return;

                    final db = ref.read(appDatabaseProvider);
                    final auth = ref.read(authStateProvider).valueOrNull;
                    final householdId = (auth?.householdId != null && auth!.householdId!.isNotEmpty)
                        ? auth.householdId!
                        : 'local';

                    await db.categoryDao.upsertAll([
                      CategoriesTableCompanion.insert(
                        id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
                        householdId: householdId,
                        kind: kind,
                        groupCode: group.isNotEmpty ? Value(group) : const Value.absent(),
                        name: name,
                        needOrWant: kind == 'spending' ? Value(needOrWant) : const Value.absent(),
                        isDeduction: const Value(false),
                        isSystem: const Value(false),
                        sortOrder: const Value(100),
                      )
                    ]);

                    ref.read(syncServiceProvider).triggerSync();

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

  void _showTimezonePicker(BuildContext context, WidgetRef ref, String currentId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        final cs = Theme.of(context).colorScheme;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.92,
          minChildSize: 0.4,
          expand: false,
          builder: (_, ctrl) => Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.schedule_outlined, color: cs.primary, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Select Timezone',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: ctrl,
                  itemCount: kTimezones.length,
                  itemBuilder: (_, i) {
                    final tz = kTimezones[i];
                    final isSelected = tz.id == currentId;
                    return ListTile(
                      title: Text(
                        tz.label,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? cs.primary : cs.onSurface,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded, color: cs.primary)
                          : null,
                      onTap: () {
                        ref.read(selectedTimezoneIdProvider.notifier).state = tz.id;
                        ref.read(timezoneOffsetProvider.notifier).state = tz.offsetMinutes;
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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

class _ManageHouseholdDialog extends StatefulWidget {
  final WidgetRef ref;
  const _ManageHouseholdDialog({required this.ref});

  @override
  State<_ManageHouseholdDialog> createState() => _ManageHouseholdDialogState();
}

class _ManageHouseholdDialogState extends State<_ManageHouseholdDialog> {
  bool _loading = true;
  Map<String, dynamic>? _household;

  @override
  void initState() {
    super.initState();
    _loadHousehold();
  }

  Future<void> _loadHousehold() async {
    setState(() => _loading = true);
    try {
      final details = await widget.ref
          .read(authStateNotifierProvider.notifier)
          .fetchHouseholdDetails();
      if (mounted) {
        setState(() {
          _household = details;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _handleCreateHousehold() async {
    final nameCtrl = TextEditingController(
      text: '${widget.ref.read(authStateProvider).valueOrNull?.displayName ?? "My"}\'s Household',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Create Household'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A new unique household ID will be generated automatically once you click Create.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Household Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final newId = await widget.ref
            .read(authStateNotifierProvider.notifier)
            .createHousehold(nameCtrl.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Household created! ID: $newId')),
          );
          _loadHousehold();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create household: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleJoinHousehold() async {
    final idCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Join Household'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the household ID shared by your family owner to join their household.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: idCtrl,
              decoration: InputDecoration(
                labelText: 'Household ID',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste_rounded),
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      idCtrl.text = data!.text!.trim();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Join'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final inputId = idCtrl.text.trim();
      if (inputId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid Household ID.')),
        );
        return;
      }
      try {
        await widget.ref
            .read(authStateNotifierProvider.notifier)
            .joinHousehold(inputId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully joined household!')),
          );
          _loadHousehold();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
          );
        }
      }
    }
  }

  Future<void> _handleUpdateName(String currentName) async {
    final ctrl = TextEditingController(text: currentName);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Update Household Name'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'New Household Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final newName = ctrl.text.trim();
      if (newName.isEmpty) return;
      try {
        await widget.ref
            .read(authStateNotifierProvider.notifier)
            .updateHouseholdName(newName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Household name updated!')),
          );
          _loadHousehold();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update name: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteHousehold(String householdName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Household'),
        content: Text(
          'Are you sure you want to delete "$householdName"?\n\nAll member associations and household data will be permanently removed. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Household'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await widget.ref
            .read(authStateNotifierProvider.notifier)
            .deleteHousehold();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Household deleted successfully.')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete household: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleRemoveMember(String memberId, String memberName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Family Member'),
        content: Text(
          'Remove "$memberName" from this household?\n\nThey will lose access to this household without affecting other members.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await widget.ref
            .read(authStateNotifierProvider.notifier)
            .removeHouseholdMember(memberId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Removed "$memberName" from household.')),
          );
          _loadHousehold();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove member: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final household = _household;
    final isOwner = household?['isOwner'] == true;
    final members = (household?['members'] as List<dynamic>?) ?? [];
    final householdId = household?['id'] as String?;
    final householdName = household?['name'] as String? ?? 'Family Household';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.roofing_rounded, color: cs.primary, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        'Manage Household',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Two Required Options: Create Household and Join Household
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add_home_rounded, size: 18),
                      label: const Text('Create Household', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _handleCreateHousehold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.group_add_rounded, size: 18),
                      label: const Text('Join Household', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _handleJoinHousehold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),

              // Content: Loading / Household Info & Members / Empty
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : householdId == null || householdId.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.home_outlined, size: 48, color: cs.outline),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No Household Associated',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Choose "Create Household" to generate a new household or "Join Household" to join an existing family.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            children: [
                              // Household Info Card
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            householdName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ),
                                        if (isOwner)
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 18),
                                            tooltip: 'Update Household Name',
                                            onPressed: () => _handleUpdateName(householdName),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SelectableText(
                                            'ID: $householdId',
                                            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy_rounded, size: 16),
                                          tooltip: 'Copy Household ID',
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: householdId));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Household ID copied to clipboard!')),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isOwner ? cs.primaryContainer : cs.secondaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isOwner ? '👑 Family Owner' : '👤 Member',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isOwner ? cs.onPrimaryContainer : cs.onSecondaryContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),
                              // Members Section
                              Row(
                                children: [
                                  Icon(Icons.people_alt_outlined, size: 18, color: cs.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Joined Members (${members.length})',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              ...members.map((m) {
                                final member = m as Map<String, dynamic>;
                                final mId = member['id'] as String? ?? '';
                                final mName = member['displayName'] as String? ?? 'User';
                                final mEmail = member['email'] as String? ?? '';
                                final mRole = member['role'] as String? ?? 'member';
                                final isMemberOwner = mRole == 'owner';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: cs.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isMemberOwner ? cs.primaryContainer : cs.surfaceContainerHighest,
                                      child: Text(
                                        mName.isNotEmpty ? mName[0].toUpperCase() : '?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isMemberOwner ? cs.onPrimaryContainer : cs.onSurface,
                                        ),
                                      ),
                                    ),
                                    title: Text(mName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(mEmail, style: const TextStyle(fontSize: 12)),
                                    trailing: isMemberOwner
                                        ? const Chip(
                                            label: Text('Owner', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                            padding: EdgeInsets.zero,
                                            visualDensity: VisualDensity.compact,
                                          )
                                        : isOwner
                                            ? IconButton(
                                                icon: const Icon(Icons.person_remove_outlined, color: Colors.red, size: 20),
                                                tooltip: 'Remove Member',
                                                onPressed: () => _handleRemoveMember(mId, mName),
                                              )
                                            : const Chip(
                                                label: Text('Member', style: TextStyle(fontSize: 10)),
                                                padding: EdgeInsets.zero,
                                                visualDensity: VisualDensity.compact,
                                              ),
                                  ),
                                );
                              }),

                              // Delete Household Button (Owner only)
                              if (isOwner) ...[
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: cs.error,
                                    side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  icon: const Icon(Icons.delete_forever_rounded, size: 18),
                                  label: const Text('Delete Household', style: TextStyle(fontWeight: FontWeight.w600)),
                                  onPressed: () => _handleDeleteHousehold(householdName),
                                ),
                              ],
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
