// FeedbackConfig
// Holds the Telegram bot token (obfuscated), chat ID, and app name.
//
// HOW TO GENERATE THE TOKEN CHAR CODES:
// 1. Open a Dart terminal or DartPad
// 2. Run: print('YOUR_BOT_TOKEN'.codeUnits);
// 3. Copy the output list and paste it into `_tokenCodes` below
//
// This prevents the token from appearing in a plain `strings` dump of your binary.
// It is NOT encryption -- just obfuscation to stop casual extraction.

class FeedbackConfig {
  // Replace with the output of the command above
  static const List<int> _tokenCodes = [
    // Example: these codes decode to "123456:ABC-DEF"
    // Run the command above with your real token and paste the result here
    49, 50, 51, 52, 53, 54, 58, 65, 66, 67, 45, 68, 69, 70,
  ];

  // Your Telegram chat ID where feedback messages will arrive
  static const String chatID = 'YOUR_CHAT_ID';

  // The name of your app (shown in the Telegram message)
  static const String appName = 'My App';

  // Decodes the bot token at runtime
  static String get botToken => String.fromCharCodes(_tokenCodes);
}
