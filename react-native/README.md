# FeedPush - React Native (TypeScript)

Drop-in feedback module for React Native / Expo apps. Users tap a button, type their feedback, and you receive it instantly via Telegram, Discord, or Slack.

## Requirements

- React Native 0.73+
- Expo SDK 50+
- TypeScript

## Dependencies

Install these packages:

```bash
npx expo install expo-application expo-haptics @react-native-async-storage/async-storage
```

## Setup

### 1. Add the files

Copy these files into your project (e.g., `src/feedback/`):

- `FeedbackConfig.ts`
- `FeedbackService.ts`
- `FeedbackButton.tsx`
- `FeedbackSheet.tsx`

Copy `FeedbackService.test.ts` alongside your other tests.

### 2. Choose your delivery channel

FeedPush supports Telegram, Discord, and Slack. See the Swift README for setup instructions per channel.

### 3. Generate the obfuscated credentials

```js
console.log(JSON.stringify([..."YOUR_TOKEN_OR_URL"].map(c => c.charCodeAt(0))))
```

### 4. Configure

Open `FeedbackConfig.ts` and set your channel and credentials:

```typescript
channel: "discord",  // or "telegram", "slack"

// For Telegram:
const tokenCodes: number[] = [49, 50, 51, ...];
chatID: "123456789",

// For Discord or Slack:
const webhookURLCodes: number[] = [104, 116, 116, ...];

appName: "My App",
```

### 5. Add the button to your app

Place `FeedbackButton` anywhere -- typically in a settings screen:

```tsx
import { FeedbackButton } from "../feedback/FeedbackButton";

function SettingsScreen() {
  return (
    <View>
      {/* ... other settings ... */}

      <FeedbackButton />
    </View>
  );
}
```

You can customize the button and sheet text:

```tsx
<FeedbackButton
  icon={"\u{1F41B}"}
  title="Found a bug?"
  subtitle="Let us know so we can fix it"
  feedbackPlaceholder="Tell us what happened..."
  sendButtonText="Submit"
  successMessage="Thanks! We'll look into it."
/>
```

## How it works

1. User taps the feedback button
2. A modal slides up with a text field and optional email field
3. User types their feedback and taps Send
4. The app POSTs the message to the Telegram Bot API using native `fetch`
5. You receive it as a push notification in Telegram

The feedback message includes the app name, version, platform (iOS/Android), and timestamp automatically.

## Security notes

- All credentials are stored as char code arrays, not plain strings. This prevents them from appearing in a basic `strings` dump of your bundle.
- A 60-second cooldown prevents rapid re-sends. The cooldown persists across app restarts via AsyncStorage.
- Feedback text is capped at 2000 characters.
- For Discord/Slack, a leak only allows posting to one channel. For Telegram, revoke via @BotFather if needed.
