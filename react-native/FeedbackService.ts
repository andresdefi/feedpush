import { Platform } from "react-native";
import * as Application from "expo-application";
import { FeedbackConfig } from "./FeedbackConfig";

// FeedbackService
// Sends feedback via Telegram, Discord, Slack, or Proxy depending on FeedbackConfig.channel.
// Uses native `fetch` -- no third-party networking dependencies.

export type FeedbackResult =
  | { success: true }
  | { success: false; error: string };

export async function sendFeedback(
  text: string
): Promise<FeedbackResult> {
  const trimmed = text.trim();
  if (!trimmed) {
    return { success: false, error: "Feedback text cannot be empty." };
  }

  let url: string;
  let body: string;

  switch (FeedbackConfig.channel) {
    case "telegram": {
      const message = buildMessage(trimmed);
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
      const message = buildMessage(trimmed);
      url = FeedbackConfig.webhookURL;
      body = JSON.stringify({ content: message });
      break;
    }
    case "slack": {
      const message = buildMessage(trimmed);
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

export function buildMessage(text: string): string {
  const appName = FeedbackConfig.appName;
  const appVersion =
    Application.nativeApplicationVersion ?? "Unknown";

  const platformName = Platform.OS === "ios" ? "iOS" : "Android";
  const osVersion = Platform.Version;
  const platformEmoji = Platform.OS === "ios" ? "\u{1F34E}" : "\u{1F916}";

  const now = new Date();
  const pad = (n: number) => n.toString().padStart(2, "0");
  const timestamp = `${now.getUTCFullYear()}-${pad(now.getUTCMonth() + 1)}-${pad(now.getUTCDate())} ${pad(now.getUTCHours())}:${pad(now.getUTCMinutes())}`;

  return [
    `\u{1F4F1} App: ${appName}`,
    `\u{1F4E6} Version: ${appVersion}`,
    `${platformEmoji} Platform: ${platformName} ${osVersion}`,
    `\u{1F554} Time: ${timestamp} UTC`,
    "",
    `\u{1F4AC} Feedback:`,
    text,
  ].join("\n");
}
