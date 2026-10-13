import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_info.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/libri_logo.dart';
import '../../widgets/radio_mark.dart';
import '../sync/sync_state.dart';

/// Opens the Connect GitHub step on its own, from "Replace token" in D6.
/// Pops when the token is saved.
Future<void> openReplaceTokenScreen(BuildContext context) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(builder: (_) => const FirstRunFlow.replaceToken()),
  );
}

enum FirstRunStep { splash, welcome, connect, file, create, existing, done }

enum _FileChoice { newFile, existing }

/// A JSON file in the repo, as F6 lists them. Static until phase 4.
class RepoFile {
  const RepoFile(this.path, {this.entries, this.updated});

  final String path;

  /// How many entries the library holds; null for a JSON file that is not
  /// a Libri library, which cannot be picked.
  final int? entries;
  final String? updated;

  bool get usable => entries != null;

  String get info => usable
      ? 'Libri library · $entries entries · updated $updated'
      : 'Not a Libri library file';

  static const sample = [
    RepoFile('library.json', entries: 214, updated: '2 days ago'),
    RepoFile('backup/library-2025.json', entries: 168, updated: 'in March'),
    RepoFile('data/old-lists.json'),
  ];
}

/// The first run (F1 to F7): splash, welcome, connect GitHub, new or
/// existing library file, create or pick it, all set. One screen whose
/// content changes with the step, like the canvas template. UI only: the
/// token and repo go nowhere until phase 4.
class FirstRunFlow extends ConsumerStatefulWidget {
  const FirstRunFlow({super.key, this.initialStep = FirstRunStep.splash})
    : replaceToken = false;

  /// Only the connect step, with a Save token button that pops.
  const FirstRunFlow.replaceToken({super.key})
    : initialStep = FirstRunStep.connect,
      replaceToken = true;

  final FirstRunStep initialStep;
  final bool replaceToken;

  /// How long the splash stays before the welcome screen.
  static const splashDuration = Duration(milliseconds: 900);

  /// The fake delay of "Create library" (F5).
  static const createDuration = Duration(milliseconds: 1400);

  @override
  ConsumerState<FirstRunFlow> createState() => _FirstRunFlowState();
}

class _FirstRunFlowState extends ConsumerState<FirstRunFlow> {
  late FirstRunStep _step = widget.initialStep;
  _FileChoice _choice = _FileChoice.newFile;
  int _file = 0;
  bool _creating = false;
  Timer? _timer;
  late final TextEditingController _repo;
  late final TextEditingController _token;
  late final TextEditingController _fileName;

