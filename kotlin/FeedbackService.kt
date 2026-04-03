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
// Sends feedback to a Telegram bot using the Telegram Bot API.
// Uses native HttpURLConnection with coroutines -- no third-party dependencies.

sealed class FeedbackResult {
    data object Success : FeedbackResult()
    data class Error(val message: String) : FeedbackResult()
}

object FeedbackService {

    /**
     * Sends feedback to the configured Telegram bot.
     * Runs on Dispatchers.IO automatically.
     *
     * @param context Android context (for reading app version)
     * @param text The feedback message (max 2000 characters)
     * @param email Optional email for follow-up
     */
    suspend fun send(context: Context, text: String, email: String? = null): FeedbackResult {
        val trimmed = text.trim()
        if (trimmed.isEmpty()) return FeedbackResult.Error("Feedback text cannot be empty.")

        val message = buildMessage(context, trimmed, email)

        return withContext(Dispatchers.IO) {
            try {
                val token = FeedbackConfig.botToken()
                val url = URL("https://api.telegram.org/bot$token/sendMessage")
                val connection = url.openConnection() as HttpURLConnection

                connection.requestMethod = "POST"
                connection.setRequestProperty("Content-Type", "application/json")
                connection.doOutput = true
                connection.connectTimeout = 15_000
                connection.readTimeout = 15_000

                val body = JSONObject().apply {
                    put("chat_id", FeedbackConfig.chatID)
                    put("text", message)
                    put("parse_mode", "Markdown")
                }

                connection.outputStream.use { os ->
                    os.write(body.toString().toByteArray(Charsets.UTF_8))
                }

                val responseCode = connection.responseCode

                if (responseCode == 200) {
                    FeedbackResult.Success
                } else {
                    val errorBody = connection.errorStream?.let { stream ->
                        BufferedReader(InputStreamReader(stream)).use { it.readText() }
                    } ?: "Unknown error"
                    FeedbackResult.Error("Telegram API error ($responseCode): $errorBody")
                }
            } catch (e: Exception) {
                FeedbackResult.Error("Network error: ${e.localizedMessage ?: e.message ?: "Unknown error"}")
            }
        }
    }

    // Visible for testing
    internal fun buildMessage(context: Context?, text: String, email: String?): String {
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

        val emailValue = email?.trim() ?: ""
        val emailLine = if (emailValue.isEmpty()) {
            "\n\uD83D\uDCE7 Email: (not provided)"
        } else {
            "\n\uD83D\uDCE7 Email: $emailValue"
        }

        return buildString {
            appendLine("\uD83D\uDCF1 App: $appName")
            appendLine("\uD83D\uDCE6 Version: $appVersion")
            appendLine("\uD83E\uDD16 Platform: $platform")
            appendLine("\uD83D\uDD54 Time: $timestamp UTC")
            appendLine()
            appendLine("\uD83D\uDCAC Feedback:")
            append(text)
            append(emailLine)
        }
    }
}
