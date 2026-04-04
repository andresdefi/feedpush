// FeedbackChannel
// The delivery channel for feedback messages.

enum FeedbackChannel { telegram, discord, slack }

// FeedbackConfig
// Holds the delivery channel, credentials, and app name.
//
// TELEGRAM SETUP:
// 1. Create a bot via @BotFather on Telegram
// 2. Generate the obfuscated token char codes:
//    print('YOUR_BOT_TOKEN'.codeUnits);
// 3. Paste the list into `_tokenCodes` and set your `chatID`
//
// DISCORD SETUP:
// 1. In your Discord server, go to Channel Settings > Integrations > Webhooks
// 2. Create a webhook and copy the URL
// 3. Generate the obfuscated URL char codes:
//    print('YOUR_WEBHOOK_URL'.codeUnits);
// 4. Paste the list into `_webhookURLCodes`
//
// SLACK SETUP:
// 1. Create a Slack app at api.slack.com/apps
// 2. Enable Incoming Webhooks and create one for your channel
// 3. Generate the obfuscated URL char codes:
//    print('YOUR_WEBHOOK_URL'.codeUnits);
// 4. Paste the list into `_webhookURLCodes`

class FeedbackConfig {
  // Which channel to use for sending feedback
  static const FeedbackChannel channel = FeedbackChannel.telegram;

  // MARK: Telegram Configuration

  // Obfuscated bot token (only needed for telegram)
  static const List<int> _tokenCodes = [
    // Example: these codes decode to "123456:ABC-DEF"
    49, 50, 51, 52, 53, 54, 58, 65, 66, 67, 45, 68, 69, 70,
  ];

  // Telegram chat ID where feedback messages will arrive (only needed for telegram)
  static const String chatID = 'YOUR_CHAT_ID';

  // MARK: Discord / Slack Configuration

  // Obfuscated webhook URL (only needed for discord or slack)
  static const List<int> _webhookURLCodes = [
    // Paste your obfuscated webhook URL char codes here
  ];

  // MARK: App Info

  // The name of your app (shown in the feedback message)
  static const String appName = 'My App';

  // MARK: Decoded Values

  static String get botToken => String.fromCharCodes(_tokenCodes);

  static String get webhookURL => String.fromCharCodes(_webhookURLCodes);
}
