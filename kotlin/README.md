# FeedPush - Kotlin (Android)

Drop-in feedback module for Jetpack Compose apps. Users tap a button, type their feedback, and you receive it instantly via Telegram, Discord, or Slack.

## Requirements

- Android API 24+ (Android 7.0)
- Jetpack Compose
- Material 3
- Kotlin Coroutines
- No third-party networking dependencies (uses native HttpURLConnection)

## Setup

### 1. Add the files

Copy these files into your project's source directory (e.g., `app/src/main/java/com/yourapp/feedback/`):

- `FeedbackConfig.kt`
- `FeedbackService.kt`
- `FeedbackButton.kt`
- `FeedbackSheet.kt`

Update the `package` declaration at the top of each file to match your project's package name.

Copy `FeedbackTests.kt` into your test directory (e.g., `app/src/test/java/com/yourapp/feedback/`).

### 2. Add internet permission

Make sure your `AndroidManifest.xml` includes:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### 3. Choose your delivery channel

FeedPush supports Telegram, Discord, and Slack. See the Swift README for setup instructions per channel -- the process is the same, only the obfuscation command differs.

### 4. Generate the obfuscated credentials

```kotlin
kotlin -e 'val t = "YOUR_TOKEN_OR_URL"; println(t.toByteArray().joinToString(", ") { it.toString() })'
```

### 5. Configure

Open `FeedbackConfig.kt` and set your channel and credentials:

```kotlin
val channel: FeedbackChannel = FeedbackChannel.DISCORD  // or TELEGRAM, SLACK

// For Telegram:
private val tokenBytes: ByteArray = byteArrayOf(49, 50, 51, ...)
const val chatID: String = "123456789"

// For Discord or Slack:
private val webhookURLBytes: ByteArray = byteArrayOf(104, 116, 116, ...)

const val appName: String = "My App"
```

### 6. Add the button to your app

Place `FeedbackButton` anywhere in your app -- typically in a settings screen:

```kotlin
@Composable
fun SettingsScreen() {
    Column {
        // ... other settings ...

        FeedbackButton(
            modifier = Modifier.padding(horizontal = 16.dp)
        )
    }
}
```

You can customize the button and sheet text:

```kotlin
FeedbackButton(
    icon = "\uD83D\uDC1B",
    title = "Found a bug?",
    subtitle = "Let us know so we can fix it",
    feedbackPlaceholder = "Tell us what happened...",
    sendButtonText = "Submit",
    successMessage = "Thanks! We'll look into it."
)
```

## How it works

1. User taps the feedback button
2. A modal bottom sheet slides up with a text field
3. User types their feedback and taps Send
4. The app POSTs the message to the Telegram Bot API (off the main thread via coroutines)
5. You receive it as a push notification in Telegram

The feedback message includes the app name, version, Android version, and timestamp automatically.

## Which channel should I use?

| Channel | Security | If credential leaks... |
|---|---|---|
| **Discord** | Best | Attacker can only post to one channel |
| **Slack** | Best | Same as Discord, plus auto-leak detection |
| **Telegram** | Good | Attacker gets full bot control |

## Security notes

- All credentials are stored as byte arrays, not plain strings. This prevents them from appearing in a basic `strings` dump of your APK.
- A 60-second cooldown prevents rapid re-sends. The cooldown persists across app restarts via SharedPreferences.
- Feedback text is capped at 2000 characters.
- This is obfuscation, not encryption. For Discord/Slack, a leak only allows posting to one channel. For Telegram, revoke and rotate the token via @BotFather if needed.
