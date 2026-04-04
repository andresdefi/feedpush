import Foundation

// MARK: - FeedbackChannel
// The delivery channel for feedback messages.

enum FeedbackChannel {
    case telegram
    case discord
    case slack
}

// MARK: - FeedbackConfig
// Holds the delivery channel, credentials, and app name.
//
// TELEGRAM SETUP:
// 1. Create a bot via @BotFather on Telegram
// 2. Generate the obfuscated token bytes:
//    swift -e 'let t = "YOUR_BOT_TOKEN"; print(Array(t.utf8))'
// 3. Paste the byte array into `tokenBytes` and set your `chatID`
//
// DISCORD SETUP:
// 1. In your Discord server, go to Channel Settings > Integrations > Webhooks
// 2. Create a webhook and copy the URL
// 3. Generate the obfuscated URL bytes:
//    swift -e 'let t = "YOUR_WEBHOOK_URL"; print(Array(t.utf8))'
// 4. Paste the byte array into `webhookURLBytes`
//
// SLACK SETUP:
// 1. Create a Slack app at api.slack.com/apps
// 2. Enable Incoming Webhooks and create one for your channel
// 3. Generate the obfuscated URL bytes:
//    swift -e 'let t = "YOUR_WEBHOOK_URL"; print(Array(t.utf8))'
// 4. Paste the byte array into `webhookURLBytes`

struct FeedbackConfig {

    // Which channel to use for sending feedback
    static let channel: FeedbackChannel = .telegram

    // MARK: - Telegram Configuration

    // Obfuscated bot token (only needed for .telegram)
    static let tokenBytes: [UInt8] = [
        // Example: these bytes decode to "123456:ABC-DEF"
        49, 50, 51, 52, 53, 54, 58, 65, 66, 67, 45, 68, 69, 70
    ]

    // Telegram chat ID where feedback messages will arrive (only needed for .telegram)
    static let chatID = "YOUR_CHAT_ID"

    // MARK: - Discord / Slack Configuration

    // Obfuscated webhook URL (only needed for .discord or .slack)
    static let webhookURLBytes: [UInt8] = [
        // Paste your obfuscated webhook URL bytes here
    ]

    // MARK: - App Info

    // The name of your app (shown in the feedback message)
    static let appName = "My App"

    // MARK: - Decoded Values

    static var botToken: String {
        String(bytes: tokenBytes, encoding: .utf8) ?? ""
    }

    static var webhookURL: String {
        String(bytes: webhookURLBytes, encoding: .utf8) ?? ""
    }
}
