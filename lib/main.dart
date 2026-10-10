import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/library_providers.dart';
import 'data/repository/fixture_library_repository.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        libraryRepositoryProvider.overrideWithValue(FixtureLibraryRepository()),
      ],
      child: const LibraryApp(),
    ),
  );
}

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Library',
      theme: buildTheme(brightness: Brightness.light),
      darkTheme: buildTheme(brightness: Brightness.dark),
      themeMode: ThemeMode.dark,
      home: const _HomePlaceholder(),
    );
  }
}

/// Stands in for the app shell until phase 1a. Shows that the theme, the
/// fonts and the fixture repository all work together.
class _HomePlaceholder extends ConsumerWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Library', style: textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(switch (library) {
                AsyncData(:final value) =>
                  '${value.entries.length} entries, ${value.plans.length} plans',
                AsyncError(:final error) =>
                  'Could not load the fixture: $error',
                _ => 'Loading…',
              }, style: textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
