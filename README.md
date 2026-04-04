# FeedPush

Drop-in feedback module for mobile apps. Users tap a button, type their feedback, and you receive it instantly on your phone. No backend, no database, no user accounts.

## Supported Platforms

| Platform | Language | UI Framework |
|---|---|---|
| [Swift](./swift) | Swift | SwiftUI |
| [Kotlin](./kotlin) | Kotlin | Jetpack Compose |
| [Flutter](./flutter) | Dart | Flutter |
| [React Native](./react-native) | TypeScript | React Native / Expo |

Each platform is a standalone, independent implementation. Pick the one that matches your app, copy the files in, configure your credentials, and you're done.

## Delivery Channels

FeedPush supports three delivery channels. Pick the one that works best for you:

### Discord Webhook (Recommended)

The most secure option. A webhook URL can only post messages to one specific channel - nothing else.

| | |
|---|---|
| **Cost** | Free |
| **Setup** | Channel Settings > Integrations > Webhooks |
| **Push notifications** | Yes, via the Discord app |
| **If the credential leaks** | Attacker can only post to that one channel. Cannot read messages, cannot affect other channels, cannot DM users. |
| **Revocation** | Delete the webhook in Discord. Instant, no app update needed to stop abuse. |
| **Read access** | None. Write-only. |

### Slack Webhook

Same security model as Discord. Slack also auto-detects leaked webhook URLs in public repos and revokes them.

| | |
|---|---|
| **Cost** | Free |
| **Setup** | Create a Slack app, enable Incoming Webhooks |
| **Push notifications** | Yes, via the Slack app |
| **If the credential leaks** | Same as Discord - post to one channel only. |
| **Revocation** | Delete in Slack app settings. |
| **Read access** | None. Write-only. |
| **Note** | Free tier has 90-day message history limit (doesn't affect receiving feedback). |

### Telegram Bot

The simplest to set up, but the token grants more access than needed for this use case.

| | |
|---|---|
| **Cost** | Free |
| **Setup** | Message @BotFather, create a bot |
| **Push notifications** | Yes, via Telegram |
| **If the credential leaks** | Attacker gets full bot control: can send messages as the bot, intercept future messages, change bot settings. |
| **Revocation** | Revoke token via @BotFather. Must ship an app update with the new token. |
| **Read access** | Can intercept incoming messages via getUpdates or webhook hijacking. |
| **Mitigation** | Disable group joining via @BotFather. Since no users chat with the bot directly, the practical risk is limited to spam in your chat. |

### Which should I use?

**Discord** or **Slack** if security matters to you. They're strictly write-only - even with the credential, an attacker can only post to one channel.

**Telegram** if you want the simplest setup and already use Telegram. The risk is manageable for personal/small apps - worst case is spam in your chat, and you can revoke the token in 30 seconds.

## How It Works

1. You add a feedback button to your app (typically in settings).
2. User taps it. A sheet/modal opens with a text field.
3. User types their feedback and taps Send.
4. The app sends the message to your chosen channel (Telegram, Discord, or Slack).
5. You receive it as a push notification on your phone.

Each message includes:
- App name and version
- Platform and OS version
- Timestamp (UTC)
- The feedback text

## Security

- All credentials (bot tokens, webhook URLs) are stored as byte/char code arrays, not plain strings. This prevents casual extraction via `strings` dumps.
- A 60-second cooldown prevents accidental double-sends and casual spam.
- Feedback text is capped at 2000 characters (Telegram max is 4096, so metadata + feedback stays within bounds).
- This is obfuscation, not encryption. A determined attacker can reverse-engineer the credentials. The channel you choose determines how much damage they can do (see comparison above).

## Quick Start

1. Pick your platform folder ([swift](./swift), [kotlin](./kotlin), [flutter](./flutter), [react-native](./react-native))
2. Copy the files into your project
3. Choose a delivery channel and set up credentials (see the platform README)
4. Add `FeedbackButton` to your settings screen
5. Run the app and send a test message

See each platform's README for detailed setup instructions.

## License

MIT
