import { Platform } from "react-native";
import * as Application from "expo-application";
import { FeedbackConfig } from "./FeedbackConfig";

// FeedbackService
// Sends feedback to a Telegram bot using the Telegram Bot API.
// Uses native `fetch` -- no third-party networking dependencies.

export type FeedbackResult =
  | { success: true }
  | { success: false; error: string };

/**
 * Sends feedback to the configured Telegram bot.
 *
 * @param text - The feedback message (max 2000 characters)
 * @param email - Optional email for follow-up
 * @returns FeedbackResult indicating success or failure
 */
export async function sendFeedback(
  text: string,
  email?: string
): Promise<FeedbackResult> {
  const trimmed = text.trim();
  if (!trimmed) {
    return { success: false, error: "Feedback text cannot be empty." };
  }

  const message = buildMessage(trimmed, email);
  const token = FeedbackConfig.botToken;
  const url = `https://api.telegram.org/bot${token}/sendMessage`;

  try {
    const response = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        chat_id: FeedbackConfig.chatID,
        text: message,
        parse_mode: "Markdown",
      }),
    });

    if (response.ok) {
      return { success: true };
    }

    const body = await response.text();
    return {
      success: false,
      error: `Telegram API error (${response.status}): ${body}`,
    };
  } catch (e) {
    const errorMessage =
      e instanceof Error ? e.message : "Unknown error";
    return { success: false, error: `Network error: ${errorMessage}` };
  }
}

// Visible for testing
export function buildMessage(text: string, email?: string): string {
  const appName = FeedbackConfig.appName;
  const appVersion =
    Application.nativeApplicationVersion ?? "Unknown";

  const platformName = Platform.OS === "ios" ? "iOS" : "Android";
  const osVersion = Platform.Version;
  const platformEmoji = Platform.OS === "ios" ? "\u{1F34E}" : "\u{1F916}";

  const now = new Date();
  const pad = (n: number) => n.toString().padStart(2, "0");
  const timestamp = `${now.getUTCFullYear()}-${pad(now.getUTCMonth() + 1)}-${pad(now.getUTCDate())} ${pad(now.getUTCHours())}:${pad(now.getUTCMinutes())}`;

  const emailValue = email?.trim() ?? "";
  const emailLine = emailValue
    ? `\n\u{1F4E7} Email: ${emailValue}`
    : `\n\u{1F4E7} Email: (not provided)`;

  return [
    `\u{1F4F1} App: ${appName}`,
    `\u{1F4E6} Version: ${appVersion}`,
    `${platformEmoji} Platform: ${platformName} ${osVersion}`,
    `\u{1F554} Time: ${timestamp} UTC`,
    "",
    `\u{1F4AC} Feedback:`,
    text,
    emailLine,
  ].join("\n");
}
