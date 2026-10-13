import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/library_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/page_header.dart';
import '../../widgets/section_heading.dart';
import '../../widgets/setting_row.dart';
import '../first_run/first_run_flow.dart';
import '../sync/relative_time.dart';
import '../sync/sync_state.dart';

/// Opens D6 above everything, like Settings.
Future<void> openConnectionScreen(BuildContext context) {
  return Navigator.of(
    context,
    rootNavigator: true,
  ).push<void>(MaterialPageRoute(builder: (_) => const ConnectionScreen()));
}

/// Settings: library connection (D6). Status, the GitHub details, how
/// often the app checks for changes, and the buttons to replace the token
/// or disconnect. UI only until phase 4.
class ConnectionScreen extends ConsumerWidget {
  const ConnectionScreen({super.key});

  static const _sectionPadding = EdgeInsets.fromLTRB(0, 20, 0, 2);

  void _disconnect(BuildContext context, WidgetRef ref) {
    // The app's home swaps to the first run (F1) once disconnected; the
    // screens stacked above it go first.
    Navigator.of(context).popUntil((route) => route.isFirst);
    unawaited(ref.read(libraryConnectionProvider.notifier).disconnect());
  }

  /// "Last synced 3 minutes ago", or "Not synced yet".
  static String lastSyncedLabel(DateTime? lastSynced, {DateTime? now}) =>
      lastSynced == null
      ? 'Not synced yet'
      : 'Last synced ${relativeTime(lastSynced, now: now ?? DateTime.now())}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = LibraryColors.of(context);
    final connection = ref.watch(libraryConnectionProvider);
    final status = ref.watch(syncStatusProvider).value;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'Library connection',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: colors.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Connected',
                                style: theme.textTheme.titleMedium!.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                lastSyncedLabel(status?.lastSynced),
                                style: theme.textTheme.bodySmall!.copyWith(
                                  fontSize: 13,
                                  fontStyle: FontStyle.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppButton(
                          label: 'Sync now',
                          kind: AppButtonKind.outline,
                          compact: true,
                          horizontalPadding: 14,
                          onPressed: () =>
                              ref.read(librarySyncProvider)?.syncNow(),
                        ),
                      ],
                    ),
                  ),
                  const SectionHeading('GitHub', padding: _sectionPadding),
                  SettingRow(
                    label: 'Repository',
                    value: connection.repository,
                    minHeight: 56,
                  ),
                  SettingRow(
                    label: 'Data file',
                    value: connection.file,
                    minHeight: 56,
                  ),
                  const SettingRow(
                    label: 'Access token',
                    value: 'Saved on this phone',
                    minHeight: 56,
                  ),
                  const SectionHeading('Syncing', padding: _sectionPadding),
                  const SettingRow(
                    label: 'Check for changes',
                    detail: 'When you open Libri, then every 5 minutes',
                    minHeight: 56,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton(
                    label: 'Replace token',
                    kind: AppButtonKind.outline,
                    onPressed: () => openReplaceTokenScreen(context),
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Disconnect',
                    kind: AppButtonKind.destructive,
                    onPressed: () => _disconnect(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
