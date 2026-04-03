import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'feedback_config.dart';

// FeedbackService
// Sends feedback to a Telegram bot using the Telegram Bot API.
// Uses the `http` package -- the only external dependency.

class FeedbackResult {
  final bool success;
  final String? error;

  const FeedbackResult.success() : success = true, error = null;
  const FeedbackResult.failure(this.error) : success = false;
}

class FeedbackService {
  /// Sends feedback to the configured Telegram bot.
  ///
  /// [text] - The feedback message (max 2000 characters).
  /// [email] - Optional email for follow-up.
  /// [client] - Optional HTTP client (injectable for testing).
  static Future<FeedbackResult> send({
    required String text,
    String? email,
    http.Client? client,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const FeedbackResult.failure('Feedback text cannot be empty.');
    }

    final message = await buildMessage(text: trimmed, email: email);
    final token = FeedbackConfig.botToken;
    final url = Uri.parse('https://api.telegram.org/bot$token/sendMessage');

    final body = jsonEncode({
      'chat_id': FeedbackConfig.chatID,
      'text': message,
      'parse_mode': 'Markdown',
    });

    try {
      final httpClient = client ?? http.Client();
      final response = await httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      // Close the client only if we created it
      if (client == null) httpClient.close();

      if (response.statusCode == 200) {
        return const FeedbackResult.success();
      } else {
        return FeedbackResult.failure(
          'Telegram API error (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      return FeedbackResult.failure('Network error: ${e.toString()}');
    }
  }

  // Visible for testing
  static Future<String> buildMessage({
    required String text,
    String? email,
  }) async {
    final appName = FeedbackConfig.appName;

    String appVersion;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
    } catch (_) {
      appVersion = 'Unknown';
    }

    final platformName = Platform.isIOS ? 'iOS' : 'Android';
    final osVersion = Platform.operatingSystemVersion;
    final platformEmoji = Platform.isIOS ? '\u{1F34E}' : '\u{1F916}';

    final now = DateTime.now().toUtc();
    final timestamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final emailValue = email?.trim() ?? '';
    final emailLine = emailValue.isEmpty
        ? '\n\u{1F4E7} Email: (not provided)'
        : '\n\u{1F4E7} Email: $emailValue';

    return '\u{1F4F1} App: $appName\n'
        '\u{1F4E6} Version: $appVersion\n'
        '$platformEmoji Platform: $platformName $osVersion\n'
        '\u{1F554} Time: $timestamp UTC\n'
        '\n'
        '\u{1F4AC} Feedback:\n'
        '$text'
        '$emailLine';
  }
}
