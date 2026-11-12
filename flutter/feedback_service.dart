import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'feedback_config.dart';

// FeedbackService
// Sends feedback via Telegram, Discord, Slack, or Proxy depending on FeedbackConfig.channel.
// Uses the `http` package -- the only external dependency.

class FeedbackResult {
  final bool success;
  final String? error;

  const FeedbackResult.success() : success = true, error = null;
  const FeedbackResult.failure(this.error) : success = false;
}

class FeedbackService {
  static final _emailPattern = RegExp(r'^[^\s@`]+@[^\s@`]+\.[^\s@`]+$');

  /// A plain address: no spaces or backticks (it is shown inside a Markdown
  /// code span), one @ and a dot after it. The proxy checks the same.
  static bool isValidEmail(String email) {
    final trimmed = email.trim();
    return trimmed.length <= 254 && _emailPattern.hasMatch(trimmed);
  }

  /// [email] is an optional reply address, only when the user wants an
  /// answer; blank means none.
  static Future<FeedbackResult> send({
    required String text,
    String? category,
    String? email,
    http.Client? client,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const FeedbackResult.failure('Feedback text cannot be empty.');
    }
    final replyTo = (email == null || email.trim().isEmpty) ? null : email.trim();
    if (replyTo != null && !isValidEmail(replyTo)) {
      return const FeedbackResult.failure("The email address doesn't look right.");
    }

    final Uri url;
    final String body;

    switch (FeedbackConfig.channel) {
      case FeedbackChannel.telegram:
        final message = await buildMessage(text: trimmed, category: category, email: replyTo);
        final token = FeedbackConfig.botToken;
        url = Uri.parse('https://api.telegram.org/bot$token/sendMessage');
        body = jsonEncode({
          'chat_id': FeedbackConfig.chatID,
          'text': message,
          'parse_mode': 'Markdown',
        });
        break;
      case FeedbackChannel.discord:
        final message = await buildMessage(text: trimmed, category: category, email: replyTo);
        url = Uri.parse(FeedbackConfig.webhookURL);
        body = jsonEncode({'content': message});
        break;
      case FeedbackChannel.slack:
        final message = await buildMessage(text: trimmed, category: category, email: replyTo);
        url = Uri.parse(FeedbackConfig.webhookURL);
        body = jsonEncode({'text': message});
        break;
      case FeedbackChannel.proxy:
        url = Uri.parse(FeedbackConfig.proxyURL);
        final packageInfo = await PackageInfo.fromPlatform();
        final platformName = Platform.isIOS ? 'iOS' : 'Android';
        final osVersion = Platform.operatingSystemVersion;
        body = jsonEncode({
          'app_name': FeedbackConfig.appName,
          'app_version': packageInfo.version,
          'platform': '$platformName $osVersion',
          'feedback': trimmed,
          if (category != null && category.trim().isNotEmpty)
            'category': category,
          if (replyTo != null) 'email': replyTo,
        });
        break;
    }

    try {
      final httpClient = client ?? http.Client();
      final response = await httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (client == null) httpClient.close();

      // Discord returns 204 No Content on success
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const FeedbackResult.success();
      } else {
        return FeedbackResult.failure(
          'API error (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      return FeedbackResult.failure('Network error: ${e.toString()}');
    }
  }

  static Future<String> buildMessage({
    required String text,
    String? category,
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

    final typeLine = (category != null && category.trim().isNotEmpty)
        ? '\u{1F3F7}\u{FE0F} Type: $category\n'
        : '';

    // In a code span: Markdown can't break on "_", and it copies in one tap.
    final replyLine = (email != null && email.trim().isNotEmpty)
        ? '\u{2709}\u{FE0F} Reply to: `${email.trim()}`\n'
        : '';

    return '\u{1F4F1} App: $appName\n'
        '\u{1F4E6} Version: $appVersion\n'
        '$platformEmoji Platform: $platformName $osVersion\n'
        '\u{1F554} Time: $timestamp UTC\n'
        '$typeLine'
        '$replyLine'
        '\n'
        '\u{1F4AC} Feedback:\n'
        '$text';
  }
}
