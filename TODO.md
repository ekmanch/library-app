# TODO

Build order for Libri. Screen IDs (A1, S5, D12 …) refer to artboards in `design/canvas.html`; decisions are in `docs/DESIGN.md`.

Phase 1 builds the whole UI on fixture data, with nothing saved and no network. Functionality is wired up from phase 2.

## Phase 0: Project setup

- [x] Create the Flutter project (Android first; Linux desktop as a dev and test target only)
- [x] Add `lib/theme/app_theme.dart`, the fonts (Bricolage Grotesque, Figtree) and check that it compiles
- [x] Add Riverpod
- [x] Define the models from DESIGN.md section 8 (Entry, Track, Plan, PlanItem, tag categories) with freezed, plus the canonical JSON codec
- [x] Define the `LibraryRepository` interface and the starter set of operations
- [x] Create `assets/fixtures/library.json` in the v2 format with realistic data for all six types, a Halloween and a Christmas plan, and music with albums, songs and rated tracks
- [x] `FixtureLibraryRepository`: loads the fixture, keeps changes in memory only
- [x] Set up `integration_test` with a smoke test and run it on Linux

## Phase 1: UI on fixture data

### 1a. Shell and shared pieces
- [x] App shell: floating pill navigation (Library, Plans) and round "+" button
- [x] Shared widgets: entry row (title, italic subtitle, status mark), section heading in type color, status segmented control, tag chip, bottom sheet frame, dialog frame, buttons (primary, outline, neutral, destructive = neutral fill with red text)
- [x] Theme switching (dark, light) and accent switching, live (state only; the Settings UI is 1f)

### 1b. Library
- [x] A1 Library home: type chips, active plan card, two entries per type under headings with counts
- [x] A4 Type picked: the home becomes the type's list in place, with status segments, count, sort, view button
- [x] D1 Sort menu
- [x] A20, A21 List with covers and grid with covers (placeholder images)
- [x] View menu (as A16) and remembering the view per type
- [x] A2 Filter sheet: type, status, released, tags in collapsible groups, "Include seasonal-only" switch
- [x] A3 Filtered results with removable chips
- [x] A5 Search
- [x] A10 Empty states
- [x] L1, L2, L3 Long lists: section headers (decade, month added, letter) with a jump rail on the right in the text and list views, shown when the list is three screens tall or more and has two sections or more
- [x] L4 Long grid: draggable thumb with a label bubble instead of headers, same rule
- [x] L5, L6 Long filtered results: sections by sort for one type, by type with a dot rail for several

### 1c. Entry details and editing
- [x] A6 Entry details sheet: cover spot, status, rating row, note, about, tags, plans, edit, delete
- [x] D11 Rating picker
- [x] A13 New entry: pick a match (static fixture results)
- [x] A8 Add / edit entry form, including the tag picker
- [x] D9 Similar tag warning and D10 New tag: confirm and pick a category
- [x] A7 Add to plan
- [x] A9 Delete confirmation

### 1d. Music
- [x] A14 Artists list: Artists / Albums / Songs toggle, letter headers, alphabet rail, "Various Artists" pinned last, leading "The" ignored when sorting
- [x] A14 Music replaces the status segments and the sort link with the tab toggle and one count line ("17 artists, 13 albums, 5 songs"); the view choice is remembered per tab (added after the canvas revision)
- [x] A16 View menu (shared since 1b), A17 list with photos, A18 grid
- [x] A15 and A19 One artist: Albums and Songs sections, text and photo versions
- [x] Albums tab and Songs tab (flat lists); the Songs tab lists song entries and rated tracks together
- [x] A22 Album details with track ratings (static track lists for two fixture albums stand in for the lookup; other albums show only their rated tracks)
- [x] Album / Song switch in the entry form, with the optional album field for songs
- [x] D12 and D13 Replace dialogs

### 1e. Plans
- [x] S5 Plans overview
- [x] S1 Plan checklist, grouped by type
- [x] S2 Timeline view (left rail, fills to today)
- [x] S4 All entries for a plan's tags: add, edit, remove
- [x] S7 and S8 Entry details inside a plan (with and without "When")
- [x] D2 When picker: a day or a period
- [x] D3 Plan menu, S9 Edit plan, S10 New plan (including copy to a new year); then the "New plan" link at the end of A7
- [x] D4 Remove from plan or delete everywhere, D5 Delete plan
- [x] S11 and S12 Seasonal themes (Halloween, Christmas): strip, title icon, progress marker, seasonal accent
- [x] Year chip on the plan header: switch between plans with the same name, "New year…" copies the plan (added after the canvas revision)
- [x] "This plan / All #tag" tabs on the plan screen; S4 rows get Add / In year, and Edit entry, Remove #tag, Delete behind "⋮"; the "+" button changes with the tab (added after the canvas revision)
- [x] S10 "Start with: Empty / Copy a plan", S5 "Next up" on the active card, a plan note editor from S7 and S8 (added after the canvas revision)
- [x] Capture every screen, sheet and dialog built so far, also at the S25's 360 dp and at text scale 1.3; one shared search field for every search box

