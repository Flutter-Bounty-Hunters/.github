import 'dart:convert';
import 'dart:io';

import 'package:flutter_bounty_hunters_ops/flutter_bounty_hunters_ops.dart';
import 'package:github/github.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

const String reportStoragePath = 'data/issue_report.json';

Future<void> main(List<String> args) async {
  final token = Platform.environment['GITHUB_TOKEN'];
  final smtpHost = Platform.environment['SMTP_HOST'] ?? 'smtp.gmail.com';
  final smtpPort = int.tryParse(Platform.environment['SMTP_PORT'] ?? '587') ?? 587;
  final senderEmail = Platform.environment['SENDER_EMAIL'];
  final senderPassword = Platform.environment['SENDER_PASSWORD'];
  final recipientEmail = Platform.environment['RECIPIENT_EMAIL'] ?? 'superdeclarative@gmail.com';

  if (token == null || senderEmail == null || senderPassword == null) {
    print('Error: Missing required environment variables');
    print('Required: GITHUB_TOKEN, SENDER_EMAIL, SENDER_PASSWORD');
    exit(1);
  }

  final github = GitHub(auth: Authentication.withToken(token));
  final collector = IssueReportCollector(github: github, org: 'flutter-bounty-hunters');

  // Load previous report
  final lastReport = _loadLastReport();
  final now = DateTime.now();
  final sinceTime = lastReport?['timestamp'] != null ? DateTime.parse(lastReport!['timestamp'] as String) : now.subtract(const Duration(days: 1));

  print('Collecting issue statistics since $sinceTime...');

  // Collect current stats
  final currentStats = await collector.collectStats(sinceTime);

  // Generate report
  final reportHtml = _generateReportHtml(currentStats);

  // Send email
  print('Sending report to $recipientEmail...');
  await _sendEmail(
    smtpHost: smtpHost,
    smtpPort: smtpPort,
    senderEmail: senderEmail,
    senderPassword: senderPassword,
    recipientEmail: recipientEmail,
    reportHtml: reportHtml,
  );

  // Save current report
  _saveReport(currentStats, now);

  print('Report sent successfully!');
  github.dispose();
}

Map<String, dynamic>? _loadLastReport() {
  final file = File(reportStoragePath);
  if (!file.existsSync()) {
    return null;
  }
  try {
    final content = file.readAsStringSync();
    return jsonDecode(content) as Map<String, dynamic>;
  } catch (e) {
    print('Warning: Could not load last report: $e');
    return null;
  }
}

void _saveReport(List<IssueStats> stats, DateTime timestamp) {
  final file = File(reportStoragePath);
  file.createSync(recursive: true);
  file.writeAsStringSync(
    jsonEncode({
      'timestamp': timestamp.toIso8601String(),
      'stats': stats.map((s) => s.toJson()).toList(),
    }),
  );
}

String _generateReportHtml(List<IssueStats> stats) {
  final totalRepos = stats.length;
  final totalOpenIssues = stats.fold<int>(0, (sum, s) => sum + s.totalOpen);
  final totalOpenedToday = stats.fold<int>(0, (sum, s) => sum + s.openedSinceLastReport);
  final totalClosedToday = stats.fold<int>(0, (sum, s) => sum + s.closedSinceLastReport);

  final rows = stats.map((s) {
    return '''
    <tr>
      <td style="padding: 8px; border-bottom: 1px solid #e0e0e0;">${s.repoName}</td>
      <td style="padding: 8px; border-bottom: 1px solid #e0e0e0; text-align: center;">${s.totalOpen}</td>
      <td style="padding: 8px; border-bottom: 1px solid #e0e0e0; text-align: center;">${s.openedSinceLastReport}</td>
      <td style="padding: 8px; border-bottom: 1px solid #e0e0e0; text-align: center;">${s.closedSinceLastReport}</td>
    </tr>
    ''';
  }).join('\n');

  return '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; color: #333; }
    h1 { color: #0366d6; }
    table { width: 100%; border-collapse: collapse; margin: 20px 0; }
    th { background-color: #f5f5f5; padding: 12px; text-align: left; font-weight: 600; border-bottom: 2px solid #e0e0e0; }
    td { padding: 8px; border-bottom: 1px solid #e0e0e0; }
    .summary { background-color: #f5f5f5; padding: 15px; border-radius: 6px; margin: 20px 0; }
    .summary p { margin: 8px 0; }
  </style>
</head>
<body>
  <h1>Daily Issue Report - flutter-bounty-hunters</h1>
  <p><em>Generated: ${DateTime.now().toLocal()}</em></p>

  <div class="summary">
    <h2>Summary</h2>
    <p><strong>Total Repositories:</strong> $totalRepos</p>
    <p><strong>Total Open Issues:</strong> $totalOpenIssues</p>
    <p><strong>Opened Since Last Report:</strong> $totalOpenedToday</p>
    <p><strong>Closed Since Last Report:</strong> $totalClosedToday</p>
  </div>

  <h2>Issues by Repository</h2>
  <table>
    <thead>
      <tr>
        <th>Repository</th>
        <th>Open Issues</th>
        <th>Opened</th>
        <th>Closed</th>
      </tr>
    </thead>
    <tbody>
      $rows
    </tbody>
  </table>
</body>
</html>
  ''';
}

Future<void> _sendEmail({
  required String smtpHost,
  required int smtpPort,
  required String senderEmail,
  required String senderPassword,
  required String recipientEmail,
  required String reportHtml,
}) async {
  final useSsl = smtpPort == 465;
  final smtpServer = SmtpServer(
    smtpHost,
    port: smtpPort,
    username: senderEmail,
    password: senderPassword,
    ssl: useSsl,
    ignoreBadCertificate: false,
  );

  final message = Message()
    ..from = Address(senderEmail)
    ..recipients.add(recipientEmail)
    ..subject = '[flutter-bounty-hunters] Daily Issue Report - ${DateTime.now().toLocal().toString().split(' ')[0]}'
    ..html = reportHtml;

  try {
    await send(message, smtpServer);
  } catch (e) {
    print('Error sending email: $e');
    rethrow;
  }
}
