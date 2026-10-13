# Libri: settled design

Everything here was decided during the design phase. Screen IDs refer to artboards in `design/canvas.html`. Items under "Open" in section 10 are not decided yet.

## 1. What the app is

- A phone-first Flutter app for Android (Samsung Galaxy S25). A Linux desktop build may follow.
- Front end for the private repo `ekmanch/library`. `library.json` in that repo is the source of truth.
- The app adds, edits and deletes entries from day one, and writes the changes back to the repo.
- Six types: Movies, Shows, Books, Games, Music, Anime. The word in the UI is "Type".

## 2. Words and rules used everywhere

| Thing | Decision |
|---|---|
| Statuses | Want, In progress, Done, DNF. Movies and music have no In progress: a movie or an album is watched or heard in one sitting, so it goes straight from Want to Done. Music has no DNF either: a song is minutes long, so "did not finish" only makes sense for long-form media. Movies keep DNF. Shows, books, games and anime have all four. |
| Rating | 1 to 10, optional, picked in a sheet (D11), never a slider |
| Favorite | The `#favorite` tag stays, alongside the rating |
| Row content | Title plus an italic subtitle. Subtitle is the year; for books and music it is creator and year; for a song it is album and year. No tags in rows. |
| Not released yet | Subtitle reads "Not released yet" |
| Note vs About | Note is my own text. About is the description fetched from a lookup. |
| Delete | Lives in the details sheet. Every destructive button (Delete, Delete plan, Delete everywhere, Disconnect, Replace…) has no fill, the grey button outline and red text; never a red fill, never next to an accent button. |
| Spelling | American, sentence case |
| Type order | Wherever entries are grouped by type (home, filtered results, plan checklists, the pool), the groups follow the global order: Movies, Shows, Books, Games, Music, Anime. An artboard showing another order is incidental. The timeline groups by time instead and uses this order inside each bucket. |

## 3. Navigation

- Floating pill at the bottom with two destinations: **Library** and **Plans**. A round "+" button sits to its right.
- Settings is reached with a gear icon on top-level screens.
- Inside a plan, "⋮" opens the plan menu (D3).
- No tinted header bars.
- Each tab keeps its own stack. A shortcut to something another tab owns switches to that tab with that tab's overview underneath, so back lands there: "Active plan" on the home opens the plan on Plans. Shared detail views (entry details, an artist, an album) stay in the tab they were opened from: an entry opened from a plan stays in Plans, one opened from the library stays in Library. Full-screen forms, search and Settings open above both tabs.

## 4. Screens

### Library (A row)

