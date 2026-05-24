import 'dart:io';

class RunContext {
  final String repo;
  final String branch;

  RunContext({required this.repo, required this.branch});

  factory RunContext.fromEnvironment() {
    return RunContext(
      repo: Platform.environment['GITHUB_REPOSITORY'] ?? 'unknown/unknown',
      branch: Platform.environment['GITHUB_REF']?.split('/').last ?? 'unknown',
    );
  }
}
