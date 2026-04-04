// FeedbackChannel
// The delivery channel for feedback messages.

export type FeedbackChannel = "telegram" | "discord" | "slack" | "proxy";

// FeedbackConfig
// Holds the delivery channel, credentials, and app name.
//
// TELEGRAM SETUP:
// 1. Create a bot via @BotFather on Telegram
// 2. Generate the obfuscated token char codes:
//    console.log(JSON.stringify([..."YOUR_BOT_TOKEN"].map(c => c.charCodeAt(0))))
// 3. Paste the array into `tokenCodes` and set your `chatID`
//
// DISCORD SETUP:
// 1. In your Discord server, go to Channel Settings > Integrations > Webhooks
// 2. Create a webhook and copy the URL
// 3. Generate the obfuscated URL char codes using the same command with your webhook URL
// 4. Paste the array into `webhookURLCodes`
//
// SLACK SETUP:
// 1. Create a Slack app at api.slack.com/apps
// 2. Enable Incoming Webhooks and create one for your channel
// 3. Generate the obfuscated URL char codes using the same command with your webhook URL
// 4. Paste the array into `webhookURLCodes`
//
// PROXY SETUP (recommended - most secure option):
// 1. Deploy the proxy worker from proxy/README.md
// 2. Set `proxyURL` to your deployed worker URL
// 3. The proxy handles message formatting and credential storage,
//    so no tokens or webhook URLs are needed in the app binary

// MARK: Telegram Configuration

// Obfuscated bot token (only needed for "telegram")
const tokenCodes: number[] = [
  // Example: these codes decode to "123456:ABC-DEF"
  49, 50, 51, 52, 53, 54, 58, 65, 66, 67, 45, 68, 69, 70,
];

// MARK: Discord / Slack Configuration

// Obfuscated webhook URL (only needed for "discord" or "slack")
const webhookURLCodes: number[] = [
  // Paste your obfuscated webhook URL char codes here
];

export const FeedbackConfig = {
  // Which channel to use for sending feedback
  channel: "telegram" as FeedbackChannel,

  // Telegram chat ID where feedback messages will arrive (only needed for "telegram")
  chatID: "YOUR_CHAT_ID",

  // The name of your app (shown in the feedback message)
  appName: "My App",

  // Proxy URL (only needed for "proxy")
  proxyURL: "https://your-proxy.workers.dev/feedback",

  // Decoded values
  get botToken(): string {
    return String.fromCharCode(...tokenCodes);
  },

  get webhookURL(): string {
    return String.fromCharCode(...webhookURLCodes);
  },
} as const;
