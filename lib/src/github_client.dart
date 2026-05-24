import 'dart:io';

import 'package:github/github.dart';

class GithubClient {
  final GitHub _client;

  GithubClient({String? token})
      : _client = GitHub(auth: Authentication.withToken(token ?? Platform.environment['GITHUB_TOKEN'] ?? ''));

  Future<List<Repository>> listOrganizationRepositories(String org) async {
    return _client.repositories.listOrganizationRepositories(org).toList();
  }

  Future<void> close() async {
    _client.dispose();
  }
}
