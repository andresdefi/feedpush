// FeedbackConfig
// Holds the Telegram bot token (obfuscated), chat ID, and app name.
//
// HOW TO GENERATE THE TOKEN CHAR CODES:
// 1. Open a Node.js or browser console
// 2. Run: console.log(JSON.stringify([..."YOUR_BOT_TOKEN"].map(c => c.charCodeAt(0))))
// 3. Copy the output array and paste it into `tokenCodes` below
//
// This prevents the token from appearing in a plain `strings` dump of your bundle.
// It is NOT encryption -- just obfuscation to stop casual extraction.

const tokenCodes: number[] = [
  // Example: these codes decode to "123456:ABC-DEF"
  // Run the command above with your real token and paste the result here
  49, 50, 51, 52, 53, 54, 58, 65, 66, 67, 45, 68, 69, 70,
];

export const FeedbackConfig = {
  // Decodes the bot token at runtime
  get botToken(): string {
    return String.fromCharCode(...tokenCodes);
  },

  // Your Telegram chat ID where feedback messages will arrive
  chatID: "YOUR_CHAT_ID",

  // The name of your app (shown in the Telegram message)
  appName: "My App",
} as const;
