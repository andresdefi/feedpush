# FeedPush - Specification

## Goal

A drop-in feedback module for mobile apps. Users tap a button, type feedback, and the developer receives it instantly on their phone. No database, no backend server, no user accounts.

Supports four platforms:
- **Swift** (iOS - SwiftUI)
- **Kotlin** (Android - Jetpack Compose)
- **Flutter/Dart** (iOS & Android)
- **React Native/TypeScript** (iOS & Android)

Each platform is a standalone, independent implementation.

---

## Delivery Channels

FeedPush supports four delivery options:

| Channel | Security | Setup |
|---|---|---|
| **Proxy** (Recommended) | Best -- no secrets in the app | Deploy a Cloudflare Worker, set secrets server-side |
| **Discord webhook** | Good -- write-only, single channel | Create webhook in Discord channel settings |
| **Slack webhook** | Good -- write-only, single channel | Create Slack app with incoming webhook |
| **Telegram bot** | Acceptable -- token grants full bot control | Create bot via @BotFather |

The proxy option is the most secure: the app only knows a URL, and all credentials live on the server. Discord and Slack webhooks are write-only (an attacker can only post to one channel). Telegram is the simplest but the token grants broader access if compromised.

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
6. The app sends the feedback to the configured channel.
7. The developer receives the feedback instantly as a push notification.

---

## Message Format

Each message includes:

- **App name** (hardcoded per app)
- **App version** (read automatically from the app bundle/package)
- **Platform + OS version** (read automatically from the device)
- **Timestamp** (UTC)
- **Feedback text** (what the user typed)

Example:

```
📱 App: Flooring Calculator
📦 Version: 2.1.0
🍎 Platform: iOS 18.4
🕐 Time: 2026-04-03 15:10 UTC

💬 Feedback:
Can you add support for hexagonal tiles?
```

## What NOT to Collect

- No email addresses
- No device model
- No device UUID or unique identifiers
- No user name or user ID
- No analytics or tracking
- No screenshots

---

## Security & Abuse Prevention

### Credential Obfuscation (Direct Channels Only)

When using Telegram, Discord, or Slack directly (not via proxy), credentials must NOT be stored as plain string literals. Each platform uses a byte/char code array decoded at runtime:

| Platform | Storage | Decode |
|---|---|---|
| Swift | `[UInt8]` array | `String(bytes:encoding:.utf8)` at runtime |
| Kotlin | `ByteArray` | `String(byteArray, Charsets.UTF_8)` at runtime |
| Flutter/Dart | `List<int>` of char codes | `String.fromCharCodes()` at runtime |
| React Native/TS | `number[]` of char codes | `String.fromCharCode(...arr)` at runtime |

This is obfuscation, not encryption. It stops casual extraction only.

When using the proxy, no credentials exist in the app at all -- just the proxy URL.

### Server-Side Rate Limiting (Proxy Only)

The Cloudflare Worker proxy enforces rate limiting by IP (default: 5 requests per minute). This is the only enforceable rate limit -- client-side cooldowns can be bypassed.

### Client-Side Cooldown

After a successful send, the app enforces a **60-second cooldown**:

- Persisted in local storage (UserDefaults / SharedPreferences / shared_preferences / AsyncStorage)
- Survives app restarts
- Send button shows remaining time (e.g., "Send (42s)")
- Prevents accidental double-sends and casual spam

### Character Limit

Feedback text is capped at **2000 characters**. A live counter is shown below the text field.

### Keyboard Dismissal

Tapping outside the text field dismisses the keyboard on all platforms.

### If Credentials Are Compromised

**Proxy:** Change the proxy URL or add authentication. No app update needed for the credential rotation since secrets are server-side.

**Discord/Slack webhook:** Delete the webhook in channel settings. Create a new one, update the app.

**Telegram bot token:** Revoke via @BotFather (`/revoke`), generate a new one, update the app.

---

## Architecture

