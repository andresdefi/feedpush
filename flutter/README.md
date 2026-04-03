# FeedPush - Flutter (Dart)

Drop-in feedback module for Flutter apps. Users tap a button, type their feedback, and you receive it instantly via Telegram.

## Requirements

- Flutter 3.x+
- Dart 3.x+

## Dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.0.0
  package_info_plus: ^8.0.0
  shared_preferences: ^2.0.0
```

## Setup

### 1. Add the files

Copy these four files into your project (e.g., `lib/feedback/`):

- `feedback_config.dart`
- `feedback_service.dart`
- `feedback_button.dart`
- `feedback_sheet.dart`

Copy `feedback_test.dart` into your `test/` directory.

### 2. Create your Telegram bot

1. Open Telegram and message [@BotFather](https://t.me/BotFather)
2. Send `/newbot` and follow the prompts
3. Copy the bot token you receive
4. To get your chat ID, message [@userinfobot](https://t.me/userinfobot) -- it will reply with your ID

### 3. Generate the obfuscated token

Run in DartPad or a Dart terminal:

```dart
print('YOUR_BOT_TOKEN_HERE'.codeUnits);
```

This outputs a list like `[49, 50, 51, ...]`. Copy this list.

### 4. Configure

Open `feedback_config.dart` and set:

```dart
static const List<int> _tokenCodes = [49, 50, 51, ...];

static const String chatID = '123456789';

static const String appName = 'My App';
```

### 5. Add the button to your app

Place `FeedbackButton` anywhere -- typically in a settings screen:

```dart
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ... other settings ...

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: FeedbackButton(),
        ),
      ],
    );
  }
}
```

You can customize the button and sheet text:

```dart
FeedbackButton(
  icon: '\u{1F41B}',
  title: 'Found a bug?',
  subtitle: 'Let us know so we can fix it',
  feedbackPlaceholder: 'Tell us what happened...',
  sendButtonText: 'Submit',
  successMessage: 'Thanks! We\'ll look into it.',
)
```

## How it works

1. User taps the feedback button
2. A modal bottom sheet slides up with a text field and optional email field
3. User types their feedback and taps Send
4. The app POSTs the message to the Telegram Bot API
5. You receive it as a push notification in Telegram

The feedback message includes the app name, version, platform (iOS/Android), and timestamp automatically.

## Security notes

- The bot token is stored as a list of char codes, not a plain string. This prevents it from appearing in a basic `strings` dump of your binary.
- A 60-second cooldown prevents rapid re-sends. The cooldown persists across app restarts via shared_preferences.
- Feedback text is capped at 2000 characters.
- This is obfuscation, not encryption. If someone decompiles your app and actively reverse-engineers it, they can recover the token. The risk is low -- worst case is spam in your Telegram chat. Revoke and rotate the token via @BotFather if needed.
