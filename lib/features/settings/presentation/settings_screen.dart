import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kReleaseMode, kDebugMode;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:dio/dio.dart';

import '../../../core/utils/csv_exporter/csv_exporter.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/timezone_utils.dart';
import '../../../core/utils/app_feedback.dart';
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
            subtitle: _backupStatusLabel(ref),
            onTap: () => _forceSync(context, ref),
          ),
          // Backup state must be visible WITHOUT tapping anything. A user whose
          // sync has quietly been failing needs to see it before they decide to
          // reinstall the app.
          const _BackupStatusBanner(),

          if (kDebugMode) ...[
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
          ],

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
                        AppFeedback.showWarning(
                          context,
                          'No lock screen configured on this device. Set up a PIN, pattern, or biometric first.',
                        );
                      }
                      return;
                    }

                    final ok = await svc.authenticate(
                      reason: 'Authenticate to enable Lock App',
                    );
                    if (!ok) {
                      if (context.mounted) {
                        AppFeedback.showWarning(
                          context,
                          'Authentication failed or cancelled.',
                        );
                      }
                      return;
                    }

                    await svc.setEnabled(true);
                    ref.read(appUnlockedProvider.notifier).state = true;
                    if (context.mounted) {
                      AppFeedback.showSuccess(context, 'Lock App enabled.');
                    }
                  } else {
                    final ok = await svc.authenticate(
                      reason: 'Authenticate to disable Lock App',
                    );
                    if (!ok) {
                      if (context.mounted) {
                        AppFeedback.showWarning(
                          context,
                          'Authentication failed. Lock App remains enabled.',
                        );
                      }
                      return;
                    }

                    await svc.setEnabled(false);
                    ref.read(appUnlockedProvider.notifier).state = true;
                    if (context.mounted) {
                      AppFeedback.showInfo(context, 'Lock App disabled.');
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
                  onTap: () => _handleSignOut(context, ref),
                  child: ListTile(
                    onTap: () => _handleSignOut(context, ref),
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
                  AppFeedback.showSuccess(context, 'Account permanently deleted.');
                  context.go('/auth/login');
                }
              } catch (e) {
                if (context.mounted) {
                  AppFeedback.showError(context, 'Failed to delete account', error: e);
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
              future: (db.select(db.categoriesTable)
                    ..where((c) => c.archivedAt.isNull()))
                  .get(),
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
                                          final confirm = await AppFeedback.showConfirmDialog(
                                            context,
                                            title: 'Delete Category',
                                            message: 'Delete custom category "${c.name}"?',
                                            confirmLabel: 'Delete',
                                            isDestructive: true,
                                          );
                                          if (confirm == true) {
                                            try {
                                              // Archive locally (matches server behavior: the category is
                                              // archived, never hard-deleted, so historical entries that
                                              // still reference it via categoryId keep resolving correctly
                                              // instead of crashing on a missing category lookup).
                                              await db.syncQueueDao.enqueueDeletion(entity: 'category', entityId: c.id);
                                              await db.categoryDao.softArchive(c.id);
                                              ref.read(syncServiceProvider).triggerSync();
                                              if (context.mounted) {
                                                Navigator.pop(context);
                                                AppFeedback.showSuccess(context, 'Category "${c.name}" deleted.');
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                AppFeedback.showError(context, 'Failed to delete category', error: e);
                                              }
                                            }
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
    final categoryCtrl = TextEditingController(
      text: (cat.groupCode != null && cat.groupCode!.isNotEmpty) ? cat.groupCode : cat.name,
    );
    final subcatCtrl = TextEditingController(text: cat.name);
    String kind = cat.kind;
    String needOrWant = cat.needOrWant ?? 'need';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final liveIcon = categoryIcon(subcatCtrl.text.isNotEmpty ? subcatCtrl.text : categoryCtrl.text, kind, categoryCtrl.text);
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
                                categoryCtrl.text.trim().isEmpty ? 'Type name to generate' : categoryCtrl.text.trim(),
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
                    controller: categoryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      hintText: 'e.g. Groceries',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: subcatCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Subcategory',
                      hintText: 'e.g. Food & Dining',
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
                  final category = categoryCtrl.text.trim();
                  final subcat = subcatCtrl.text.trim();
                  if (category.isEmpty) {
                    AppFeedback.showWarning(context, 'Please enter a category name.');
                    return;
                  }

                  final finalGroup = category;
                  final finalName = subcat.isNotEmpty ? subcat : category;

                  try {
                    final db = ref.read(appDatabaseProvider);
                    await (db.update(db.categoriesTable)..where((c) => c.id.equals(cat.id)))
                        .write(CategoriesTableCompanion(
                      name: Value(finalName),
                      groupCode: Value(finalGroup),
                      kind: Value(kind),
                      needOrWant: kind == 'spending' ? Value(needOrWant) : const Value.absent(),
                    ));
                    ref.read(syncServiceProvider).triggerSync();

                    if (context.mounted) {
                      Navigator.pop(context);
                      AppFeedback.showSuccess(context, 'Category updated successfully.');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppFeedback.showError(context, 'Failed to update category', error: e);
                    }
                  }
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
    final categoryCtrl = TextEditingController();
    final subcatCtrl = TextEditingController();
    String kind = 'spending';
    String needOrWant = 'need';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final liveIcon = categoryIcon(subcatCtrl.text.isNotEmpty ? subcatCtrl.text : categoryCtrl.text, kind, categoryCtrl.text);
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
                                  categoryCtrl.text.trim().isEmpty ? 'Type name to generate' : categoryCtrl.text.trim(),
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
                      controller: categoryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        hintText: 'e.g. Groceries',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: subcatCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Subcategory',
                        hintText: 'e.g. Food & Dining',
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
                    final category = categoryCtrl.text.trim();
                    final subcat = subcatCtrl.text.trim();
                    if (category.isEmpty) {
                      AppFeedback.showWarning(context, 'Please enter a category name.');
                      return;
                    }

                    final finalGroup = category;
                    final finalName = subcat.isNotEmpty ? subcat : category;

                    try {
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
                          groupCode: Value(finalGroup),
                          name: finalName,
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
                        AppFeedback.showSuccess(context, 'Custom category "$finalName" added!');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        AppFeedback.showError(context, 'Failed to add category', error: e);
                      }
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
    // DEF-DATA-05: export only the active household's live (not soft-deleted) entries.
    final householdId = ref.read(authStateProvider).valueOrNull?.householdId ?? 'local';
    final entries = await (db.select(db.entriesTable)
          ..where((e) => e.householdId.equals(householdId) & e.deletedAt.isNull())
          ..orderBy([(e) => OrderingTerm.asc(e.entryDate)]))
        .get();
    final categoryNames = {
      for (final c in await (db.select(db.categoriesTable)..where((c) => c.householdId.equals(householdId))).get())
        c.id: c.name,
    };

    if (entries.isEmpty) {
      if (context.mounted) {
        AppFeedback.showInfo(context, 'No entries found to export.');
      }
      return;
    }

    final csvBuffer = StringBuffer();
    // RFC 4180 quoting: fields containing comma, quote or line breaks are wrapped and quotes doubled.
    String csvField(String? value) {
      final v = value ?? '';
      if (v.contains(RegExp(r'[",\r\n]'))) return '"${v.replaceAll('"', '""')}"';
      return v;
    }

    csvBuffer.writeln('ID,Date,Category,Type,Amount (Paise),Note');
    for (final e in entries) {
      csvBuffer.writeln([
        csvField(e.id),
        e.entryDate.toIso8601String().split('T').first,
        csvField(categoryNames[e.categoryId] ?? e.categoryId),
        csvField(e.kind),
        e.amountPaise.toString(),
        csvField(e.note),
      ].join(','));
    }

    try {
      final resultPath = await exportCsv(csvBuffer.toString());

      if (context.mounted) {
        AppFeedback.showSuccess(context, 'Exported to CSV successfully: $resultPath');
      }
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showError(context, 'Export failed', error: e);
      }
    }
  }

  Future<void> _forceSync(BuildContext context, WidgetRef ref) async {
    final syncService = ref.read(syncServiceProvider);
    if (syncService.isSyncRunning) {
      AppFeedback.showInfo(context, 'A sync is already in progress.');
      return;
    }

    final cancelToken = CancelToken();
    bool isDialogDismissed = false;
    BuildContext? dialogContext;

    void dismissDialog() {
      if (!isDialogDismissed && dialogContext != null && dialogContext!.mounted) {
        isDialogDismissed = true;
        Navigator.of(dialogContext!, rootNavigator: true).pop();
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            cancelToken.cancel('User cancelled sync');
            dismissDialog();
          },
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text(
                  'Syncing with server...',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Backing up local data and fetching updates.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    cancelToken.cancel('User cancelled sync');
                    dismissDialog();
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final outcome = await syncService.syncAllQueue(
        cancelToken: cancelToken,
        timeout: const Duration(seconds: 60),
      );

      dismissDialog();
      if (!context.mounted) return;

      if (outcome.status == SyncStatus.cancelled) {
        // User cancelled; quietly return without showing errors or stale state.
        return;
      }

      if (outcome.status == SyncStatus.inProgress) {
        AppFeedback.showInfo(context, outcome.message);
        return;
      }

      if (outcome.status == SyncStatus.timedOut) {
        AppFeedback.showError(
          context,
          'Sync timed out. Your changes remain saved on this device.',
          error: outcome.error,
        );
        return;
      }

      if (!outcome.isSuccess) {
        AppFeedback.showError(context, outcome.message, error: outcome.error);
        return;
      }

      if (outcome.hasUnsyncedData) {
        AppFeedback.showWarning(context, outcome.message);
        return;
      }

      AppFeedback.showSuccess(context, outcome.message);
    } catch (e) {
      dismissDialog();
      if (context.mounted && !cancelToken.isCancelled) {
        AppFeedback.showError(context, 'Sync failed', error: e);
      }
    } finally {
      dismissDialog();
    }
  }

  /// One-line backup state for the Force Sync tile: how long ago the device
  /// last reached the server, and how much is still waiting.
  String _backupStatusLabel(WidgetRef ref) {
    // Kick off the one-time load of the persisted timestamp.
    ref.watch(lastSyncBootstrapProvider);

    final pending = ref.watch(pendingSyncCountProvider).valueOrNull ?? 0;
    final lastSync = ref.watch(lastSyncAtProvider);

    final backedUp = lastSync == null
        ? 'Never backed up'
        : 'Last backup ${_relativeTime(lastSync)}';

    if (pending == 0) return backedUp;
    return '$backedUp • $pending waiting';
  }

  static String _relativeTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  /// Signs out, clearing this device's data only once the server has the
  /// user's changes.
  /// Prompts for confirmation, pushes pending work, and signs out cleanly.
  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('Sign Out'),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out? Your synchronized data remains safe on the cloud.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogCtx).colorScheme.error,
              foregroundColor: Theme.of(dialogCtx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    BuildContext? progressCtx;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        progressCtx = ctx;
        return const PopScope(
          canPop: false,
          child: Center(
            child: Card(
              elevation: 6,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Signing out...', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    int unsynced = 0;
    try {
      unsynced = await ref.read(authStateNotifierProvider.notifier).logout();
    } catch (e) {
      if (progressCtx != null && progressCtx!.mounted) {
        Navigator.of(progressCtx!).pop();
      }
      if (context.mounted) {
        AppFeedback.showError(context, 'Sign out failed', error: e);
      }
      return;
    }

    if (progressCtx != null && progressCtx!.mounted) {
      Navigator.of(progressCtx!).pop();
    }

    if (unsynced > 0 && context.mounted) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Unsynced changes'),
          content: Text(
            '$unsynced change${unsynced == 1 ? '' : 's'} could not be sent to the '
            'server, so they exist only on this phone.\n\n'
            'They have been kept. Sign in again with the same account while '
            'connected to upload them.\n\n'
            'Removing them now deletes them permanently.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Keep on this device'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogCtx).colorScheme.error,
              ),
              child: const Text('Delete anyway'),
            ),
          ],
        ),
      );

      if (discard == true) {
        await ref.read(authStateNotifierProvider.notifier).logout(force: true);
      }
    }

    if (context.mounted) {
      context.go('/auth/login');
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
              final url = ctrl.text.trim();
              if (url.isEmpty) {
                AppFeedback.showWarning(context, 'Please enter a server URL.');
                return;
              }
              if (!url.startsWith('http://') && !url.startsWith('https://')) {
                AppFeedback.showWarning(context, 'Server URL must start with http:// or https://');
                return;
              }
              // SECURITY: release builds must not talk to a plaintext endpoint.
              // Loopback/emulator hosts stay permitted so local debugging works.
              if (kReleaseMode && url.startsWith('http://')) {
                final host = Uri.tryParse(url)?.host ?? '';
                if (!isLoopbackHost(host)) {
                  AppFeedback.showWarning(
                    context,
                    'Server URL must use https:// — plain HTTP is not allowed.',
                  );
                  return;
                }
              }
              ref.read(serverUrlProvider.notifier).state = url;
              Navigator.pop(context);
              AppFeedback.showSuccess(context, 'Server URL updated.');
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


/// Warns when this device holds financial records the server never received.
///
/// This is the surface that was missing when a user lost data: sync had been
/// failing silently, nothing on screen indicated it, and they reinstalled the
/// app believing everything was safely on the server.
class _BackupStatusBanner extends ConsumerWidget {
  const _BackupStatusBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(syncHealthProvider);
    if (health == SyncHealth.healthy) return const SizedBox.shrink();

    final pending = ref.watch(pendingSyncCountProvider).valueOrNull ?? 0;
    final lastSync = ref.watch(lastSyncAtProvider);
    final isStale = health == SyncHealth.stale;
    final cs = Theme.of(context).colorScheme;

    final color = isStale ? cs.error : Colors.amber.shade800;
    final plural = pending == 1 ? '' : 's';

    String text;
    if (!isStale) {
      text = '$pending change$plural waiting to be backed up.';
    } else if (lastSync == null) {
      text = '$pending change$plural have never been backed up. '
          'They exist only on this phone — do not uninstall the app.';
    } else {
      text = '$pending change$plural have not reached the server since '
          '${SettingsScreen._relativeTime(lastSync)}. '
          'They exist only on this phone.';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isStale ? Icons.warning_amber_rounded : Icons.cloud_upload_outlined,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
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
    final displayName = widget.ref.read(authStateProvider).valueOrNull?.displayName;
    final nameCtrl = TextEditingController();
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
              decoration: InputDecoration(
                labelText: 'Household Name *',
                hintText: displayName != null && displayName.isNotEmpty
                    ? "e.g. $displayName's Household"
                    : 'e.g. My Household',
                border: const OutlineInputBorder(),
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
      final name = nameCtrl.text.trim();
      if (name.isEmpty) {
        AppFeedback.showWarning(context, 'Please enter a household name.');
        return;
      }
      try {
        final newId = await widget.ref
            .read(authStateNotifierProvider.notifier)
            .createHousehold(name);
        if (mounted) {
          AppFeedback.showSuccess(context, 'Household created successfully! ID: $newId');
          _loadHousehold();
        }
      } catch (e) {
        if (mounted) {
          AppFeedback.showError(context, 'Failed to create household', error: e);
        }
      }
    }
  }

  Future<void> _handleJoinHousehold() async {
    final codeCtrl = TextEditingController();
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
              'Enter the 8-character invite code provided by your family\'s household owner.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              textCapitalization: TextCapitalization.characters,
              maxLength: 8,
              decoration: InputDecoration(
                labelText: 'Invite Code *',
                hintText: 'e.g. 7K2P9XQ4',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste_rounded),
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      codeCtrl.text = data!.text!.trim().toUpperCase();
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
      final inputCode = codeCtrl.text.trim().toUpperCase();
      if (inputCode.isEmpty || inputCode.length != 8) {
        AppFeedback.showWarning(context, 'Please enter a valid 8-character invite code.');
        return;
      }
      try {
        await widget.ref
            .read(authStateNotifierProvider.notifier)
            .joinHousehold(inputCode);
        if (mounted) {
          AppFeedback.showSuccess(context, 'Successfully joined household!');
          _loadHousehold();
        }
      } catch (e) {
        if (mounted) {
          AppFeedback.showError(context, 'Failed to join household', error: e);
        }
      }
    }
  }

  /// Owner-only: request a fresh invite code from the server and display it.
  Future<void> _handleGenerateInvite() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await widget.ref
          .read(authStateNotifierProvider.notifier)
          .generateHouseholdInvite();

      if (!mounted) return;
      Navigator.pop(context); // dismiss spinner

      final code = result['code'] as String? ?? '';
      final expiresAtRaw = result['expiresAt'] as String? ?? '';
      String expiryLabel = expiresAtRaw;
      try {
        final dt = DateTime.parse(expiresAtRaw).toLocal();
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        expiryLabel = '${dt.day}/${dt.month}/${dt.year} at $h:$m';
      } catch (_) {}

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Invite Code Generated'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Share this code with the person you want to add. It can only be used once and expires in 24 hours.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Expires: $expiryLabel',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copy Code'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                AppFeedback.showInfo(context, 'Invite code copied to clipboard!');
              },
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // dismiss spinner
      AppFeedback.showError(context, 'Failed to generate invite code', error: e);
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
            labelText: 'New Household Name *',
            hintText: 'e.g. Smith Family',
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
      if (newName.isEmpty) {
        AppFeedback.showWarning(context, 'Please enter a household name.');
        return;
      }
      try {
        await widget.ref
            .read(authStateNotifierProvider.notifier)
            .updateHouseholdName(newName);
        if (mounted) {
          AppFeedback.showSuccess(context, 'Household name updated!');
          _loadHousehold();
        }
      } catch (e) {
        if (mounted) {
          AppFeedback.showError(context, 'Failed to update household name', error: e);
        }
      }
    }
  }

  Future<void> _handleDeleteHousehold(String householdName) async {
    final confirmed = await AppFeedback.showConfirmDialog(
      context,
      title: 'Delete Household',
      message: 'Are you sure you want to delete "$householdName"?\n\nAll member associations and household data will be permanently removed. This action cannot be undone.',
      confirmLabel: 'Delete Household',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      try {
        await widget.ref
            .read(authStateNotifierProvider.notifier)
            .deleteHousehold();
        if (mounted) {
          AppFeedback.showSuccess(context, 'Household deleted successfully.');
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          AppFeedback.showError(context, 'Failed to delete household', error: e);
        }
      }
    }
  }

  Future<void> _handleRemoveMember(String memberId, String memberName) async {
    final confirmed = await AppFeedback.showConfirmDialog(
      context,
      title: 'Remove Family Member',
      message: 'Remove "$memberName" from this household?\n\nThey will lose access to this household without affecting other members.',
      confirmLabel: 'Remove',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      try {
        await widget.ref
            .read(authStateNotifierProvider.notifier)
            .removeHouseholdMember(memberId);
        if (mounted) {
          AppFeedback.showSuccess(context, 'Removed "$memberName" from household.');
          _loadHousehold();
        }
      } catch (e) {
        if (mounted) {
          AppFeedback.showError(context, 'Failed to remove member', error: e);
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
                                            AppFeedback.showInfo(context, 'Household ID copied to clipboard!');
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

                              const SizedBox(height: 12),
                              // Owner-only: Generate invite code button
                              if (isOwner)
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.link_rounded, size: 18),
                                    label: const Text(
                                      'Generate Invite Code',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    onPressed: _handleGenerateInvite,
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