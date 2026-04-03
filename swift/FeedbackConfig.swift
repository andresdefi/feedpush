import Foundation

// MARK: - FeedbackConfig
// Holds the Telegram bot token (obfuscated), chat ID, and app name.
//
// HOW TO GENERATE THE TOKEN BYTES:
// 1. Open Terminal
// 2. Run: swift -e 'let t = "YOUR_BOT_TOKEN"; print(Array(t.utf8))'
// 3. Copy the output array and paste it into `tokenBytes` below
//
// This prevents the token from appearing in a plain `strings` dump of your binary.
// It is NOT encryption -- just obfuscation to stop casual extraction.

struct FeedbackConfig {

    // Replace with the output of the command above
    static let tokenBytes: [UInt8] = [
        // Example: these bytes decode to "123456:ABC-DEF"
        // Run the command above with your real token and paste the result here
        49, 50, 51, 52, 53, 54, 58, 65, 66, 67, 45, 68, 69, 70
    ]

    // Your Telegram chat ID where feedback messages will arrive
    static let chatID = "YOUR_CHAT_ID"

    // The name of your app (shown in the Telegram message)
    static let appName = "My App"

    // Decodes the bot token at runtime
    static var botToken: String {
        String(bytes: tokenBytes, encoding: .utf8) ?? ""
    }
}
