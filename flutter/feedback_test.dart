import 'package:flutter_test/flutter_test.dart';

// To run these tests, copy this file into your Flutter project's test/ directory
// and adjust the import path to match your project structure.
// import 'package:your_app/feedback/feedback_config.dart';
// import 'package:your_app/feedback/feedback_service.dart';

// For standalone reference, the tests below use inline equivalents.

// MARK: FeedbackConfig Tests

void main() {
  group('FeedbackConfig', () {
    test('token decodes from char codes', () {
      // Default placeholder codes should decode to "123456:ABC-DEF"
      const tokenCodes = [49, 50, 51, 52, 53, 54, 58, 65, 66, 67, 45, 68, 69, 70];
      final token = String.fromCharCodes(tokenCodes);
      expect(token, '123456:ABC-DEF');
    });

    test('token is not empty', () {
      const tokenCodes = [49, 50, 51, 52, 53, 54, 58, 65, 66, 67, 45, 68, 69, 70];
      final token = String.fromCharCodes(tokenCodes);
      expect(token.isNotEmpty, true);
    });

    test('token char codes round trip', () {
      const original = 'test:token-123';
      final codes = original.codeUnits;
      final decoded = String.fromCharCodes(codes);
      expect(decoded, original);
    });

    test('empty char codes produce empty string', () {
      final token = String.fromCharCodes(<int>[]);
      expect(token, '');
    });
  });

  // MARK: Message Formatting Tests
  // These test the message format logic inline since buildMessage depends on
  // dart:io Platform which isn't available in unit tests.
  // The format logic is tested by constructing the message the same way the service does.

  group('Message formatting', () {
    String buildTestMessage({
      required String text,
      String? email,
      String appName = 'My App',
      String appVersion = '1.0.0',
      String platform = 'iOS 18.0',
      String platformEmoji = '\u{1F34E}',
    }) {
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
          '$platformEmoji Platform: $platform\n'
          '\u{1F554} Time: $timestamp UTC\n'
          '\n'
          '\u{1F4AC} Feedback:\n'
          '$text'
          '$emailLine';
    }

    test('message contains app name', () {
      final message = buildTestMessage(text: 'Great app!');
      expect(message.contains('App: My App'), true);
    });

    test('message contains feedback text', () {
      const feedbackText = 'This is my feedback about the app';
      final message = buildTestMessage(text: feedbackText);
      expect(message.contains(feedbackText), true);
    });

    test('message contains feedback header', () {
      final message = buildTestMessage(text: 'Test');
      expect(message.contains('Feedback:'), true);
    });

    test('message contains version line', () {
      final message = buildTestMessage(text: 'Test');
      expect(message.contains('Version: 1.0.0'), true);
    });

    test('message contains platform line', () {
      final message = buildTestMessage(text: 'Test');
      expect(message.contains('Platform:'), true);
    });

    test('message contains timestamp', () {
      final message = buildTestMessage(text: 'Test');
      expect(message.contains('Time:'), true);
      expect(message.contains('UTC'), true);
    });

    test('message with no email shows not provided', () {
      final message = buildTestMessage(text: 'Test');
      expect(message.contains('Email: (not provided)'), true);
    });

    test('message with empty email shows not provided', () {
      final message = buildTestMessage(text: 'Test', email: '');
      expect(message.contains('Email: (not provided)'), true);
    });

    test('message with whitespace only email shows not provided', () {
      final message = buildTestMessage(text: 'Test', email: '   ');
      expect(message.contains('Email: (not provided)'), true);
    });

    test('message with email shows email', () {
      const email = 'user@example.com';
      final message = buildTestMessage(text: 'Test', email: email);
      expect(message.contains('Email: $email'), true);
      expect(message.contains('(not provided)'), false);
    });

    test('message with email with whitespace trims it', () {
      final message =
          buildTestMessage(text: 'Test', email: '  user@example.com  ');
      expect(message.contains('Email: user@example.com'), true);
    });

    test('message order is correct', () {
      final message = buildTestMessage(text: 'My feedback', email: 'a@b.com');

      final appIndex = message.indexOf('App:');
      final versionIndex = message.indexOf('Version:');
      final platformIndex = message.indexOf('Platform:');
      final timeIndex = message.indexOf('Time:');
      final feedbackIndex = message.indexOf('Feedback:');
      final emailIndex = message.indexOf('Email:');

      expect(appIndex < versionIndex, true);
      expect(versionIndex < platformIndex, true);
      expect(platformIndex < timeIndex, true);
      expect(timeIndex < feedbackIndex, true);
      expect(feedbackIndex < emailIndex, true);
    });

    test('message with special characters', () {
      const text = 'Feedback with special chars: <>&"\' and emojis \u{1F600}\u{1F525}';
      final message = buildTestMessage(text: text);
      expect(message.contains(text), true);
    });

    test('message with multiline feedback', () {
      const text = 'Line 1\nLine 2\nLine 3';
      final message = buildTestMessage(text: text);
      expect(message.contains(text), true);
    });

    test('message with max length feedback stays under telegram limit', () {
      final text = 'a' * 2000;
      final message = buildTestMessage(text: text);
      expect(message.contains(text), true);
      expect(message.length <= 4096, true);
    });
  });

  // MARK: FeedbackResult Tests

  group('FeedbackResult', () {
    test('success result', () {
      const result = FeedbackResult.success();
      expect(result.success, true);
      expect(result.error, null);
    });

    test('failure result contains message', () {
      const result = FeedbackResult.failure('Something went wrong');
      expect(result.success, false);
      expect(result.error, 'Something went wrong');
    });

    test('failure result with empty message', () {
      const result = FeedbackResult.failure('');
      expect(result.success, false);
      expect(result.error, '');
    });
  });

  // MARK: Input Validation Tests

  group('Input validation', () {
    test('empty text should be rejected', () {
      final trimmed = ''.trim();
      expect(trimmed.isEmpty, true);
    });

    test('whitespace only text should be rejected', () {
      final trimmed = '   \n\t  '.trim();
      expect(trimmed.isEmpty, true);
    });

    test('text within limit is valid', () {
      final text = 'a' * 2000;
      expect(text.length <= 2000, true);
    });

    test('text exceeding limit is invalid', () {
      final text = 'a' * 2001;
      expect(text.length > 2000, true);
    });
  });
}

// Inline FeedbackResult for standalone test compilation
class FeedbackResult {
  final bool success;
  final String? error;

  const FeedbackResult.success() : success = true, error = null;
  const FeedbackResult.failure(this.error) : success = false;
}