  @override
  void initState() {
    super.initState();
    final connection = ref.read(libraryConnectionProvider);
    _repo = TextEditingController(text: connection.repository);
    _token = TextEditingController();
    _fileName = TextEditingController(text: connection.file);
    _repo.addListener(_refresh);
    _token.addListener(_refresh);
    _fileName.addListener(_refresh);
    if (_step == FirstRunStep.splash) {
      _timer = Timer(FirstRunFlow.splashDuration, () {
        if (mounted) setState(() => _step = FirstRunStep.welcome);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _repo.dispose();
    _token.dispose();
    _fileName.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _go(FirstRunStep step) => setState(() {
    _step = step;
    _creating = false;
  });

  /// The step a back goes to; null where there is no back.
  FirstRunStep? get _previous => switch (_step) {
    FirstRunStep.connect => FirstRunStep.welcome,
    FirstRunStep.file => FirstRunStep.connect,
    FirstRunStep.create || FirstRunStep.existing => FirstRunStep.file,
    _ => null,
  };

  void _back() {
    if (widget.replaceToken) {
      Navigator.pop(context);
    } else if (_previous case final step?) {
      _go(step);
    }
  }

  bool get _canConnect =>
      _repo.text.trim().contains('/') && _token.text.trim().isNotEmpty;

  void _connect() {
    if (widget.replaceToken) {
      Navigator.pop(context);
    } else {
      _go(FirstRunStep.file);
    }
  }

  void _create() {
    if (_creating) return;
    setState(() => _creating = true);
    _timer?.cancel();
    _timer = Timer(FirstRunFlow.createDuration, () {
      if (mounted) _go(FirstRunStep.done);
    });
  }

  void _finish() {
    // The app opens the library once the token and the connection are
    // stored; the branch is the repo's default from phase 4's F3.
    unawaited(
      ref
          .read(libraryConnectionProvider.notifier)
          .connect(
            repository: _repo.text.trim(),
            file: _choice == _FileChoice.newFile
                ? _fileName.text.trim()
                : RepoFile.sample[_file].path,
            branch: 'main',
            token: _token.text.trim(),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = _previous == null && !widget.replaceToken;
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: SafeArea(
          child: switch (_step) {
            FirstRunStep.splash => const _Splash(),
            FirstRunStep.welcome => _Welcome(
              onStart: () => _go(FirstRunStep.connect),
            ),
            FirstRunStep.connect => _StepPage(
              label: widget.replaceToken ? null : 'Step 1 of 3',
              onBack: _back,
              title: 'Connect GitHub',
              body:
                  'Libri reads and saves your library in a GitHub repo you '
                  'own. A private repo is fine.',
              content: [
                const FieldLabel('Repository'),
                AppTextField(
                  controller: _repo,
                  hintText: 'owner/repo',
                  textCapitalization: TextCapitalization.none,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                const FieldLabel('Access token'),
                AppTextField(
                  controller: _token,
                  hintText: 'github_pat_…',
                  obscureText: true,
                  textCapitalization: TextCapitalization.none,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _canConnect ? _connect() : null,
                ),
                const SizedBox(height: 6),
                const _Help(
                  'A fine-grained token that can read and write this one '
                  'repo. It stays in the phone\'s secure storage and never '
                  'leaves the device.',
                ),
              ],
              footer: [
                AppButton(
                  label: widget.replaceToken ? 'Save token' : 'Connect',
                  onPressed: _canConnect ? _connect : null,
                ),
                const SizedBox(height: 10),
                // Phase 4 opens GitHub's token page here.
                const AppButton(
                  label: 'How do I create a token?',
                  kind: AppButtonKind.text,
                  onPressed: null,
                ),
              ],
            ),
            FirstRunStep.file => _StepPage(
              label: 'Step 2 of 3',
              onBack: _back,
              title: 'Your library file',
              body:
                  'Libri keeps everything in one JSON file in '
                  '${_repo.text.trim()}. Start fresh, or use a file you '
                  'already have.',
              bodyHighlight: _repo.text.trim(),
              content: [
                _ChoiceCard(
                  icon: AppIcons.filePlus,
                  title: 'Create a new library',
                  body:
                      'Libri makes an empty library file in your repo. '
                      'Pick this if you are starting out.',
                  selected: _choice == _FileChoice.newFile,
                  onTap: () => setState(() => _choice = _FileChoice.newFile),
                ),
                const SizedBox(height: 12),
                _ChoiceCard(
                  icon: AppIcons.folder,
                  title: 'Use a file I already have',
                  body:
                      'Pick a Libri library file that is already in the repo.',
                  selected: _choice == _FileChoice.existing,
                  onTap: () => setState(() => _choice = _FileChoice.existing),
                ),
              ],
              footer: [
                AppButton(
                  label: 'Continue',
                  onPressed: () => _go(
                    _choice == _FileChoice.newFile
                        ? FirstRunStep.create
                        : FirstRunStep.existing,
                  ),
                ),
              ],
            ),
            FirstRunStep.create => _StepPage(
              label: 'Step 3 of 3',
              onBack: _back,
              title: 'Create a new library',
              body:
                  'Libri adds an empty library file to your repo and '
                  'commits it for you.',
              content: [
                const FieldLabel('File name'),
                AppTextField(
                  controller: _fileName,
                  hintText: 'library.json',
                  textCapitalization: TextCapitalization.none,
                ),
                const SizedBox(height: 6),
                _Help(
                  'Saved at the top of ${_repo.text.trim()}. Libri never '
                  'overwrites a file that already exists.',
                ),
                const SizedBox(height: 16),
                const FieldLabel('What gets added'),
                const _CodeBlock(
                  '{\n'
                  '  "version": 2,\n'
                  '  "tags": {},\n'
                  '  "entries": [],\n'
                  '  "plans": []\n'
                  '}',
                ),
                const SizedBox(height: 6),
                const _Help('Commit message: “Create Libri library”'),
              ],
              footer: [
                if (_creating)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Creating ${_fileName.text.trim()} and pushing to '
                      'GitHub…',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall!
                          .copyWith(fontSize: 14, fontStyle: FontStyle.normal),
                    ),
                  ),
                // Dimmed rather than disabled while creating, as on the
                // canvas; _create ignores a second press.
                Opacity(
                  opacity: _creating ? 0.6 : 1,
                  child: AppButton(
                    label: _creating ? 'Creating…' : 'Create library',
                    onPressed: _fileName.text.trim().isEmpty ? null : _create,
                  ),
                ),
              ],
            ),
            FirstRunStep.existing => _StepPage(
              label: 'Step 3 of 3',
              onBack: _back,
              title: 'Pick your file',
              body:
                  'JSON files found in ${_repo.text.trim()}. Only files in '
                  'Libri\'s format can be used.',
              contentTopPadding: 20,
              content: [
                for (final (i, file) in RepoFile.sample.indexed)
                  _FileRow(
                    file: file,
                    selected: file.usable && i == _file,
                    onTap: file.usable ? () => setState(() => _file = i) : null,
                  ),
                const SizedBox(height: 14),
                const _Help(
                  'Don\'t see your file? Make sure it\'s in this repo and '
                  'ends in .json.',
                ),
              ],
              footer: [
                AppButton(
                  label: 'Use this file',
                  onPressed: () => _go(FirstRunStep.done),
                ),
              ],
            ),
            FirstRunStep.done => _Done(
              text: _choice == _FileChoice.newFile
                  ? '${_fileName.text.trim()} is now in ${_repo.text.trim()}. '
                        'Add your first entry with the + button.'
                  : 'Loaded ${RepoFile.sample[_file].entries} entries from '
                        '${RepoFile.sample[_file].path}.',
              onOpen: _finish,
            ),
          },
        ),
      ),
    );
  }
}

/// F1: the mark in the middle, the name near the bottom.
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Center(child: LibriLogo(width: 168)),
        Positioned(
          left: 0,
          right: 0,
          bottom: 56,
          child: Text(
            appName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ],
    );
  }
}

/// F2.
class _Welcome extends StatelessWidget {
  const _Welcome({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = LibraryColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const LibriLogo(width: 134),
                const SizedBox(height: 32),
                Text(
                  'Welcome to $appName',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge!.copyWith(height: 1.1),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    'Keep track of your movies, shows, books, games, music '
                    'and anime, and plan what to enjoy next.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontSize: 16,
                      color: colors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(label: 'Get started', onPressed: onStart),
              const SizedBox(height: 10),
              Text(
                'Your library is saved in a GitHub repo you own.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall!.copyWith(
                  fontSize: 13,
                  fontStyle: FontStyle.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// F3 to F6: a back arrow with the step label, a title and a line under
/// it, the step's content, and the buttons pinned to the bottom.
class _StepPage extends StatelessWidget {
  const _StepPage({
    required this.label,
    required this.onBack,
    required this.title,
    required this.body,
    required this.content,
    required this.footer,
    this.bodyHighlight,
    this.contentTopPadding = 24,
  });

  /// "Step 1 of 3"; null when the step stands alone (Replace token).
  final String? label;
  final VoidCallback onBack;
  final String title;
  final String body;

  /// A part of [body] set in the main text color, e.g. the repo name.
  final String? bodyHighlight;
  final List<Widget> content;
  final List<Widget> footer;
  final double contentTopPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = LibraryColors.of(context);
    final bodyStyle = theme.textTheme.bodyMedium!.copyWith(color: colors.muted);
    final highlight = bodyHighlight;
    final split = highlight == null || highlight.isEmpty
        ? -1
        : body.indexOf(highlight);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 24, 20, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                tooltip: 'Back',
                color: theme.colorScheme.onSurface,
                icon: const StrokeIcon(AppIcons.back, size: 22),
              ),
              if (label != null) ...[
                const SizedBox(width: 4),
                Text(
                  label!.toUpperCase(),
                  style: theme.textTheme.labelSmall!.copyWith(
                    letterSpacing: 0.78,
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            children: [
              Text(
                title,
                style: theme.textTheme.headlineMedium!.copyWith(height: 1.1),
              ),
              const SizedBox(height: 8),
              split < 0
                  ? Text(body, style: bodyStyle)
                  : Text.rich(
                      TextSpan(
                        style: bodyStyle,
                        children: [
                          TextSpan(text: body.substring(0, split)),
                          TextSpan(
                            text: highlight,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: body.substring(split + highlight!.length),
                          ),
                        ],
                      ),
                    ),
              SizedBox(height: contentTopPadding),
              ...content,
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: footer,
          ),
        ),
      ],
    );
  }
}

/// Muted help under a field.
class _Help extends StatelessWidget {
  const _Help(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall!
          .copyWith(fontSize: 13.5, fontStyle: FontStyle.normal, height: 1.4),
    );
  }
}

/// The JSON that F5 adds to the repo.
class _CodeBlock extends StatelessWidget {
  const _CodeBlock(this.code);

  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = LibraryColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
      ),
      child: Text(
        code,
        style: theme.textTheme.bodyMedium!.copyWith(
          fontFamily: AppFonts.code,
          fontSize: 13,
          height: 1.55,
        ),
      ),
    );
  }
}

/// F4: one of the two ways to get a library file.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
  });

  final StrokeIconData icon;
  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = LibraryColors.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(
        color: selected ? theme.colorScheme.primary : colors.surfaceHigh,
        width: 2,
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: theme.colorScheme.surface,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.selectedFill,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: StrokeIcon(
                      icon,
                      size: 22,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontSize: 16.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontSize: 14,
                          fontStyle: FontStyle.normal,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: RadioMark(selected: selected),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// F6: a JSON file in the repo. A file that is not a library is dimmed
/// and cannot be picked.
class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.file,
    required this.selected,
    required this.onTap,
  });

  final RepoFile file;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = LibraryColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: file.usable ? 1 : 0.5,
          child: Container(
            constraints: const BoxConstraints(minHeight: 68),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.path,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        file.info,
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                RadioMark(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// F7.
class _Done extends StatelessWidget {
  const _Done({required this.text, required this.onOpen});

  final String text;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = LibraryColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: StrokeIcon(
                      AppIcons.checkBold,
                      size: 40,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'You\'re all set',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium!.copyWith(height: 1.1),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontSize: 16,
                      color: colors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: AppButton(label: 'Open $appName', onPressed: onOpen),
        ),
      ],
    );
  }
}
