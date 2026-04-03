package com.feedpush

// MARK: FeedbackConfig
// Holds the Telegram bot token (obfuscated), chat ID, and app name.
//
// HOW TO GENERATE THE TOKEN BYTES:
// 1. Open a Kotlin scratch file, terminal with kotlinc, or use this one-liner:
//    kotlin -e 'val t = "YOUR_BOT_TOKEN"; println(t.toByteArray().joinToString(", ") { it.toString() })'
// 2. Copy the output and paste it into `tokenBytes` below.
//
// This prevents the token from appearing in a plain `strings` dump of your APK.
// It is NOT encryption -- just obfuscation to stop casual extraction.

object FeedbackConfig {

    // Replace with the output of the command above
    private val tokenBytes: ByteArray = byteArrayOf(
        // Example: these bytes decode to "123456:ABC-DEF"
        // Run the command above with your real token and paste the result here
        49, 50, 51, 52, 53, 54, 58, 65, 66, 67, 45, 68, 69, 70
    )

    // Your Telegram chat ID where feedback messages will arrive
    const val chatID: String = "YOUR_CHAT_ID"

    // The name of your app (shown in the Telegram message)
    const val appName: String = "My App"

    // Decodes the bot token at runtime
    fun botToken(): String = String(tokenBytes, Charsets.UTF_8)
}