| ID | Screen | Notes |
|---|---|---|
| A1 | Library home | Type chips; active plan card; two entries per type under a heading that shows the type's count. Rows are ordered In progress, then Want (newest added), then Done, then DNF. Tapping a heading or a chip picks that type, and the home becomes the type's list in place (A4) with no separate screen: status segments, count, sort and view replace the plan card and the headings, and the search hint becomes "Search movies". Picking a type resets the status segment to All. The active plan is the first plan with items that are not all done; finished plans live on S5. Seasonal-only entries are hidden from the home, the type lists and filtered results unless the switch in A2 is on; search still finds them. |
| A2 | Filter sheet | Type, Status, Kind, Released, Tags. Within Type, Status, Kind and Released any choice matches; all selected tags must match. Tags are in collapsible groups by category, only the groups the chosen types use (section 7). Released is a scrolling row built from the library: one chip per decade, labeled with the full decade ("1980s", not "80s"), from the earliest to the latest decade that has an entry, gaps filled in so the row never jumps, plus Older when anything is from before 1960. A new decade appears as soon as an entry from it exists. Has an "Include seasonal-only" switch; when on it counts as one active filter and shows as a removable chip. The Status chips follow the chosen types: In progress only shows when a chosen type can have it (or no type is chosen), and a status the chosen types cannot have is dropped. Kind (Albums, Songs) shows under Status only while Music is chosen, narrows music entries only, and is dropped when Music is unticked. The sheet and the home stay in sync (A3, A11, A23, A24): anything the home's chips can show is not a results screen, anything more opens results (L5, L6). A filter with exactly one type keeps that type picked underneath, so removing the extra filters lands on that type's view; a filter with no type or several types puts the home on All. "Clear all", "Clear filters" and the sheet's Reset clear the type, the status segment and the music tab too. |
| A3 | Filter opened from a type view | The sheet starts with what the home shows: the picked type and its status segment (Movies + Done), or Music and the music tab's kind (Albums or Songs). Music on Artists starts with Music only, since Artists is a way of browsing, not a filter. On All it starts with nothing chosen. |
| A4 | Type picked, text view | The home with a type chip picked: status segments, count, sort link, view button. A status with nothing in it shows one line, "Nothing marked want yet." |
| A5 | Search | |
| A6 | Entry details sheet | Cover spot, status, rating row, Note, About, tags, plans, Edit, Delete |
| A7 | Add to plan | |
| A8 | Add / edit entry | Rating row opens D11. Tag picker is the only place tags are created. |
| A9 | Delete confirmation | |
| A10 | Empty states | |
| A11 | Filter result: one type and one status is the type view | One type with at most one status, and nothing else, shows that type's view with the status segment picked, and the sheet's button reads "Show 5 movies". Music has no status segment, so music with a status opens results. |
| A12 | Sync and errors | |
| A13 | New entry: pick a match | A new entry starts here, then opens A8 prefilled. "Fill in the details myself" skips the lookup. |
| A14 | Music by artist, text view | See section 5 |
| A15 | One artist, text view | |
| A16 | View menu | Text, List with covers, Grid with covers for media types and music albums; Text, List with photos, Grid with photos for music artists and songs. The screen behind is dimmed; the chosen view is highlighted and checked. |
| A17 | Music, list with photos | |
| A18 | Music, grid | |
| A19 | One artist, with photos | |
| A20 | Type picked, list with covers | |
| A21 | Type picked, grid with covers | Title on up to two lines, then the year only, never the status ("Not released yet" without a year); music grids show the artist instead. The check badge on the cover's upper-right corner means Done. L4 follows the same rule. |
| A22 | Album details with track ratings | See section 5 |
| A23 | Filter result: Music + Songs is the Music view | For music the kind plays the status segment's part: Music + Songs opens the Music view on Songs ("Show 3 songs"), and Music alone opens it on Artists ("Show 12 music entries"). Music with both kinds, or with a status, opens results. |
| A24 | Filter result: Music + Albums is the Music view | Same as A23, on Albums ("Show 9 albums"). |
| L1, L2, L3 | Long list with a jump rail | The rail shows when both hold: the list is at least three screens tall, and it has two sections or more. Then the text and list views get section headers and a rail on the right that jumps to a section. Sections follow the sort: decades for the year orders (Older before 1960, "Not released yet" last for entries without a date), months of the current year and then whole years for newest added, first letters for title order with "#" for digits, letters for music artists (1d). The highlighted rail label follows the scroll position. A short list has neither headers nor rail. |
| L4 | Long grid with fast scroll | Same rule. The grid keeps no headers; a thumb on the right appears while scrolling and can be dragged, and a bubble next to it names the section at the top of the screen. |
| L5 | Filtered results, one type | Removable chips and the count stay put; the rows scroll, grouped by type. Same rule. When every result is of one type, sections follow the sort, headers in that type's color, rail of short labels. |
| L6 | Filtered results, several types | Same rule. One section per type in type order, headers in the type colors, and the rail shows one colored dot per type instead of labels; the current dot is a little larger. A short result list keeps its type headings and no rail. |

### Plans (S row)

A plan is a named list of entries, for example "Halloween 2026". Plans replace the old "seasonal" files and are not tied to seasons.

| ID | Screen | Notes |
|---|---|---|
| S1 | Plan checklist | Grouped by type, in the global type order. Spacing in the mockup is trimmed; use normal row spacing. |
| S2 | Timeline view | Groups by time, not by type: Earlier, Last week, This week, each future single day ("Sat Oct 17"), Later, and Whenever for undated items. Every bucket mixes types, in the global type order inside. Titles wrap to two lines before cutting off. A rail on the left fills up to today. No highlight on the last item. |
| S4 | All entries matching the plan's tags | Add, edit, remove. Keeps the plan header's progress row. |
| S5 | Plans overview | Active plans as cards, then Not started and Finished as rows (see the plan states below). |
| S6 | Settings | Theme, accent color, timeline default, seasonal theme default; an About row with the app name and version |
| S7 | Entry details in a plan, timeline on | Has a "When" row (D2) and a plan note |
| S8 | Entry details in a plan, timeline off | No "When" row |
| S9 | Edit plan | A Started switch under Name and Year (see the plan states below). |
| S10 | New plan | Can copy an existing plan to a new year |
| S11 | Halloween theme | |
| S12 | Christmas theme | |

