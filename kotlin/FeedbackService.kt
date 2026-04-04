package com.feedpush

import android.content.Context
import android.os.Build
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

// MARK: FeedbackService
// Sends feedback via Telegram, Discord, or Slack depending on FeedbackConfig.channel.
// Uses native HttpURLConnection with coroutines -- no third-party dependencies.

sealed class FeedbackResult {
    data object Success : FeedbackResult()
    data class Error(val message: String) : FeedbackResult()
}

object FeedbackService {

    suspend fun send(context: Context, text: String): FeedbackResult {
        val trimmed = text.trim()
        if (trimmed.isEmpty()) return FeedbackResult.Error("Feedback text cannot be empty.")

        val message = buildMessage(context, trimmed)

        return withContext(Dispatchers.IO) {
            try {
                val (url, body) = when (FeedbackConfig.channel) {
                    FeedbackChannel.TELEGRAM -> buildTelegramPayload(message)
                    FeedbackChannel.DISCORD -> buildDiscordPayload(message)
                    FeedbackChannel.SLACK -> buildSlackPayload(message)
                }

                val connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "POST"
                connection.setRequestProperty("Content-Type", "application/json")
                connection.doOutput = true
                connection.connectTimeout = 15_000
                connection.readTimeout = 15_000

                connection.outputStream.use { os ->
                    os.write(body.toString().toByteArray(Charsets.UTF_8))
                }

                val responseCode = connection.responseCode

                // Discord returns 204 No Content on success
                if (responseCode in 200..299) {
                    FeedbackResult.Success
                } else {
                    val errorBody = connection.errorStream?.let { stream ->
                        BufferedReader(InputStreamReader(stream)).use { it.readText() }
                    } ?: "Unknown error"
                    FeedbackResult.Error("API error ($responseCode): $errorBody")
                }
            } catch (e: Exception) {
                FeedbackResult.Error("Network error: ${e.localizedMessage ?: e.message ?: "Unknown error"}")
            }
        }
    }

    // MARK: Payload Builders

    private fun buildTelegramPayload(message: String): Pair<URL, JSONObject> {
        val token = FeedbackConfig.botToken()
        val url = URL("https://api.telegram.org/bot$token/sendMessage")
        val body = JSONObject().apply {
            put("chat_id", FeedbackConfig.chatID)
            put("text", message)
            put("parse_mode", "Markdown")
        }
        return url to body
    }

    private fun buildDiscordPayload(message: String): Pair<URL, JSONObject> {
        val url = URL(FeedbackConfig.webhookURL())
        val body = JSONObject().apply {
            put("content", message)
        }
        return url to body
    }

    private fun buildSlackPayload(message: String): Pair<URL, JSONObject> {
        val url = URL(FeedbackConfig.webhookURL())
        val body = JSONObject().apply {
            put("text", message)
        }
        return url to body
    }

    // MARK: Message Formatting

    internal fun buildMessage(context: Context?, text: String): String {
        val appName = FeedbackConfig.appName

        val appVersion = try {
            context?.packageManager?.getPackageInfo(context.packageName, 0)?.versionName ?: "Unknown"
        } catch (_: Exception) {
            "Unknown"
        }

        val platform = "Android ${Build.VERSION.RELEASE}"

        val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.US)
        formatter.timeZone = TimeZone.getTimeZone("UTC")
        val timestamp = formatter.format(Date())

        return buildString {
            appendLine("\uD83D\uDCF1 App: $appName")
            appendLine("\uD83D\uDCE6 Version: $appVersion")
            appendLine("\uD83E\uDD16 Platform: $platform")
            appendLine("\uD83D\uDD54 Time: $timestamp UTC")
            appendLine()
            appendLine("\uD83D\uDCAC Feedback:")
            append(text)
        }
    }
}
