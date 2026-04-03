# FeedPush - React Native (TypeScript)

Drop-in feedback module for React Native / Expo apps. Users tap a button, type their feedback, and you receive it instantly via Telegram.

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

### 2. Create your Telegram bot

1. Open Telegram and message [@BotFather](https://t.me/BotFather)
2. Send `/newbot` and follow the prompts
3. Copy the bot token you receive
4. To get your chat ID, message [@userinfobot](https://t.me/userinfobot) -- it will reply with your ID

### 3. Generate the obfuscated token

Run in a Node.js or browser console:

```js
console.log(JSON.stringify([..."YOUR_BOT_TOKEN_HERE"].map(c => c.charCodeAt(0))))
```

This outputs an array like `[49,50,51,...]`. Copy this array.

### 4. Configure

Open `FeedbackConfig.ts` and set:

```typescript
const tokenCodes: number[] = [49, 50, 51, ...];

chatID: "123456789",

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

- The bot token is stored as an array of char codes, not a plain string. This prevents it from appearing in a basic `strings` dump of your bundle.
- A 60-second cooldown prevents rapid re-sends. The cooldown persists across app restarts via AsyncStorage.
- Feedback text is capped at 2000 characters.
- This is obfuscation, not encryption. If someone reverse-engineers your app bundle, they can recover the token. The risk is low -- worst case is spam in your Telegram chat. Revoke and rotate the token via @BotFather if needed.
