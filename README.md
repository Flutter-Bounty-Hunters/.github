# flutter-bounty-hunters/.github

This repository contains GitHub workflows, Dart automation scripts, and shared ops tooling for the `flutter-bounty-hunters` GitHub organization.

## Contents

- `.github/workflows/` — organization-level workflows for CI and scheduled automation.
- `bin/` — command-line Dart automation entry points.
- `lib/` — shared Dart package APIs and utilities.


## Getting started

```bash
dart pub get
dart analyze
dart test
```

## Available automation commands

```bash
dart run bin/ops_runner.dart lint
dart run bin/ops_runner.dart format
dart run bin/ops_runner.dart test
```

## GitHub issue and PR templates

This repository includes org-level templates for issues and pull requests:

- `.github/ISSUE_TEMPLATE/bug_report.md`
- `.github/ISSUE_TEMPLATE/feature_request.md`
- `.github/PULL_REQUEST_TEMPLATE.md`

Use the issue template chooser when opening new issues in GitHub.

## Workflows

### Daily Issue Report
The `daily_org_report.yml` workflow runs daily at 5 AM UTC and generates a comprehensive report of all public repositories in the organization. It:
- Counts total open issues per repository
- Tracks issues opened and closed since the previous report
- Sends an email report to superdeclarative@gmail.com

**Setup required:**
To enable this workflow, add the following organization secrets in GitHub:
- `ISSUE_REPORT_SENDER_EMAIL` — the Gmail address sending the report
- `ISSUE_REPORT_SENDER_PASSWORD` — the Gmail app-specific password (or SMTP password)

The workflow automatically uses the GitHub Actions `GITHUB_TOKEN` for API access.

