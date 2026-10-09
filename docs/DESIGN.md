# Library app: settled design

Everything here was decided during the design phase. Screen IDs refer to artboards in `design/canvas.html`. Items under "Open" in section 10 are not decided yet.

## 1. What the app is

- A phone-first Flutter app for Android (Samsung Galaxy S25). A Linux desktop build may follow.
- Front end for the private repo `ekmanch/library`. `library.json` in that repo is the source of truth.
- The app adds, edits and deletes entries from day one, and writes the changes back to the repo.
- Six types: Movies, Shows, Books, Games, Music, Anime. The word in the UI is "Type".

## 2. Words and rules used everywhere

| Thing | Decision |
|---|---|
| Statuses | Want, In progress, Done, DNF |
| Rating | 1 to 10, optional, picked in a sheet (D11), never a slider |
| Favorite | The `#favorite` tag stays, alongside the rating |
| Row content | Title plus an italic subtitle. Subtitle is the year; for books and music it is creator and year; for a song it is album and year. No tags in rows. |
| Not released yet | Subtitle reads "Not released yet" |
| Note vs About | Note is my own text. About is the description fetched from a lookup. |
| Delete | Lives in the details sheet. Destructive buttons use a neutral fill with red text; never a red fill, never next to an accent button. |
| Spelling | American, sentence case |

## 3. Navigation

- Floating pill at the bottom with two destinations: **Library** and **Plans**. A round "+" button sits to its right.
- Settings is reached with a gear icon on top-level screens.
- Inside a plan, "⋮" opens the plan menu (D3).
- No tinted header bars.

## 4. Screens

### Library (A row)

| ID | Screen | Notes |
|---|---|---|
| A1 | Library home | Type chips; active plan card; two entries per type, ordered In progress, then Want (newest added), then Done |
| A2 | Filter sheet | Type, Status, Released, Tags. Within Type, Status and Released any choice matches; all selected tags must match. Tags are in collapsible groups by category. Has an "Include seasonal-only" switch (not drawn yet). |
| A3 | Filtered results | Removable chips for active filters |
| A4 | See all, one type | Status segments, count, sort link, view button |
| A5 | Search | |
| A6 | Entry details sheet | Cover spot, status, rating row, Note, About, tags, plans, Edit, Delete |
| A7 | Add to plan | |
| A8 | Add / edit entry | Rating row opens D11. Tag picker is the only place tags are created. |
| A9 | Delete confirmation | |
| A10 | Empty states | |
| A11 | First-time setup | Connect to the GitHub repo |
| A12 | Sync and errors | |
| A13 | New entry: pick a match | A new entry starts here, then opens A8 prefilled. "Fill in the details myself" skips the lookup. |
| A14 | Music by artist, text view | See section 5 |
| A15 | One artist, text view | |
| A16 | View menu | Text, List with photos, Grid |
| A17 | Music, list with photos | |
| A18 | Music, grid | |
| A19 | One artist, with photos | |
| A20 | See all, list with covers | |
| A21 | See all, grid with covers | Check badge on the cover means Done; other statuses are written under the title |
| A22 | Album details with track ratings | See section 5 |

### Plans (S row)

A plan is a named list of entries, for example "Halloween 2026". Plans replace the old "seasonal" files and are not tied to seasons.

| ID | Screen | Notes |
|---|---|---|
| S1 | Plan checklist | Grouped by type. Spacing in the mockup is trimmed; use normal row spacing. |
| S2 | Timeline view | Chronological, with a rail on the left that fills up to today. No highlight on the last item. |
| S4 | All entries matching the plan's tags | Add, edit, remove |
| S5 | Plans overview | |
| S6 | Settings | Theme, accent color, timeline default, seasonal theme default |
| S7 | Entry details in a plan, timeline on | Has a "When" row (D2) and a plan note |
| S8 | Entry details in a plan, timeline off | No "When" row |
| S9 | Edit plan | |
| S10 | New plan | Can copy an existing plan to a new year |
| S11 | Halloween theme | |
| S12 | Christmas theme | |

Plan rules:

