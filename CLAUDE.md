# Library app

Phone-first Flutter app (Android, Samsung Galaxy S25; a Linux desktop build may come later) that is the front end for my personal media library: movies, shows, books, games, music and anime. The data lives in a separate private GitHub repo, `ekmanch/library`, as `library.json`.

## Read these first

- `docs/DESIGN.md`: every settled product and design decision, the screen list, the data format and the sync rules. This is the source of truth. If code and DESIGN.md disagree, ask me.
- `design/canvas.html`: the exported design canvas with all mockups. Screen IDs such as A14 or D12 in DESIGN.md and TODO.md refer to artboards in this file.
- `TODO.md`: the build order. Work through it top to bottom unless I say otherwise.
- `lib/theme/app_theme.dart`: colors, fonts and the theme extension. Never hard-code a color or font in a widget; add it to the theme instead.

## Git rules

- **Never commit, amend, push, tag or create a branch unless I explicitly ask for it in that message.** Finishing a task is not a request to commit. A general instruction earlier in the conversation is not one either.
- When a task is done, end your reply with a **suggested commit message** in a code block so I can use it myself.
- Commit message style: short imperative subject, no trailing period, e.g. `Add artist list with alphabet rail`. One logical change per commit. Add a body only when the why is not obvious.
- Never touch the `ekmanch/library` data repo from this project except through the app's own sync code, and never during development unless I ask. Use the fixture file for testing.

## Working rules

- Tick off items in `TODO.md` as they are completed. Add new items there when you find missing work, instead of doing unplanned work silently.
- Phase 1 is UI only, on fixture data. Do not add networking, GitHub access or file writing before the phase that calls for it.
- Ask before adding a package. Say what it is for and what the alternative is.
- Ask before changing anything that DESIGN.md marks as settled. Proposals are welcome; silent changes are not.
- UI text uses American spelling ("color", "favorite") and sentence case.
- Run the formatter, the analyzer and the tests before saying a task is done, and tell me if any of them fail:

```bash
dart format .
```

```bash
flutter analyze
```

```bash
flutter test
```

## Code conventions

- State management: Riverpod. Navigation: Flutter's built-in Navigator; no routing package unless I ask.
- Feature-first folders: `lib/features/<feature>/` with widgets and state together; shared widgets in `lib/widgets/`; models in `lib/data/models/`.
- All reading and writing of the library goes through one `LibraryRepository` interface. Phase 1 uses a fixture implementation; the GitHub implementation comes later. Widgets never know which one they have.
- Models are immutable. Every change to the library is expressed as a small operation ("set status", "add entry", "rate track") so it can be re-applied after a sync conflict.
- Display preferences (theme, accent, view per type, sort) are stored on the device, never in `library.json`.
- Touch targets are at least 44 px. Every icon-only button has a tooltip or semantic label.
- Write widget tests for anything with logic (filtering, sorting, similar-tag check, replace dialogs) and unit tests for the models and operations.
