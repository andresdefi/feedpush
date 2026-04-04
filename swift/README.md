# FeedPush - Swift (iOS)

Drop-in feedback module for iOS apps. Users tap a button, type their feedback, and you receive it instantly via Telegram, Discord, or Slack.

## Requirements

- iOS 17+
- SwiftUI
- No third-party dependencies

## Setup

### 1. Add the files

Copy these four files into your Xcode project:

- `FeedbackConfig.swift`
- `FeedbackService.swift`
- `FeedbackButton.swift`
- `FeedbackSheet.swift`

### 2. Choose your delivery channel

FeedPush supports three channels. Pick one:

#### Option A: Telegram (simplest)
1. Message [@BotFather](https://t.me/BotFather) on Telegram, send `/newbot`
2. Copy the bot token
3. Message [@userinfobot](https://t.me/userinfobot) to get your chat ID
4. Recommended: send `/setjoingroups` to BotFather and disable it

#### Option B: Discord (most secure)
1. In your Discord server, go to Channel Settings > Integrations > Webhooks
2. Create a webhook and copy the URL

#### Option C: Slack
1. Create a Slack app at [api.slack.com/apps](https://api.slack.com/apps)
2. Enable Incoming Webhooks and create one for your channel
3. Copy the webhook URL

### 3. Generate the obfuscated credentials

Open Terminal and run:

```bash
# For Telegram bot token:
swift -e 'let t = "YOUR_BOT_TOKEN_HERE"; print(Array(t.utf8))'

# For Discord/Slack webhook URL:
swift -e 'let t = "YOUR_WEBHOOK_URL_HERE"; print(Array(t.utf8))'
```

This outputs an array of bytes like `[49, 50, 51, ...]`. Copy this array.

### 4. Configure

Open `FeedbackConfig.swift` and set your channel and credentials:

```swift
// Pick your channel
static let channel: FeedbackChannel = .discord  // or .telegram, .slack

// For Telegram: set tokenBytes and chatID
static let tokenBytes: [UInt8] = [49, 50, 51, ...]
static let chatID = "123456789"

// For Discord or Slack: set webhookURLBytes
static let webhookURLBytes: [UInt8] = [104, 116, 116, ...]

// Your app's name
static let appName = "My App"
```

### 5. Add the button to your app

Place `FeedbackButton` anywhere in your app -- typically in a settings screen:

```swift
struct SettingsView: View {
    var body: some View {
        VStack {
            // ... other settings ...

            FeedbackButton()
                .padding(.horizontal)
        }
    }
}
```

You can customize the button text:

```swift
FeedbackButton(
    icon: "\u{1F41B}",
    title: "Found a bug?",
    subtitle: "Let us know so we can fix it"
)
```

And the sheet strings:

```swift
// Inside FeedbackButton, the sheet is configurable too:
FeedbackSheet(
    feedbackPlaceholder: "Tell us what happened...",
    sendButtonText: "Submit",
    successMessage: "Thanks! We'll look into it."
)
```

## How it works

1. User taps the feedback button
2. A sheet slides up with a text field
3. User types their feedback and taps Send
4. The app POSTs the message to your chosen channel (Telegram, Discord, or Slack)
5. You receive it as a push notification on your phone

The feedback message includes the app name, version, iOS version, and timestamp automatically.

## Which channel should I use?

| Channel | Security | If credential leaks... | Revocation |
|---|---|---|---|
| **Discord** | Best | Attacker can only post to one channel. No read access. | Delete webhook in Discord settings |
| **Slack** | Best | Same as Discord. Slack also auto-detects leaked URLs. | Delete in Slack app settings |
| **Telegram** | Good | Attacker gets full bot control (send/receive). | Revoke via @BotFather, ship app update |

For maximum security, use **Discord** or **Slack** webhooks. They're write-only and scoped to a single channel.

## Security notes

- All credentials (tokens, webhook URLs) are stored as byte arrays, not plain strings. This prevents them from appearing in a basic `strings` dump of your binary.
- A 60-second cooldown prevents rapid re-sends. The cooldown persists across app restarts.
- Feedback text is capped at 2000 characters.
- This is obfuscation, not encryption. If someone decompiles your app and actively reverse-engineers it, they can recover the credentials. For Discord/Slack, this only allows posting to one channel. For Telegram, revoke and rotate the token via @BotFather if needed.
