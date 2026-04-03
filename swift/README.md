# FeedPush - Swift (iOS)

Drop-in feedback module for iOS apps. Users tap a button, type their feedback, and you receive it instantly via Telegram.

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

### 2. Create your Telegram bot

1. Open Telegram and message [@BotFather](https://t.me/BotFather)
2. Send `/newbot` and follow the prompts
3. Copy the bot token you receive
4. To get your chat ID, message [@userinfobot](https://t.me/userinfobot) -- it will reply with your ID

### 3. Generate the obfuscated token

Open Terminal and run:

```bash
swift -e 'let t = "YOUR_BOT_TOKEN_HERE"; print(Array(t.utf8))'
```

This outputs an array of bytes like `[49, 50, 51, ...]`. Copy this array.

### 4. Configure

Open `FeedbackConfig.swift` and set:

```swift
// Paste your byte array here
static let tokenBytes: [UInt8] = [49, 50, 51, ...]

// Your Telegram chat ID
static let chatID = "123456789"

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
2. A sheet slides up with a text field and optional email field
3. User types their feedback and taps Send
4. The app POSTs the message to the Telegram Bot API
5. You receive it as a push notification in Telegram

The feedback message includes the app name, version, iOS version, and timestamp automatically.

## Security notes

- The bot token is stored as a byte array, not a plain string. This prevents it from appearing in a basic `strings` dump of your binary.
- A 60-second cooldown prevents rapid re-sends. The cooldown persists across app restarts.
- Feedback text is capped at 2000 characters.
- This is obfuscation, not encryption. If someone decompiles your app and actively reverse-engineers it, they can recover the token. The risk is low -- worst case is spam in your Telegram chat. Revoke and rotate the token via @BotFather if needed.
