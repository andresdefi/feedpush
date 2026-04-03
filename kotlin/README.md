# FeedPush - Kotlin (Android)

Drop-in feedback module for Jetpack Compose apps. Users tap a button, type their feedback, and you receive it instantly via Telegram.

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

### 3. Create your Telegram bot

1. Open Telegram and message [@BotFather](https://t.me/BotFather)
2. Send `/newbot` and follow the prompts
3. Copy the bot token you receive
4. To get your chat ID, message [@userinfobot](https://t.me/userinfobot) -- it will reply with your ID

### 4. Generate the obfuscated token

Run in a Kotlin scratch file or terminal:

```kotlin
kotlin -e 'val t = "YOUR_BOT_TOKEN_HERE"; println(t.toByteArray().joinToString(", ") { it.toString() })'
```

This outputs bytes like `49, 50, 51, ...`. Copy this output.

### 5. Configure

Open `FeedbackConfig.kt` and set:

```kotlin
private val tokenBytes: ByteArray = byteArrayOf(49, 50, 51, ...)

const val chatID: String = "123456789"

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
2. A modal bottom sheet slides up with a text field and optional email field
3. User types their feedback and taps Send
4. The app POSTs the message to the Telegram Bot API (off the main thread via coroutines)
5. You receive it as a push notification in Telegram

The feedback message includes the app name, version, Android version, and timestamp automatically.

## Security notes

- The bot token is stored as a `ByteArray`, not a plain string. This prevents it from appearing in a basic `strings` dump of your APK.
- A 60-second cooldown prevents rapid re-sends. The cooldown persists across app restarts via SharedPreferences.
- Feedback text is capped at 2000 characters.
- This is obfuscation, not encryption. If someone decompiles your APK and actively reverse-engineers it, they can recover the token. The risk is low -- worst case is spam in your Telegram chat. Revoke and rotate the token via @BotFather if needed.