Plan rules:

- A plan has a name, an optional year, linked tags (multi-select from existing tags; an entry matches if it has any of them), a Timeline switch and a Seasonal theme switch. Both switches default to the values in Settings.
- Plan states, from the S9 note: Not started, Active, Finished.
  - Active: the Started switch is on, or the plan's first date has come. When the first date arrives the app turns Started on, so the switch always shows the real state. A plan never goes inactive on its own after its end date.
  - Finished, automatically: the plan has at least one entry and every entry is done or removed from the plan. An empty plan is never Finished. Finishing shows a short "Halloween 2026 finished" message with Undo, which unticks the last item.
  - Ticking an item also turns Started on, so unticking an entry or adding a new one to a Finished plan makes it Active again.
  - Removing an entry from a plan never removes it from the library. There is no separate close action.
  - The Started help text: on, "Active. Stays active after its end date until every entry is done or removed."; off, "Not started. Turns on by itself when the plan's first date comes."
- The plan header is the same on the checklist, the timeline and the "All <plan>" tab (S11 to S14): row 1 is the name (one line, 32, 28 then 24 px, then an ellipsis) and the ⋮ menu; row 2 is the year chip, the progress bar and "X of Y done". The year chip is never next to the title, and its menu opens right below it.
- "When" on a plan item is empty, a single day, or a period.
- Rewatch or re-read is detected automatically: an entry that is already Done when it is added to a plan is a repeat. Its row says Rewatch for movies, shows and anime, Reread for books, Replay for games and Relisten for music.
- Removing an entry from a plan offers "Remove from this plan" or "Delete everywhere" (D4).
- Seasonal theme: an illustrated 88 px strip at the top, an icon by the title, a themed progress marker and a seasonal accent color. Only inside that plan.

### Dialogs and small screens (D row)

| ID | Screen |
|---|---|
| D1 | Sort menu |
| D2 | When: a day or a period |
| D3 | Plan menu |
| D4 | Remove from plan, or everywhere |
| D5 | Delete plan |
| D6 | Settings: library connection |
| D7 | First load |
| D8 | Library home, light theme |
| D9 | New tag: a similar one exists |
| D10 | New tag: confirm and pick a category |
| D11 | Rating picker |
| D12 | Saving an album when songs from it are saved |
| D13 | Saving a song when its album is saved |

### First run (F row)

Greeting screens, to be built later in phase 1 (see TODO.md). The canvas has F1 Splash, F2 Welcome to Libri, F3 Connect GitHub, F4 Your library file: new or existing, F5 Create a new library, F6 Pick an existing file, F7 All set. They replace the old first-time setup artboard.

## 5. Music

