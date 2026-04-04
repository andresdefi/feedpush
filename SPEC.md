# In-App Feedback System via Telegram Bot

## Goal

Create a reusable feedback module that lets users send feedback from any mobile app directly to a Telegram bot. No database, no backend server, no user accounts.

Must work across all platforms:
- **Swift** (iOS - SwiftUI)
- **Kotlin** (Android - Jetpack Compose)
- **Flutter/Dart** (iOS & Android)
- **React Native/TypeScript** (iOS & Android)

Each platform gets its own complete, independent, drop-in implementation.

---

## User Flow

1. User opens the app's settings screen (or wherever the button is placed).
2. They see a **"Give Feedback" card button** -- an icon, a title ("Have suggestions?"), a subtitle ("Share your ideas with us"), and a directional arrow.
3. They tap the button. A **sheet/modal** slides up over the current screen.
4. The sheet contains:
   - A multi-line text field for their feedback (2000-character limit, live counter)
   - A send button
   - A close/dismiss button
5. They type their feedback and tap "Send".
6. The app sends the message to a Telegram bot via the Telegram Bot API.
7. The developer receives the feedback instantly as a Telegram push notification.

---

## What Gets Sent in the Telegram Message

Each message is formatted with:

- **App name** (hardcoded per app)
- **App version** (read automatically from the app bundle/package)
- **OS version** (read automatically from the device)
- **Platform** (iOS or Android)
- **Feedback text** (what the user typed)
- **Timestamp** (UTC, when the feedback was sent)

Example messages:

```
📱 App: Flashlight Pro
📦 Version: 1.3.2
🤖 Platform: Android 15
🕐 Time: 2026-04-03 14:30 UTC

💬 Feedback:
The strobe mode flickers too fast. Would love a speed slider.
```

```
📱 App: Flooring Calculator
📦 Version: 2.1.0
🍎 Platform: iOS 18.4
🕐 Time: 2026-04-03 15:10 UTC

💬 Feedback:
Can you add support for hexagonal tiles?
```

## What NOT to Collect

- No device model
- No device UUID or unique identifiers
- No user name or user ID
- No analytics or tracking
- No screenshots

---

## Security & Abuse Prevention

### Token Obfuscation

The Telegram bot token must NOT be stored as a plain string literal. Each platform uses a simple encoding strategy to prevent the token from appearing in a basic `strings` dump of the binary:

| Platform | Storage | Decode |
|---|---|---|
| Swift | `[UInt8]` array | `String(bytes:encoding:.utf8)` at runtime |
| Kotlin | `ByteArray` | `String(byteArray, Charsets.UTF_8)` at runtime |
| Flutter/Dart | `List<int>` of char codes | `String.fromCharCodes()` at runtime |
| React Native/TS | `number[]` of char codes | `String.fromCharCode(...arr)` at runtime |

Each config file must include a comment explaining how to generate the encoded array from a plain token string.

This is obfuscation, not encryption. It stops casual extraction only. See "If the Token Gets Compromised" below.

### Rate Limiting (Client-Side Cooldown)

After a successful send, the app enforces a **60-second cooldown**:

- Store the timestamp of the last successful send in persistent local storage:
  - Swift: `UserDefaults`
  - Kotlin: `SharedPreferences`
  - Flutter: `shared_preferences`
  - React Native: `AsyncStorage`
- The cooldown survives app restarts
- While active, the send button is disabled and shows remaining time (e.g., "Send (42s)")
- This prevents accidental double-sends and casual spam. It is not a security measure -- it can be bypassed by a determined user.

### Character Limit

The feedback text field has a **2000-character limit**:

- Telegram messages max at 4096 characters. The metadata (app name, version, platform, timestamp) uses ~200-300 characters. 2000 keeps the total well within bounds.
- A live character counter is shown below the text field (e.g., "142 / 2000")
- The send button is disabled if the text is empty or exceeds 2000 characters

### Keyboard Dismissal

Tapping outside the text fields dismisses the keyboard on all platforms.

### If the Token Gets Compromised

1. Open @BotFather in Telegram
2. Revoke the old token (`/revoke`)
3. Generate a new one
4. Update the app with the new (obfuscated) token
5. Push an app update

Takes under 5 minutes. Worst case is spam messages in your Telegram chat -- no data, accounts, or systems are at risk.

---

## Technical Details

- Telegram Bot API endpoint: `https://api.telegram.org/bot<TOKEN>/sendMessage`
- Simple HTTP POST with `chat_id` and `text` parameters
- Bot token and chat ID stored in a dedicated config file, token obfuscated as described above
- No third-party dependencies except where noted per platform
- Each implementation is self-contained and drop-in ready

## Telegram Bot Setup (Done by Developer)

The developer creates the bot via @BotFather and provides:
- The bot token
- The chat ID (personal chat ID where messages arrive)

The implementation does not handle bot creation.

---

## File Structure Per Platform

Each platform lives in its own folder with four files:

```
/feedback-tool
  /swift
    FeedbackConfig.swift
    FeedbackService.swift
    FeedbackButton.swift
    FeedbackSheet.swift
    README.md
  /kotlin
    FeedbackConfig.kt
    FeedbackService.kt
    FeedbackButton.kt
    FeedbackSheet.kt
    README.md
  /flutter
    feedback_config.dart
    feedback_service.dart
    feedback_button.dart
    feedback_sheet.dart
    README.md
  /react-native
    FeedbackConfig.ts
    FeedbackService.ts
    FeedbackButton.tsx
    FeedbackSheet.tsx
    README.md
```

---

## Component Details Per Platform

### All Platforms -- FeedbackConfig

Holds three constants:
- **Bot token** (obfuscated as described above)
- **Chat ID** (plain string)
- **App name** (plain string, e.g., "Flooring Calculator")

Includes a function/property to decode the token at runtime.

### All Platforms -- FeedbackService

A single function: `sendFeedback(text)` that:
1. Reads app version and OS version from the system
2. Formats the Telegram message string with all fields
3. POSTs to the Telegram Bot API
4. Returns success or throws/returns an error

Networking:
- Swift: `URLSession` with `async/await`
- Kotlin: `HttpURLConnection` with coroutines (off main thread)
- Flutter: `http` package
- React Native: native `fetch`

### All Platforms -- FeedbackButton

A card-style button component:
- Left side: icon (lightbulb or similar)
- Center: title ("Have suggestions?") and subtitle ("Share your ideas with us")
- Right side: directional arrow
- Card has rounded corners, subtle shadow
- Tapping it opens the FeedbackSheet

### All Platforms -- FeedbackSheet

A bottom sheet or modal presented over the current screen:
- **Multi-line text field** for feedback
  - 2000-character limit
  - Live character counter below (e.g., "142 / 2000")
- **Send button**
  - Disabled when: text is empty, text exceeds 2000 chars, send in progress, cooldown active
  - During cooldown: shows "Send (42s)" with countdown
- **Close/dismiss button** (X or system default)
- **States:**
  - Default: form ready
  - Sending: button disabled, loading indicator
  - Success: "Thank you!" message, form clears, cooldown starts, sheet auto-dismisses after ~2 seconds
  - Error: "Could not send feedback. Please check your connection and try again."
- Tapping outside text fields dismisses keyboard

---

## Platform-Specific Dependencies

| Platform | Dependencies |
|---|---|
| Swift | None (Foundation, SwiftUI only) |
| Kotlin | None (stdlib, Compose, coroutines only) |
| Flutter | `http`, `package_info_plus`, `shared_preferences` |
| React Native | `@react-native-async-storage/async-storage`, `expo-application` |

---

## READMEs

Each platform folder includes a README explaining:
1. How to copy the files into an existing project
2. How to generate the obfuscated token array from a plain token string
3. How to set the app name and chat ID
4. How to add the FeedbackButton to a settings screen
5. Any platform-specific setup (e.g., Flutter pubspec dependencies)

---

## Building Phases

### Phase 1: Swift (iOS)
Build the complete Swift implementation first since the impostor app is available for immediate testing.

- [ ] `FeedbackConfig.swift` -- obfuscated token, chat ID, app name
- [ ] `FeedbackService.swift` -- async/await URLSession POST to Telegram API
- [ ] `FeedbackButton.swift` -- card-style SwiftUI button
- [ ] `FeedbackSheet.swift` -- sheet with text field, send button, cooldown, character counter
- [ ] Test in impostor app (replace the existing mailto feedback with the new Telegram flow)
- [ ] `README.md`

### Phase 2: Kotlin (Android)
- [ ] `FeedbackConfig.kt` -- obfuscated token, chat ID, app name
- [ ] `FeedbackService.kt` -- HttpURLConnection with coroutines
- [ ] `FeedbackButton.kt` -- card-style Compose button
- [ ] `FeedbackSheet.kt` -- bottom sheet with text field, send button, cooldown, character counter
- [ ] Test in an Android project
- [ ] `README.md`

### Phase 3: Flutter
- [ ] `feedback_config.dart` -- obfuscated token, chat ID, app name
- [ ] `feedback_service.dart` -- http package POST
- [ ] `feedback_button.dart` -- card-style button widget
- [ ] `feedback_sheet.dart` -- modal bottom sheet with text field, send button, cooldown, character counter
- [ ] Test in a Flutter project
- [ ] `README.md`

### Phase 4: React Native (TypeScript)
- [ ] `FeedbackConfig.ts` -- obfuscated token, chat ID, app name
- [ ] `FeedbackService.ts` -- native fetch POST
- [ ] `FeedbackButton.tsx` -- card-style pressable component
- [ ] `FeedbackSheet.tsx` -- modal with text field, send button, cooldown, character counter
- [ ] Test in a React Native/Expo project
- [ ] `README.md`

### Phase 5: Final Review
- [ ] Verify all four implementations send identical Telegram message format
- [ ] Verify obfuscation works (run `strings` on a test binary, confirm token does not appear)
- [ ] Confirm cooldown persists across app restarts on each platform
- [ ] Confirm character limit is enforced on each platform