- A plan has a name, an optional year, linked tags (multi-select from existing tags; an entry matches if it has any of them), a Timeline switch and a Seasonal theme switch. Both switches default to the values in Settings.
- "When" on a plan item is empty, a single day, or a period.
- Rewatch or re-read is detected automatically: an entry that is already Done when it is added to a plan is a repeat.
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

## 5. Music

- Music is tracked at album level. A single song can also be an entry (`kind: "song"`).
- **A14** has three tabs: Artists (default), Albums, Songs. Albums and Songs are flat lists.
- Every artist with at least one album or song appears in the same list. The row says what is saved: "7 albums", "2 albums, 3 songs", "1 song".
- Sorting ignores a leading "The" but displays the full name. Names starting with a digit go under "#".
- "Various Artists" (today's "Compilations") is pinned at the very end, after Z.
- An alphabet rail on the right jumps to a letter. It is present in all three views; the grid has no letter headers.
- **One artist** shows an Albums section, then a Songs section.
- **A song entry** has an optional `album` text field, normally filled in by the lookup, shown as its subtitle ("Bad Music for Bad People · 1981").

### Track ratings (A22)

- Opening an album writes nothing. The track list is fetched from the lookup and cached on the device.
- Rating a track adds it to the album entry's `tracks` list. Clearing the rating removes it. Only rated tracks are stored.
- A rated track is not a song entry. It has a title, a lookup ID and a rating, nothing else.
- The Songs tab lists song entries and rated tracks together.
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

## 7. Tags

- Tags belong to categories: Genre, Animation style, Game genre, Mood, Season, Creators, Other.
- A new tag can only be created from the entry form's tag picker, so every tag is used by at least one entry. A tag that no entry uses disappears.
- Before creating a tag, check for similar existing ones: same when hyphens are ignored; one letter different (two for tags of six letters or more); two neighboring letters swapped; singular versus plural. If one is found, show D9.
- Creating a tag always goes through D10 to confirm it and pick its category.

## 8. Data: `library.json` version 2

```json
{
  "version": 2,
  "tags": { "Genre": ["horror", "scifi"], "Mood": ["lighthearted"] },
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
      "items": [
        { "entry": "movies/the-mummy-1999", "done": false, "repeat": true, "note": "", "when": { "from": "2026-10-19", "to": "2026-10-31" } }
      ]
    }
  ]
}
```

Field rules:

- `id` keeps today's scheme (`movies/the-mummy-1999`, `music/dirt-alice-in-chains`).
- `type`: `movies`, `shows`, `books`, `games`, `music`, `anime`.
- `released` is text with flexible precision: `"1999"`, `"2026-12"` or `"2026-12-25"`. There is no separate `year`; the app derives the year and whether the title is out yet.
- `creator` is one field; the app labels it Director, Author, Artist and so on by type.
- `status`: `want`, `in_progress`, `done`, `dnf`.
- `rating`: 1 to 10 or `null`.
- `seasonal_only`: true for titles only wanted in season; hidden from the main lists unless "Include seasonal-only" is on.
- `when` on a plan item: `null`, or `from` and `to` (equal for a single day).
- Type-specific fields: `platform` (games), `formats` (books: `audiobook`, `physical`), and for music `kind` (`album` or `song`), `album` (songs, optional), `tracks` (albums, optional: `[{ "title", "id", "rating" }]`).
- Lookup IDs for entries (to re-fetch covers and track lists) can be added as a `source` field when lookups are built.

Not in the file: covers, track lists, view choices, theme, sort order. Those are caches or device preferences.

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
- Some older Plans mockups (S4, S9) still show an earlier red for Delete; the correct one is in the theme file.

## 11. Visual design

Exact values are in `lib/theme/app_theme.dart`.

- Dark graphite theme by default; a light theme with a white background and soft shadows for cards.
- Fonts: Bricolage Grotesque for titles, Figtree for everything else.
- One accent color chosen by the user in Settings, from a Vivid group and a Pastel group. Default: Hot pink. On the light theme a darker "ink" version of the accent is used.
- Each type has its own color, used for section headings, dots and labels. On the light theme the headings use darker versions of the same hues.
- Seasonal accents: Halloween orange, Christmas green, only inside a themed plan.
- Phone frame in the mockups is 390 × 844. Side padding is 20 px. Touch targets are at least 44 px.
