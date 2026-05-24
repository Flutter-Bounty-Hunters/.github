import 'dart:convert';
import 'package:github/github.dart';

class IssueStats {
  final String repoName;
  final int totalOpen;
  final int openedSinceLastReport;
  final int closedSinceLastReport;

  IssueStats({
    required this.repoName,
    required this.totalOpen,
    required this.openedSinceLastReport,
    required this.closedSinceLastReport,
  });

  Map<String, dynamic> toJson() {
    return {
      'repoName': repoName,
      'totalOpen': totalOpen,
      'openedSinceLastReport': openedSinceLastReport,
      'closedSinceLastReport': closedSinceLastReport,
    };
  }

  static IssueStats fromJson(Map<String, dynamic> json) {
    return IssueStats(
      repoName: json['repoName'] as String,
      totalOpen: json['totalOpen'] as int,
      openedSinceLastReport: json['openedSinceLastReport'] as int,
      closedSinceLastReport: json['closedSinceLastReport'] as int,
    );
  }
}

class IssueReportCollector {
  final GitHub github;
  final String org;

  IssueReportCollector({required this.github, required this.org});

  Future<List<IssueStats>> collectStats(DateTime since) async {
    final repos = await github.repositories
        .listOrganizations(org)
        .where((repo) => !repo.isPrivate!)
        .toList();

    final stats = <IssueStats>[];

    for (final repo in repos) {
      final openIssues = await github.issues
          .listByRepo(
            RepositorySlug(org, repo.name!),
            state: 'open',
          )
          .toList();

      final openedSince = await github.issues
          .listByRepo(
            RepositorySlug(org, repo.name!),
            state: 'open',
            since: since,
          )
          .toList();

      final closedSince = await github.issues
          .listByRepo(
            RepositorySlug(org, repo.name!),
            state: 'closed',
            since: since,
          )
          .toList();

      stats.add(IssueStats(
        repoName: repo.name!,
        totalOpen: openIssues.length,
        openedSinceLastReport: openedSince.length,
        closedSinceLastReport: closedSince.length,
      ));
    }

    return stats;
  }
}
