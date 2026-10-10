import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/library_providers.dart';
import '../../data/models/entry.dart';
import '../../data/operations/operations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/chips.dart';
import '../../widgets/entry_row.dart';
import '../../widgets/labels.dart';
import '../../widgets/section_heading.dart';
import '../../widgets/segmented_control.dart';
import '../../widgets/sheet_frame.dart';
import '../library/cover_placeholder.dart';
import '../plans/plan_progress.dart';
import '../settings/display_preferences.dart';
import '../settings/entry_view.dart';
import 'add_to_plan_sheet.dart';
import 'delete_entry_dialog.dart';
import 'entry_form_screen.dart';
import 'rating_sheet.dart';

/// Opens the entry details sheet (A6) for the entry with [entryId].
Future<void> showEntryDetailsSheet(BuildContext context, String entryId) {
  return showAppSheet<void>(
    context,
    builder: (context) => EntryDetailsSheet(entryId: entryId),
  );
}

/// Entry details (A6): cover spot, status, rating, note, about, tags,
/// plans, Edit and Delete. Watches the library, so a change made here or
/// in the edit form shows at once. Status and rating apply immediately.
class EntryDetailsSheet extends ConsumerWidget {
  const EntryDetailsSheet({super.key, required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = LibraryColors.of(context);
    final libraryAsync = ref.watch(libraryProvider);
    // The sheet may be the first to watch the library; wait for it.
    if (!libraryAsync.hasValue) return const SizedBox(height: 120);
    final library = libraryAsync.value!;
    final entry = library.entryById(entryId);
    if (entry == null) {
      // Gone, e.g. deleted from somewhere else. Nothing to show.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
      return const SizedBox(height: 120);
    }
    final repository = ref.read(libraryRepositoryProvider);
    final plans = library.plans
        .where((p) => p.itemFor(entry.id) != null)
        .toList();
    final showCover =
        ref.watch(displayPreferencesProvider).viewFor(entry.type) !=
        EntryView.text;
    final typeColor = colors.forType(entry.type);

    Future<void> pickRating() async {
      final choice = await showRatingSheet(
        context,
        title: entry.title,
        current: entry.rating,
      );
      if (choice != null && choice.rating != entry.rating) {
        await repository.apply(SetRating(entry.id, choice.rating));
      }
    }

    Future<void> delete() async {
      final ok = await confirmDeleteEntry(context, entry: entry, plans: plans);
      if (!ok) return;
      await repository.apply(DeleteEntry(entry.id));
      if (context.mounted) Navigator.of(context).pop();
    }

    return SheetFrame(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showCover) ...[
                CoverPlaceholder(entry: entry, width: 84, fontSize: 10),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _kindLine(entry),
                        style: theme.textTheme.labelSmall!.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: typeColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(entry.title, style: theme.textTheme.headlineSmall),
                      if (entry.creator case final creator?
                          when creator.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          entry.kind != null && entry.album != null
                              ? '$creator · ${entry.album}'
                              : creator,
                          style: theme.textTheme.bodyMedium!.copyWith(
                            fontSize: 14.5,
                            height: 1.2,
                            color: colors.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          const SectionHeading('Status', padding: EdgeInsets.zero),
          const SizedBox(height: 6),
          StatusSegmentedControl(
            selected: entry.status,
            type: entry.type,
            kind: entry.kind,
            style: SegmentedStyle.accent,
            inset: true,
            onChanged: (status) {
              if (status != null && status != entry.status) {
                repository.apply(SetStatus(entry.id, status));
              }
            },
          ),
          const SizedBox(height: 13),
          _BorderedRow(
            onTap: pickRating,
            semanticsLabel: 'Rating, ${ratingLabel(entry.rating)}',
            minHeight: 48,
            leading: Text(
              'Rating',
              style: theme.textTheme.bodyMedium!.copyWith(
                fontSize: 15,
                color: colors.muted,
              ),
            ),
            trailing: Text(
              ratingLabel(entry.rating),
              style: theme.textTheme.titleMedium!.copyWith(fontSize: 15),
            ),
          ),
          if (entry.note.isNotEmpty) ...[
            const SizedBox(height: 13),
            const SectionHeading('Note', padding: EdgeInsets.zero),
            const SizedBox(height: 6),
            Text(entry.note, style: theme.textTheme.bodyMedium),
          ],
          if (entry.description.isNotEmpty) ...[
            const SizedBox(height: 13),
            const SectionHeading('About', padding: EdgeInsets.zero),
            const SizedBox(height: 6),
            Text(
              entry.description,
              style: theme.textTheme.bodyMedium!.copyWith(
                fontSize: 14.5,
                color: colors.soft,
              ),
            ),
          ],
          if (entry.tags.isNotEmpty) ...[
            const SizedBox(height: 13),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final tag in entry.tags) TagChip(tag)],
            ),
          ],
          const SizedBox(height: 13),
          _BorderedRow(
            onTap: () => showAddToPlanSheet(context, entry.id),
            semanticsLabel: 'Add to plan',
            minHeight: 52,
            leading: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plans.isEmpty ? 'Plans' : 'In plans',
                  style: theme.textTheme.bodySmall!.copyWith(
                    fontSize: 13,
                    fontStyle: FontStyle.normal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  plans.isEmpty
                      ? 'Not in any plan'
                      : plans.map(planTitle).join(', '),
                  style: theme.textTheme.titleMedium!.copyWith(fontSize: 15),
                ),
              ],
            ),
            trailing: Text(
              'Add to plan',
              style: theme.textTheme.labelMedium!.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Edit',
                  kind: AppButtonKind.neutral,
                  onPressed: () => openEditEntryForm(context, entry),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  label: 'Delete',
                  kind: AppButtonKind.destructive,
                  onPressed: delete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// "MOVIE · 1999", "SONG · 1981", or just the kind without a date.
  static String _kindLine(Entry entry) {
    final year = entry.year;
    return [
      entryKindLabel(entry),
      if (year != null) '$year',
    ].join(' · ').toUpperCase();
  }
}

/// A tappable row between two hairlines: the rating and plans rows of A6.
class _BorderedRow extends StatelessWidget {
  const _BorderedRow({
    required this.onTap,
    required this.leading,
    required this.trailing,
    required this.minHeight,
    this.semanticsLabel,
  });

  final VoidCallback onTap;
  final Widget leading;
  final Widget trailing;
  final double minHeight;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = LibraryColors.of(context);
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: colors.surfaceHigh),
            ),
          ),
          child: Row(
            children: [
              Expanded(child: leading),
              const SizedBox(width: 12),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