### 1f. Settings and states
- [x] S6 Settings: theme, accent color (Vivid and Pastel groups), timeline default, seasonal theme default, About row (name and version); also the default game platform from the canvas, used by A8
- [x] D6 Library connection (UI only)
- [x] F1 to F7 First run (UI only): splash, welcome, connect GitHub, new or existing library file, create, pick, all set (replaces A11)
- [x] A12 Sync and error banners, D7 First load (driven by fake states)
- [x] D8 Light theme pass over every screen (every screen is captured in light by `screenshots_test.dart`; a reviewer compared them and the banners, the inset status segments and the type-chip dots were fixed)

### 1g. Phase 1 wrap-up
- [ ] Screen sizes pass: every screen at 320, 360, 384 and 412 dp and at text scale 1.3; fixed widths that break become flowing layouts
- [ ] Walk through every artboard next to the app and list the differences
- [ ] The tag search boxes in the filter sheet (A2) and the tag picker (D14) are filled fields without the shared search outline; decide whether they should be the shared `SearchField`
- [ ] D6: the Disconnect outline is a step dimmer than Replace token in the mockup; the value column wraps on the 360 dp phone at text scale 1.3
- [x] Reconsider the "See all" link: it jumps to a different screen (A4) and that was not intuitive. A clearer label or a different affordance. (Resolved by the canvas revision of 2026-10-10: the type view is the home with a chip picked.)
- [ ] Accessibility pass: contrast, touch targets, screen reader labels, large font scale
- [ ] Widget tests for filtering, sorting, the similar-tag check and the replace dialogs

## Phase 2: Local data

- [ ] Persist the library to a local file through a `LocalLibraryRepository`, so changes survive a restart
- [ ] Operations layer: every change is a small named operation with a human-readable summary
- [ ] Store display preferences on the device
- [x] Rewatch detection: adding a Done entry to a plan marks the plan item as a repeat (done in A7, phase 1c)

## Phase 3: Migrating the data repo

Done in `ekmanch/library`, not in this repo. Each step needs my go-ahead.

- [ ] On a feature branch in `ekmanch/library`, reverse the pre-commit hook so JSON is the source and Markdown is generated from it
- [ ] Script that converts today's `library.json` (v1) to v2: flat entries, `dropped` becomes `dnf`, `year` becomes `released`, "Compilations" becomes "Various Artists", plan rows become `want` entries tagged with their season, seasonal favorites merge into entries
- [ ] The migration script writes the file in the app's canonical encoding (see DESIGN.md section 8), so the app's first save is not a full rewrite
- [ ] Check the id scheme for books, games, shows and anime against today's ids before migrating
- [ ] Generate the Markdown files and PDFs from the JSON (GitHub Action), instead of the other way around
- [ ] Verify nothing was lost: entry counts per type before and after

## Phase 4: GitHub sync

- [ ] F3 to F6 First run for real: token and repo, stored in secure storage
- [ ] `GitHubLibraryRepository`: read with a conditional request, always in raw format
- [ ] Show cached data first, then refresh on open, on resume, on pull-to-refresh, and on tab switch after 5 minutes
- [ ] Save: bundle edits for 2 to 3 seconds into one commit with a readable message ("Mark The Mummy as done")
- [ ] Conflicts: refetch and re-apply the pending operations
- [ ] Offline queue
- [ ] A12 banners driven by the real sync state; Retry re-sends, "Sync now" in D6 syncs
- [ ] F3 "How do I create a token?" opens GitHub's token page (needs url_launcher)
- [ ] Confirm before Disconnect in D6, since it clears the token
- [ ] Read the version for About from the build (package_info_plus) instead of `lib/app_info.dart`

## Phase 5: Lookups and images

- [ ] A13 Pick a match for real: TMDB (movies, shows), AniList (anime), Google Books or Open Library (books), Steam then IGDB (games), a music source for albums and tracks
- [ ] Fill in released, creator, description and album from the match
- [ ] Covers and artist photos, cached on the device
- [ ] Track lists for A22, cached on the device
- [ ] API keys kept out of the repo

## Later

- [ ] Linux desktop layout
- [ ] Split `library.json` per type if it grows too large
- [ ] General "Show cover images" data-saving option
