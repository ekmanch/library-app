import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/github/token_store.dart';

void main() {
  test('the memory store keeps, replaces and forgets the token', () async {
    final store = MemoryTokenStore();
    expect(await store.read(), isNull);
    await store.write('github_pat_a');
    expect(await store.read(), 'github_pat_a');
    await store.write('github_pat_b');
    expect(await store.read(), 'github_pat_b');
    await store.delete();
    expect(await store.read(), isNull);
  });
}
