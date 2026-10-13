// Assigns every entry id in a library.json with the app's own EntryId.generate,
// so the data repo and the app follow one id scheme. Used once by the
// ekmanch/library migration (phase 3); plan items are rewritten to the new ids
// and the file is written in the canonical encoding.
//
// Run from the project root:
//   dart run tool/assign_ids.dart <in.json> <out.json>
//
// Entries keep their order. Ids are assigned in that order, so a collision
// gets "-2" on the later entry. Running it on its own output changes nothing.
import 'dart:io';

import 'package:library_app/data/library_codec.dart';
import 'package:library_app/data/models/entry.dart';
import 'package:library_app/data/models/entry_id.dart';
import 'package:library_app/data/models/media_type.dart';
import 'package:library_app/data/models/plan.dart';
import 'package:library_app/data/models/plan_item.dart';

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln('Usage: dart run tool/assign_ids.dart <in.json> <out.json>');
    exit(2);
  }
  final library = decodeLibrary(File(args[0]).readAsStringSync());

  final assigned = <String>[];
  final renamed = <String, String>{};
  final suffixed = <String>[];
  final entries = <Entry>[];
  for (final entry in library.entries) {
    final id = EntryId.generate(
      type: entry.type,
      title: entry.title,
      year: entry.year?.toString(),
      artist: entry.type == MediaType.music ? entry.creator : null,
      existingIds: assigned,
    );
    // A "-2" style suffix was added when the id without it is already taken.
    final base = RegExp(r'^(.*)-\d+$').firstMatch(id)?.group(1);
    if (base != null && assigned.contains(base)) suffixed.add(id);
    assigned.add(id);
    if (id != entry.id) {
      if (renamed.containsKey(entry.id)) {
        stderr.writeln('Duplicate old id ${entry.id}; cannot rewrite plans.');
        exit(1);
      }
      renamed[entry.id] = id;
    }
    entries.add(entry.copyWith(id: id));
  }

  final plans = <Plan>[];
  var rewritten = 0;
  for (final plan in library.plans) {
    final items = <PlanItem>[];
    for (final item in plan.items) {
      final target = renamed[item.entry];
      if (target != null) rewritten++;
      items.add(item.copyWith(entry: target ?? item.entry));
    }
    plans.add(plan.copyWith(items: items));
  }

  final out = library.copyWith(entries: entries, plans: plans);
  File(args[1]).writeAsStringSync(encodeLibrary(out));

  stdout.writeln(
    '${entries.length} entries, ${renamed.length} ids changed, '
    '$rewritten plan items rewritten.',
  );
  if (suffixed.isNotEmpty) {
    stdout.writeln('Collision suffixes added: ${suffixed.join(', ')}');
  }
  for (final MapEntry(key: from, value: to) in renamed.entries) {
    stdout.writeln('  $from -> $to');
  }
}