### Direct Mode (Telegram / Discord / Slack)

```
App  -->  Telegram API / Discord Webhook / Slack Webhook
```

The app holds obfuscated credentials and calls the service directly.

### Proxy Mode (Recommended)

```
App  -->  Cloudflare Worker  -->  Telegram / Discord / Slack
```

The app sends a JSON payload to the proxy. The proxy holds all credentials as environment secrets, validates the payload, rate limits by IP, formats the message, and forwards to the configured channel.

---

## File Structure

```
/feedpush
  /swift
    FeedbackConfig.swift
    FeedbackService.swift
    FeedbackButton.swift
    FeedbackSheet.swift
    FeedbackTests.swift
    README.md
  /kotlin
    FeedbackConfig.kt
    FeedbackService.kt
    FeedbackButton.kt
    FeedbackSheet.kt
    FeedbackTests.kt
    README.md
  /flutter
    feedback_config.dart
    feedback_service.dart
    feedback_button.dart
    feedback_sheet.dart
    feedback_test.dart
    README.md
  /react-native
    FeedbackConfig.ts
    FeedbackService.ts
    FeedbackButton.tsx
    FeedbackSheet.tsx
    FeedbackService.test.ts
    README.md
  /proxy
    src/worker.ts
    wrangler.toml
    package.json
    tsconfig.json
    README.md
```

---

## Component Details

### FeedbackConfig

Holds the delivery channel selection and credentials:
- **Channel** (proxy, telegram, discord, or slack)
- **Proxy URL** (for proxy mode)
- **Bot token / Webhook URL** (obfuscated, for direct modes)
- **Chat ID** (for Telegram only)
- **App name**

### FeedbackService

Routes feedback to the configured channel:
- **Proxy mode:** POSTs structured JSON (`app_name`, `app_version`, `platform`, `feedback`) to the proxy URL. The proxy handles formatting.
- **Direct mode:** Builds the formatted message locally and POSTs to the respective API.

### FeedbackButton

A card-style button with configurable icon, title, subtitle, and directional arrow. Tapping opens FeedbackSheet.

### FeedbackSheet

A bottom sheet or modal with:
- Multi-line text field (2000-char limit, live counter)
- Send button (disabled when empty, over limit, sending, or in cooldown)
- Close button
- Success: haptic feedback + "Thank you!" + auto-dismiss after 2 seconds
- Error: inline error message

---

## Platform-Specific Dependencies

| Platform | Dependencies |
|---|---|
| Swift | None (Foundation, SwiftUI only) |
| Kotlin | None (stdlib, Compose, coroutines only) |
| Flutter | `http`, `package_info_plus`, `shared_preferences` |
| React Native | `@react-native-async-storage/async-storage`, `expo-application`, `expo-haptics` |

---

## Proxy (Cloudflare Worker)

A lightweight TypeScript worker (~100 lines) that:
1. Accepts POST requests to `/feedback`
2. Validates the JSON payload
3. Rate limits by IP (configurable, default 5/min)
4. Formats the message with emojis and metadata
5. Forwards to Telegram, Discord, or Slack based on the `CHANNEL` environment variable
6. Returns `{ ok: true }` or an error

Credentials are stored as Cloudflare secrets (never in code):
- `CHANNEL` -- "telegram", "discord", or "slack"
- `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID` -- for Telegram
- `DISCORD_WEBHOOK_URL` -- for Discord
- `SLACK_WEBHOOK_URL` -- for Slack

---

## Build Status

All phases complete:
- [x] Phase 1: Swift (iOS)
- [x] Phase 2: Kotlin (Android)
- [x] Phase 3: Flutter
- [x] Phase 4: React Native
- [x] Phase 5: Multi-channel support (Telegram, Discord, Slack)
- [x] Phase 6: Proxy (Cloudflare Worker)
- [x] Phase 7: Email field removal
- [ ] Phase 8: Proxy as fourth delivery option in all platform modules
