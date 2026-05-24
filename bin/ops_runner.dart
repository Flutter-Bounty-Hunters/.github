import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter_bounty_hunters_ops/flutter_bounty_hunters_ops.dart';

void main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help message.')
    ..addCommand('lint')
    ..addCommand('format')
    ..addCommand('test')
    ..addCommand('describe');

  final result = parser.parse(args);
  if (result['help'] as bool || result.command == null) {
    print('Usage: dart run bin/ops_runner.dart <command>');
    print(parser.usage);
    return;
  }

  final command = result.command!.name;
  switch (command) {
    case 'lint':
      await _runProcess('dart', ['analyze']);
      break;
    case 'format':
      await _runProcess('dart', ['format', '.']);
      break;
    case 'test':
      await _runProcess('dart', ['test']);
      break;
    case 'describe':
      final context = RunContext.fromEnvironment();
      print('Repository: \u001b[1m${context.repo}\u001b[0m');
      print('Branch: ${context.branch}');
      break;
    default:
      print('Unknown command: $command');
  }
}

Future<void> _runProcess(String executable, List<String> arguments) async {
  final process = await Process.start(executable, arguments, mode: ProcessStartMode.inheritStdio);
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    exit(exitCode);
  }
}
