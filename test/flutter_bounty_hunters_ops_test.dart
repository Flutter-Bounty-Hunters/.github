import 'package:flutter_bounty_hunters_ops/flutter_bounty_hunters_ops.dart';
import 'package:test/test.dart';

void main() {
  test('RunContext can be created from env variables', () {
    const repo = 'flutter-bounty-hunters/example';
    const branch = 'main';
    final context = RunContext(repo: repo, branch: branch);

    expect(context.repo, equals(repo));
    expect(context.branch, equals(branch));
  });
}
