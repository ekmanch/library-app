import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/library_providers.dart';
import '../../widgets/page_header.dart';
import '../shell/app_shell.dart';

/// Placeholder until A1 is built in phase 1b: the header and a count.
class LibraryHomeScreen extends ConsumerWidget {
  const LibraryHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppShell.contentBottomPadding),
          children: [
            PageHeader(
              title: 'Library',
              actions: [SettingsButton(onPressed: () {})],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(switch (library) {
                AsyncData(:final value) =>
                  '${value.entries.length} entries, '
                      '${value.plans.length} plans',
                AsyncError(:final error) =>
                  'Could not load the library: $error',
                _ => 'Loading…',
              }, style: textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
