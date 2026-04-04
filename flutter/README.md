# FeedPush - Flutter (Dart)

Drop-in feedback module for Flutter apps. Users tap a button, type their feedback, and you receive it instantly via Telegram, Discord, or Slack.

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

### 2. Choose your delivery channel

FeedPush supports Telegram, Discord, and Slack. See the Swift README for setup instructions per channel.

### 3. Generate the obfuscated credentials

```dart
print('YOUR_TOKEN_OR_URL'.codeUnits);
```

### 4. Configure

Open `feedback_config.dart` and set your channel and credentials:

```dart
static const FeedbackChannel channel = FeedbackChannel.discord;  // or .telegram, .slack

// For Telegram:
static const List<int> _tokenCodes = [49, 50, 51, ...];
static const String chatID = '123456789';

// For Discord or Slack:
static const List<int> _webhookURLCodes = [104, 116, 116, ...];

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

- All credentials are stored as char code lists, not plain strings. This prevents them from appearing in a basic `strings` dump of your binary.
- A 60-second cooldown prevents rapid re-sends. The cooldown persists across app restarts via shared_preferences.
- Feedback text is capped at 2000 characters.
- For Discord/Slack, a leak only allows posting to one channel. For Telegram, revoke via @BotFather if needed.
