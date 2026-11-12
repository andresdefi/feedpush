import { Platform } from "react-native";
import * as Application from "expo-application";
import { FeedbackConfig } from "./FeedbackConfig";

// FeedbackService
// Sends feedback via Telegram, Discord, Slack, or Proxy depending on FeedbackConfig.channel.
// Uses native `fetch` -- no third-party networking dependencies.

export type FeedbackResult =
  | { success: true }
  | { success: false; error: string };

// A plain address: no spaces or backticks (it is shown inside a Markdown code
// span), one @ and a dot after it. The proxy checks the same.
const EMAIL_PATTERN = /^[^\s@`]+@[^\s@`]+\.[^\s@`]+$/;

export function isValidEmail(email: string): boolean {
  const trimmed = email.trim();
  return trimmed.length <= 254 && EMAIL_PATTERN.test(trimmed);
}

/** `email` is an optional reply address, only when the user wants an answer; blank = none. */
export async function sendFeedback(
  text: string,
  category?: string,
  email?: string
): Promise<FeedbackResult> {
  const trimmed = text.trim();
  if (!trimmed) {
    return { success: false, error: "Feedback text cannot be empty." };
  }
  const replyTo = email?.trim() || undefined;
  if (replyTo && !isValidEmail(replyTo)) {
    return { success: false, error: "The email address doesn't look right." };
  }

  let url: string;
  let body: string;

  switch (FeedbackConfig.channel) {
    case "telegram": {
      const message = buildMessage(trimmed, category, replyTo);
      const token = FeedbackConfig.botToken;
      url = `https://api.telegram.org/bot${token}/sendMessage`;
      body = JSON.stringify({
        chat_id: FeedbackConfig.chatID,
        text: message,
        parse_mode: "Markdown",
      });
      break;
    }
    case "discord": {
      const message = buildMessage(trimmed, category, replyTo);
      url = FeedbackConfig.webhookURL;
      body = JSON.stringify({ content: message });
      break;
    }
    case "slack": {
      const message = buildMessage(trimmed, category, replyTo);
      url = FeedbackConfig.webhookURL;
      body = JSON.stringify({ text: message });
      break;
    }
    case "proxy": {
      const appVersion =
        Application.nativeApplicationVersion ?? "Unknown";
      const platformName = Platform.OS === "ios" ? "iOS" : "Android";
      const osVersion = Platform.Version;

      url = FeedbackConfig.proxyURL;
      body = JSON.stringify({
        app_name: FeedbackConfig.appName,
        app_version: appVersion,
        platform: `${platformName} ${osVersion}`,
        feedback: trimmed,
        ...(category && category.trim() ? { category } : {}),
        ...(replyTo ? { email: replyTo } : {}),
      });
      break;
    }
  }

  try {
    const response = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body,
    });

    // Discord returns 204 No Content on success
    if (response.ok) {
      return { success: true };
    }

    const responseBody = await response.text();
    return {
      success: false,
      error: `API error (${response.status}): ${responseBody}`,
    };
  } catch (e) {
    const errorMessage =
      e instanceof Error ? e.message : "Unknown error";
    return { success: false, error: `Network error: ${errorMessage}` };
  }
}

export function buildMessage(text: string, category?: string, email?: string): string {
  const appName = FeedbackConfig.appName;
  const appVersion =
    Application.nativeApplicationVersion ?? "Unknown";

  const platformName = Platform.OS === "ios" ? "iOS" : "Android";
  const osVersion = Platform.Version;
  const platformEmoji = Platform.OS === "ios" ? "\u{1F34E}" : "\u{1F916}";

  const now = new Date();
  const pad = (n: number) => n.toString().padStart(2, "0");
  const timestamp = `${now.getUTCFullYear()}-${pad(now.getUTCMonth() + 1)}-${pad(now.getUTCDate())} ${pad(now.getUTCHours())}:${pad(now.getUTCMinutes())}`;

  const lines = [
    `\u{1F4F1} App: ${appName}`,
    `\u{1F4E6} Version: ${appVersion}`,
    `${platformEmoji} Platform: ${platformName} ${osVersion}`,
    `\u{1F554} Time: ${timestamp} UTC`,
  ];

  if (category && category.trim()) {
    lines.push(`\u{1F3F7}\u{FE0F} Type: ${category}`);
  }

  // In a code span: Markdown can't break on "_", and it copies in one tap.
  if (email && email.trim()) {
    lines.push(`\u{2709}\u{FE0F} Reply to: \`${email.trim()}\``);
  }

  lines.push("", `\u{1F4AC} Feedback:`, text);

  return lines.join("\n");
}
