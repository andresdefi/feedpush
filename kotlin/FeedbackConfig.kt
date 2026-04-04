package com.feedpush

// MARK: FeedbackChannel
// The delivery channel for feedback messages.

enum class FeedbackChannel {
    TELEGRAM,
    DISCORD,
    SLACK
}

// MARK: FeedbackConfig
// Holds the delivery channel, credentials, and app name.
//
// TELEGRAM SETUP:
// 1. Create a bot via @BotFather on Telegram
// 2. Generate the obfuscated token bytes:
//    kotlin -e 'val t = "YOUR_BOT_TOKEN"; println(t.toByteArray().joinToString(", ") { it.toString() })'
// 3. Paste the byte array into `tokenBytes` and set your `chatID`
//
// DISCORD SETUP:
// 1. In your Discord server, go to Channel Settings > Integrations > Webhooks
// 2. Create a webhook and copy the URL
// 3. Generate the obfuscated URL bytes using the same command with your webhook URL
// 4. Paste the byte array into `webhookURLBytes`
//
// SLACK SETUP:
// 1. Create a Slack app at api.slack.com/apps
// 2. Enable Incoming Webhooks and create one for your channel
// 3. Generate the obfuscated URL bytes using the same command with your webhook URL
// 4. Paste the byte array into `webhookURLBytes`

object FeedbackConfig {

    // Which channel to use for sending feedback
    val channel: FeedbackChannel = FeedbackChannel.TELEGRAM

    // MARK: Telegram Configuration

    // Obfuscated bot token (only needed for TELEGRAM)
    private val tokenBytes: ByteArray = byteArrayOf(
        // Example: these bytes decode to "123456:ABC-DEF"
        49, 50, 51, 52, 53, 54, 58, 65, 66, 67, 45, 68, 69, 70
    )

    // Telegram chat ID where feedback messages will arrive (only needed for TELEGRAM)
    const val chatID: String = "YOUR_CHAT_ID"

    // MARK: Discord / Slack Configuration

    // Obfuscated webhook URL (only needed for DISCORD or SLACK)
    private val webhookURLBytes: ByteArray = byteArrayOf(
        // Paste your obfuscated webhook URL bytes here
    )

    // MARK: App Info

    // The name of your app (shown in the feedback message)
    const val appName: String = "My App"

    // MARK: Decoded Values

    fun botToken(): String = String(tokenBytes, Charsets.UTF_8)

    fun webhookURL(): String = String(webhookURLBytes, Charsets.UTF_8)
}
