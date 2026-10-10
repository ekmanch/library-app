# TODO

Build order for the Library app. Screen IDs (A1, S5, D12 …) refer to artboards in `design/canvas.html`; decisions are in `docs/DESIGN.md`.

Phase 1 builds the whole UI on fixture data, with nothing saved and no network. Functionality is wired up from phase 2.

## Phase 0: Project setup

- [ ] Create the Flutter project (Android first; keep Linux desktop possible)
- [ ] Add `lib/theme/app_theme.dart`, the fonts (Bricolage Grotesque, Figtree) and check that it compiles
- [ ] Add Riverpod
- [ ] Define the models from DESIGN.md section 6 (Entry, Track, Plan, PlanItem, tag categories)
- [ ] Define the `LibraryRepository` interface
- [ ] Create `assets/fixtures/library.json` in the v2 format with realistic data for all six types, a Halloween and a Christmas plan, and music with albums, songs and rated tracks
- [ ] `FixtureLibraryRepository`: loads the fixture, keeps changes in memory only

## Phase 1: UI on fixture data

### 1a. Shell and shared pieces
- [ ] App shell: floating pill navigation (Library, Plans) and round "+" button
- [ ] Shared widgets: entry row (title, italic subtitle, status mark), section heading in type color, status segmented control, tag chip, bottom sheet frame, dialog frame, buttons (primary, outline, neutral, destructive = neutral fill with red text)
- [ ] Theme switching (dark, light) and accent switching, live

### 1b. Library
- [ ] A1 Library home: type chips, active plan card, two entries per type
- [ ] A4 See all, one type: status segments, count, sort, view button
- [ ] D1 Sort menu
- [ ] A20, A21 List with covers and grid with covers (placeholder images)
- [ ] View menu (as A16) and remembering the view per type
- [ ] A2 Filter sheet: type, status, released, tags in collapsible groups, "Include seasonal-only" switch
- [ ] A3 Filtered results with removable chips
- [ ] A5 Search
- [ ] A10 Empty states

### 1c. Entry details and editing
- [ ] A6 Entry details sheet: cover spot, status, rating row, note, about, tags, plans, edit, delete
- [ ] D11 Rating picker
- [ ] A13 New entry: pick a match (static fixture results)
- [ ] A8 Add / edit entry form, including the tag picker
- [ ] D9 Similar tag warning and D10 New tag: confirm and pick a category
- [ ] A7 Add to plan
- [ ] A9 Delete confirmation

### 1d. Music
- [ ] A14 Artists list: Artists / Albums / Songs toggle, letter headers, alphabet rail, "Various Artists" pinned last, leading "The" ignored when sorting
- [ ] A16 View menu, A17 list with photos, A18 grid
- [ ] A15 and A19 One artist: Albums and Songs sections, text and photo versions
- [ ] Albums tab and Songs tab (flat lists)
- [ ] A22 Album details with track ratings
- [ ] Album / Song switch in the entry form, with the optional album field for songs
- [ ] D12 and D13 Replace dialogs

### 1e. Plans
- [ ] S5 Plans overview
- [ ] S1 Plan checklist, grouped by type
- [ ] S2 Timeline view (left rail, fills to today)
- [ ] S4 All entries for a plan's tags: add, edit, remove
- [ ] S7 and S8 Entry details inside a plan (with and without "When")
- [ ] D2 When picker: a day or a period
- [ ] D3 Plan menu, S9 Edit plan, S10 New plan (including copy to a new year)
- [ ] D4 Remove from plan or delete everywhere, D5 Delete plan
- [ ] S11 and S12 Seasonal themes (Halloween, Christmas): strip, title icon, progress marker, seasonal accent

### 1f. Settings and states
- [ ] S6 Settings: theme, accent color (Vivid and Pastel groups), timeline default, seasonal theme default
- [ ] D6 Library connection (UI only)
- [ ] A11 First-time setup (UI only)
- [ ] A12 Sync and error banners, D7 First load (driven by fake states)
- [ ] D8 Light theme pass over every screen

### 1g. Phase 1 wrap-up
- [ ] Walk through every artboard next to the app and list the differences
- [ ] Accessibility pass: contrast, touch targets, screen reader labels, large font scale
- [ ] Widget tests for filtering, sorting, the similar-tag check and the replace dialogs

## Phase 2: Local data

- [ ] Persist the library to a local file through a `LocalLibraryRepository`, so changes survive a restart
- [ ] Operations layer: every change is a small named operation with a human-readable summary
- [ ] Store display preferences on the device
- [ ] Rewatch detection: adding a Done entry to a plan marks the plan item as a repeat

## Phase 3: Migrating the data repo

Done in `ekmanch/library`, not in this repo. Each step needs my go-ahead.

- [ ] Script that converts today's `library.json` (v1) to v2: flat entries, `dropped` becomes `dnf`, `year` becomes `released`, "Compilations" becomes "Various Artists", plan rows become `want` entries tagged with their season, seasonal favorites merge into entries
- [ ] Generate the Markdown files and PDFs from the JSON (GitHub Action), instead of the other way around
- [ ] Verify nothing was lost: entry counts per type before and after

## Phase 4: GitHub sync

- [ ] A11 First-time setup for real: token and repo, stored in secure storage
- [ ] `GitHubLibraryRepository`: read with a conditional request, always in raw format
- [ ] Show cached data first, then refresh on open, on resume, on pull-to-refresh, and on tab switch after 5 minutes
- [ ] Save: bundle edits for 2 to 3 seconds into one commit with a readable message ("Mark The Mummy as done")
- [ ] Conflicts: refetch and re-apply the pending operations
- [ ] Offline queue
- [ ] A12 banners driven by the real sync state

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