- Music is tracked at album level. A single song can also be an entry (`kind: "song"`).
- **A14** has three tabs: Artists (default), Albums, Songs. Albums and Songs are flat lists.
- Every artist with at least one album or song appears in the same list. The row says what is saved: "7 albums", "2 albums, 3 songs", "1 song".
- Sorting ignores a leading "The" but displays the full name. Names starting with a digit go under "#".
- "Various Artists" (today's "Compilations") is pinned at the very end, after Z.
- An alphabet rail on the right jumps to a letter, under the same rule as every long list (L1 to L6: three screens tall, two sections or more). The text and list views get letter headers; the grid has none and uses the fast-scroll thumb with its letter bubble instead.
- **One artist** shows an Albums section, then a Songs section.
- **A song entry** has an optional `album` text field, normally filled in by the lookup, shown as its subtitle ("Bad Music for Bad People · 1981").

### Track ratings (A22)

- Opening an album writes nothing. The track list is fetched from the lookup and cached on the device.
- Rating a track adds it to the album entry's `tracks` list. Clearing the rating removes it. Only rated tracks are stored.
- A rated track is not a song entry. It has a title, a lookup ID and a rating, nothing else.
- The Songs tab lists song entries and rated tracks together, both with the subtitle "Artist · Year": the year the song, or the album it is on, came out. Tapping a rated track opens its album. Plan rows, which also mix artists, use the same "Artist · Year" for songs. On an artist's own screen a song keeps "Album · Year".
- Offline with no cached track list: show the rated tracks and a line saying the full list needs a connection.

### Replace dialogs

- **D12**, saving an album when song entries from it exist: Keep both / Replace songs with album / Cancel. Replacing moves the songs' ratings into the album's `tracks`.
- **D13**, saving a song when its album exists: Keep both / Replace album with this song / Cancel. The dialog says what would be lost.
- A match needs the same artist and the same album (by lookup ID when available, otherwise by title). No album info on the song means no dialog. Nothing is ever merged without asking.

## 6. Views and covers

- Each list can be shown as Text, List with photos, or Grid. The view button sits next to sort/search and opens the menu in A16.
- The choice is remembered per type, and for music per tab. It is stored on the device.
- Artist photos are round. Covers are poster-shaped for movies, shows, books and anime, and square for albums. The games shape is open.
- With the text view chosen, detail screens stay text-only (A15). With a photo view chosen, they show images (A19).
- Long lists (three screens or more, two sections or more) get section headers and a jump rail, or a fast-scroll thumb in the grid; see L1 to L6.

## 7. Tags

- Tags belong to categories, in this order: Genres (movies, shows, books and anime), Game genres, Music genres, Mood (all types), Season, Creators, Animation style, Other. Every tag belongs to one category, picked when it is created (D10). A new tag starts on Game genres for a game, Music genres for music and Genres otherwise.
- Filter sheet (A2): a category group shows only when at least one of its tags is used by an entry of the chosen types. This comes from the library, not a fixed mapping, so Games shows Genres too once a game is tagged #crime. With no type chosen, every group shows. A chosen tag whose group goes away is dropped.
- Tag picker (D14): Game genres only for games and Music genres only for music, unless you search; a search finds any tag. Plan hashtags (S9, S10) list every category.
- A new tag can only be created from the entry form's tag picker, so every tag is used by at least one entry. A tag that no entry uses disappears.
- Before creating a tag, check for similar existing ones: same when hyphens are ignored; one letter different (two for tags of six letters or more); two neighboring letters swapped; singular versus plural. If one is found, show D9.
- Creating a tag always goes through D10 to confirm it and pick its category.

## 8. Data: `library.json` version 2

```json
{
  "version": 2,
  "tags": { "Genres": ["horror", "scifi"], "Mood": ["lighthearted"] },
  "entries": [
    {
      "id": "movies/the-mummy-1999",
      "type": "movies",
      "title": "The Mummy",
      "released": "1999",
      "creator": "Stephen Sommers",
      "status": "done",
      "rating": 9,
      "tags": ["adventure", "lighthearted", "halloween"],
      "note": "",
      "description": "",
      "seasonal_only": false,
      "added": "2026-10-01"
    }
  ],
  "plans": [
    {
      "id": "halloween-2026",
      "name": "Halloween",
      "year": 2026,
      "tags": ["halloween"],
      "timeline": true,
      "seasonal_theme": true,
      "started": true,
      "items": [
        { "entry": "movies/the-mummy-1999", "done": false, "repeat": true, "note": "", "when": { "from": "2026-10-19", "to": "2026-10-31" } }
      ]
    }
  ]
}
```

Field rules:

- `id`: `<type>/<title>-<year>` for every type but music (`movies/the-mummy-1999`, `books/dracula-1897`), `music/<title>-<artist>` for music (`music/dirt-alice-in-chains`). One scheme for the app and the data: the phase 3 migration assigned every existing id with the app's `EntryId.generate`, so nothing in `ekmanch/library` follows an older rule.
- `type`: `movies`, `shows`, `books`, `games`, `music`, `anime`.
- `released` is text with flexible precision: `"1999"`, `"2026-12"` or `"2026-12-25"`. There is no separate `year`; the app derives the year and whether the title is out yet.
- `creator` is one field; the app labels it Director, Author, Artist and so on by type.
- `status`: `want`, `in_progress`, `done`, `dnf`.
- `rating`: 1 to 10 or `null`.
- `seasonal_only`: true for titles only wanted in season; hidden from the main lists unless "Include seasonal-only" is on.
- `started` on a plan: the Started switch (S9). Always written, `false` by default; set by the user or by the app when the plan's first date arrives, and never cleared by the app.
- `platform` (games) uses spelled-out names, one spelling per platform: "PlayStation 5", not "PS5" (see `lib/data/models/platform_names.dart`).
- `when` on a plan item: `null`, or `from` and `to` (equal for a single day).
- Type-specific fields: `platform` (games), `formats` (books: `audiobook`, `physical`), and for music `kind` (`album` or `song`), `album` (songs, optional), `tracks` (albums, optional: `[{ "title", "id", "rating" }]`).
- Lookup IDs for entries (to re-fetch covers and track lists) can be added as a `source` field when lookups are built.

Not in the file: covers, track lists, view choices, theme, sort order. Those are caches or device preferences.

Rules settled during phase 0:

- A partial `released` counts as released only after its period ends: `"2026-12-25"` on that day, `"2026-12"` from 2027-01-01, `"2027"` from 2028-01-01. A game "coming in 2027" stays "Not released yet" all year. No `released` at all counts as released.
- The file is written in one canonical form so that a save is a minimal git diff: two-space indent, one trailing newline, keys in the order of the sample above, entries and plans never reordered by an edit. Common entry fields are always written, including `"rating": null`; the type-specific fields are omitted when absent. Decoding and re-encoding a canonical file gives back the same bytes.
- Entry ids are slugs frozen at creation: lowercase, apostrophes dropped (`salems-lot`, not `salem-s-lot`), diacritics folded to ASCII, runs of other characters become one hyphen; `<type>/<title>-<year>` for every type but music (books too, never the author), or `music/<title>-<artist>`. A collision gets `-2`, `-3`, for every type (`EntryId.generate`, covered by `test/data/models/entry_id_test.dart`). Editing a title never changes the id, so plan items keep pointing at the right entry.
- A tag disappears from `tags` only when no entry **and no plan** uses it, so a new plan tagged `halloween` keeps the tag alive before any entry has it.

Migration from version 1 (`catalog.<type>` plus `seasonal.<season>.<type>.{plans, coming_later, favorites}`; 659 entries, 425 of them music):

- `dropped` becomes `dnf`; `year` becomes `released`.
- Seasonal favorites merge into the entries.
- Plan and "Coming later" rows become `want` entries tagged with their season, plus plan items.
- The artist "Compilations" becomes "Various Artists".
- The Markdown files and PDFs become output generated from the JSON.

## 9. Sync with GitHub

- Show cached data immediately, then check for changes.
- Check on open and resume, on pull-to-refresh, on tab switch if more than 5 minutes have passed, and always right before saving.
- Use conditional requests so an unchanged file costs almost nothing. Always request the raw format, which supports files up to 100 MB.
- The UI updates at once; saving happens in the background.
- Edits made within 2 to 3 seconds are bundled into one commit with a readable message, such as "Mark The Mummy as done".
- On a conflict, fetch the new file and re-apply the pending operations. Operations are small ("set status of X"), so this is safe.
- Offline edits are queued and sent when the connection returns.
- All storage goes through one interface, so the file can later be split per type without touching the UI.

## 10. Lookups and images

| Type | Source |
|---|---|
| Movies, shows | TMDB |
| Anime | AniList |
| Books | Google Books or Open Library |
| Games | Steam, then IGDB or Wikipedia |
| Music details | Open: MusicBrainz, Deezer or Spotify |
| Artist photos | Open: Spotify or Deezer (check the terms), TheAudioDB or fanart.tv as alternatives |

No scraping. Goodreads has no public API any more. Images are cached on the device.

### Open

- Which music source to use for albums, tracks and artist photos.
- Cover shape for games.
- Whether rated tracks need notes (currently: no, make it a song entry instead).
- Not drawn yet: the "Include seasonal-only" switch in A2, the `seasonal_only` switch in A8, the "Rewatch" label on plan rows, the Album / Song switch in A8.

## 10a. Decisions made while building

- Section headers are uppercase, except decades ("1990s", not "1990S").
- A plan header gives the name priority: it shrinks a little to fit on one line, then truncates with "…"; the year chip sits by the progress bar.
- Every search box is the shared `SearchField`: a magnifying glass on the left, one outline (the accent while typing, the field outline at rest), the text inside it, no border on the inner field. That includes the tag searches in A2, D14 and S9.
- Ticking a plan item marks the entry Done and remembers the old status; unticking restores it unless the status changed in between or was Done already.
- Platform chips in the entry form are only the platforms the game came out on (fetched) plus the entry's own; "Other…" adds anything else. Aliases merge into one spelled-out name.
- A sheet is at most 88% of the screen tall, the tag picker 78%, so the screen behind stays in view.
- Segmented controls that do not fit at a large text size keep their full labels and scroll sideways; the filter sheet's status chips share the row by label length and wrap when they do not fit.
- A filter that is only one type, with at most one status (for music, at most one kind), is not a results screen: the home picks that type and its status segment or music tab instead (the L6 note; see A2, A11, A23).
- A filter that matches nothing spells itself out: "No books are both in progress and tagged #christmas. Remove a filter to see more." The empty state's button clears the filters, so the chip row has no "Clear all" then.
- The active plan card's name shrinks a step (20, 18, 16 px) before cutting off, like the plan header.
- At a large text size on a small phone, a timeline card puts its type label above the title so the title gets the full width, and the entry form stacks the creator and Released fields so neither is cut.
- D6: "Check for changes" is a two-line row: the label, then "When you open Libri, then every 5 minutes" in the secondary color, left-aligned.
- D2: the range band is drawn per week row from the center of the start day to the center of the end day (to the row edge where the range carries on), 40 px tall, square ends hidden under the dots; no band for a single day.
- The "+" button changes with the screen: on a plan it opens the pool or adds a tagged entry, and wears the plan's seasonal accent.
- Desktop builds use the same visual density as the phone, so Linux captures match the device.
- Settings (S6) also has the default game platform from the canvas (PC, PlayStation 5, Xbox Series X|S, Switch 2, Steam Deck, None). A new game from a lookup starts with it picked when the game came out on it, as the A8 note says.
- The A12 banner sits under the title on both top-level screens, Library and Plans, so a failed save is seen wherever you are.
- Until phase 4, Disconnect in D6 goes straight back to the splash (F1); a confirmation comes with the real token handling.
- "Replace token" in D6 opens the Connect GitHub step (F3) on its own, with a Save token button and no step label.
- Phase 2 keeps the library in `library.json` and the display preferences in `preferences.json`, both in a `libri` folder in the app documents directory (never the cache), each written atomically. A new install starts from the bundled fixture until phase 4 connects GitHub. An unreadable library file is renamed aside with an `.unreadable` suffix, never overwritten. Preferences sit behind their own `PreferencesStore`, separate from `LibraryRepository`, and are never synced.
- Every operation has a one-line summary in the imperative ("Mark The Mummy as done", "Tick The Mummy in Halloween 2026"), for the commit messages of phase 4.
- The About version comes from `lib/app_info.dart`, kept equal to pubspec.yaml by a test, until a package reads it from the build.
- Phase 3 (the data repo): `library.json` v2 is the source of truth there; `scripts/generate.sh` writes the Markdown lists and tag pages from it, and the GitHub Action commits the regenerated lists after a save from the app. Migrated entries have `rating: null` (favorites keep the `#favorite` tag), `creator: null` outside books and music, `added` from the first commit that listed the title, and plan items keep the old table notes. A wanted entry tagged with a season shows under "Coming later" in that season's list only while its release is ahead; a year-only release counts as out in its own year.

## 11. Visual design

Exact values are in `lib/theme/app_theme.dart`.

- Dark graphite theme by default; a light theme with a white background and soft shadows for cards.
- Fonts: Bricolage Grotesque for titles, Figtree for everything else.
- One accent color chosen by the user in Settings, from a Vivid group and a Pastel group. Default: Hot pink. On the light theme a darker "ink" version of the accent is used for accent text, icons and outlines; every ink reaches 4.5:1 on white (the S6 list). Fills stay the same on both themes.
- Each type has its own color per theme, used for section headings, chip dots, rail dots and labels. The light colors reach 4.5:1 on white, except Movies (3.8:1, kept on purpose so gold stays gold). Values are in the theme file and the D8 note.
- Seasonal accents: Halloween orange, Christmas green, only inside a themed plan.
- Phone frame in the mockups is 390 × 844. The target phone, the Galaxy S25 (1080 × 2340 at 480 dpi), is 360 × 780 dp, and the Linux dev window and the captures use that size. Side padding is 20 px. Touch targets are at least 48 dp: bottom navigation items and segments are 48 dp tall and every segment at least 48 dp wide; 40 dp chips keep their drawn size but get a 48 dp touch area.
