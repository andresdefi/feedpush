package com.feedpush

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

// MARK: FeedbackConfig Tests

class FeedbackConfigTests {

    @Test
    fun `token decodes from bytes`() {
        // Default placeholder bytes should decode to "123456:ABC-DEF"
        val token = FeedbackConfig.botToken()
        assertEquals("123456:ABC-DEF", token)
    }

    @Test
    fun `token is not empty`() {
        assertTrue(FeedbackConfig.botToken().isNotEmpty())
    }

    @Test
    fun `token bytes round trip`() {
        val original = "test:token-123"
        val bytes = original.toByteArray(Charsets.UTF_8)
        val decoded = String(bytes, Charsets.UTF_8)
        assertEquals(original, decoded)
    }

    @Test
    fun `chat ID is set`() {
        assertTrue(FeedbackConfig.chatID.isNotEmpty())
    }

    @Test
    fun `app name is set`() {
        assertTrue(FeedbackConfig.appName.isNotEmpty())
    }
}

// MARK: FeedbackService Message Formatting Tests

class FeedbackServiceMessageTests {

    @Test
    fun `message contains app name`() {
        val message = FeedbackService.buildMessage(null, "Great app!", null)
        assertTrue(message.contains("App: ${FeedbackConfig.appName}"))
    }

    @Test
    fun `message contains feedback text`() {
        val feedbackText = "This is my feedback about the app"
        val message = FeedbackService.buildMessage(null, feedbackText, null)
        assertTrue(message.contains(feedbackText))
    }

    @Test
    fun `message contains feedback header`() {
        val message = FeedbackService.buildMessage(null, "Test", null)
        assertTrue(message.contains("Feedback:"))
    }

    @Test
    fun `message contains version line`() {
        val message = FeedbackService.buildMessage(null, "Test", null)
        assertTrue(message.contains("Version:"))
    }

    @Test
    fun `message contains platform line`() {
        val message = FeedbackService.buildMessage(null, "Test", null)
        assertTrue(message.contains("Platform:"))
        assertTrue(message.contains("Android"))
    }

    @Test
    fun `message contains timestamp`() {
        val message = FeedbackService.buildMessage(null, "Test", null)
        assertTrue(message.contains("Time:"))
        assertTrue(message.contains("UTC"))
    }

    @Test
    fun `message with no email shows not provided`() {
        val message = FeedbackService.buildMessage(null, "Test", null)
        assertTrue(message.contains("Email: (not provided)"))
    }

    @Test
    fun `message with empty email shows not provided`() {
        val message = FeedbackService.buildMessage(null, "Test", "")
        assertTrue(message.contains("Email: (not provided)"))
    }

    @Test
    fun `message with whitespace only email shows not provided`() {
        val message = FeedbackService.buildMessage(null, "Test", "   ")
        assertTrue(message.contains("Email: (not provided)"))
    }

    @Test
    fun `message with email shows email`() {
        val email = "user@example.com"
        val message = FeedbackService.buildMessage(null, "Test", email)
        assertTrue(message.contains("Email: $email"))
        assertFalse(message.contains("(not provided)"))
    }

    @Test
    fun `message with email with whitespace trims it`() {
        val message = FeedbackService.buildMessage(null, "Test", "  user@example.com  ")
        assertTrue(message.contains("Email: user@example.com"))
    }

    @Test
    fun `message order is correct`() {
        val message = FeedbackService.buildMessage(null, "My feedback", "a@b.com")

        val appIndex = message.indexOf("App:")
        val versionIndex = message.indexOf("Version:")
        val platformIndex = message.indexOf("Platform:")
        val timeIndex = message.indexOf("Time:")
        val feedbackIndex = message.indexOf("Feedback:")
        val emailIndex = message.indexOf("Email:")

        assertTrue(appIndex < versionIndex)
        assertTrue(versionIndex < platformIndex)
        assertTrue(platformIndex < timeIndex)
        assertTrue(timeIndex < feedbackIndex)
        assertTrue(feedbackIndex < emailIndex)
    }

    @Test
    fun `message with special characters in feedback`() {
        val text = "Feedback with special chars: <>&\"' and emojis \uD83D\uDE00\uD83D\uDD25"
        val message = FeedbackService.buildMessage(null, text, null)
        assertTrue(message.contains(text))
    }

    @Test
    fun `message with multiline feedback`() {
        val text = "Line 1\nLine 2\nLine 3"
        val message = FeedbackService.buildMessage(null, text, null)
        assertTrue(message.contains(text))
    }

    @Test
    fun `message with max length feedback stays under telegram limit`() {
        val text = "a".repeat(2000)
        val message = FeedbackService.buildMessage(null, text, null)
        assertTrue(message.contains(text))
        assertTrue(message.length <= 4096)
    }

    @Test
    fun `message with null context shows unknown version`() {
        val message = FeedbackService.buildMessage(null, "Test", null)
        assertTrue(message.contains("Version: Unknown"))
    }
}

// MARK: FeedbackConfig Channel Tests

class FeedbackConfigChannelTests {

    @Test
    fun `webhook URL decodes from bytes`() {
        val testURL = "https://discord.com/api/webhooks/123/abc"
        val bytes = testURL.toByteArray(Charsets.UTF_8)
        val decoded = String(bytes, Charsets.UTF_8)
        assertEquals(testURL, decoded)
    }

    @Test
    fun `channel is a valid enum value`() {
        val channel = FeedbackConfig.channel
        assertTrue(channel in FeedbackChannel.entries)
    }

    @Test
    fun `all channels are accessible`() {
        val channels = FeedbackChannel.entries
        assertEquals(3, channels.size)
        assertTrue(channels.contains(FeedbackChannel.TELEGRAM))
        assertTrue(channels.contains(FeedbackChannel.DISCORD))
        assertTrue(channels.contains(FeedbackChannel.SLACK))
    }
}

// MARK: FeedbackResult Tests

class FeedbackResultTests {

    @Test
    fun `success result is Success type`() {
        val result: FeedbackResult = FeedbackResult.Success
        assertTrue(result is FeedbackResult.Success)
    }

    @Test
    fun `error result contains message`() {
        val result = FeedbackResult.Error("Something went wrong")
        assertTrue(result is FeedbackResult.Error)
        assertEquals("Something went wrong", result.message)
    }

    @Test
    fun `error result with empty message`() {
        val result = FeedbackResult.Error("")
        assertEquals("", result.message)
    }
}
