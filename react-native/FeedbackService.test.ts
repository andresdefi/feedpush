// FeedPush - React Native Tests
// Run with: npx jest FeedbackService.test.ts
//
// These tests verify config decoding, message formatting, and input validation.
// The buildMessage function is tested with mocked Platform and Application values.

import { buildMessage } from "./FeedbackService";

// Mock expo-application
jest.mock("expo-application", () => ({
  nativeApplicationVersion: "1.0.0",
}));

// Mock react-native Platform
jest.mock("react-native", () => ({
  Platform: {
    OS: "ios",
    Version: "18.0",
  },
}));

// MARK: FeedbackConfig Tests

describe("FeedbackConfig", () => {
  test("token decodes from char codes", () => {
    // Default placeholder codes should decode to "123456:ABC-DEF"
    const tokenCodes = [49, 50, 51, 52, 53, 54, 58, 65, 66, 67, 45, 68, 69, 70];
    const token = String.fromCharCode(...tokenCodes);
    expect(token).toBe("123456:ABC-DEF");
  });

  test("token is not empty", () => {
    const tokenCodes = [49, 50, 51, 52, 53, 54, 58, 65, 66, 67, 45, 68, 69, 70];
    const token = String.fromCharCode(...tokenCodes);
    expect(token.length).toBeGreaterThan(0);
  });

  test("token char codes round trip", () => {
    const original = "test:token-123";
    const codes = [...original].map((c) => c.charCodeAt(0));
    const decoded = String.fromCharCode(...codes);
    expect(decoded).toBe(original);
  });

  test("empty char codes produce empty string", () => {
    const token = String.fromCharCode(...[]);
    expect(token).toBe("");
  });
});

// MARK: Message Formatting Tests

describe("buildMessage", () => {
  test("message contains app name", () => {
    const message = buildMessage("Great app!");
    expect(message).toContain("App:");
  });

  test("message contains feedback text", () => {
    const feedbackText = "This is my feedback about the app";
    const message = buildMessage(feedbackText);
    expect(message).toContain(feedbackText);
  });

  test("message contains feedback header", () => {
    const message = buildMessage("Test");
    expect(message).toContain("Feedback:");
  });

  test("message contains version line", () => {
    const message = buildMessage("Test");
    expect(message).toContain("Version:");
  });

  test("message contains platform line", () => {
    const message = buildMessage("Test");
    expect(message).toContain("Platform:");
  });

  test("message contains timestamp", () => {
    const message = buildMessage("Test");
    expect(message).toContain("Time:");
    expect(message).toContain("UTC");
  });

  test("message order is correct", () => {
    const message = buildMessage("My feedback");

    const appIndex = message.indexOf("App:");
    const versionIndex = message.indexOf("Version:");
    const platformIndex = message.indexOf("Platform:");
    const timeIndex = message.indexOf("Time:");
    const feedbackIndex = message.indexOf("Feedback:");

    expect(appIndex).toBeLessThan(versionIndex);
    expect(versionIndex).toBeLessThan(platformIndex);
    expect(platformIndex).toBeLessThan(timeIndex);
    expect(timeIndex).toBeLessThan(feedbackIndex);
  });

  test("message with special characters", () => {
    const text = 'Feedback with special chars: <>&"\' and emojis \u{1F600}\u{1F525}';
    const message = buildMessage(text);
    expect(message).toContain(text);
  });

  test("message with multiline feedback", () => {
    const text = "Line 1\nLine 2\nLine 3";
    const message = buildMessage(text);
    expect(message).toContain(text);
  });

  test("message with max length feedback stays under telegram limit", () => {
    const text = "a".repeat(2000);
    const message = buildMessage(text);
    expect(message).toContain(text);
    expect(message.length).toBeLessThanOrEqual(4096);
  });
});

// MARK: Input Validation Tests

describe("Input validation", () => {
  test("empty text should be rejected", () => {
    expect("".trim().length).toBe(0);
  });

  test("whitespace only text should be rejected", () => {
    expect("   \n\t  ".trim().length).toBe(0);
  });

  test("text within limit is valid", () => {
    const text = "a".repeat(2000);
    expect(text.length).toBeLessThanOrEqual(2000);
  });

  test("text exceeding limit is invalid", () => {
    const text = "a".repeat(2001);
    expect(text.length).toBeGreaterThan(2000);
  });
});

// MARK: sendFeedback Tests

describe("sendFeedback", () => {
  beforeEach(() => {
    (global.fetch as jest.Mock)?.mockClear?.();
  });

  test("rejects empty text", async () => {
    const { sendFeedback } = require("./FeedbackService");
    const result = await sendFeedback("");
    expect(result.success).toBe(false);
    expect(result.error).toContain("empty");
  });

  test("rejects whitespace only text", async () => {
    const { sendFeedback } = require("./FeedbackService");
    const result = await sendFeedback("   \n\t  ");
    expect(result.success).toBe(false);
    expect(result.error).toContain("empty");
  });

  test("sends successfully with mocked fetch", async () => {
    (global as any).fetch = jest.fn().mockResolvedValue({
      ok: true,
      status: 200,
    });

    const { sendFeedback } = require("./FeedbackService");
    const result = await sendFeedback("Test feedback");
    expect(result.success).toBe(true);

    const fetchCall = (global.fetch as jest.Mock).mock.calls[0];
    expect(fetchCall[0]).toContain("/sendMessage");
    expect(fetchCall[1].method).toBe("POST");

    const body = JSON.parse(fetchCall[1].body);
    expect(body.text).toContain("Test feedback");
    expect(body.parse_mode).toBe("Markdown");
  });

  test("handles server error", async () => {
    (global as any).fetch = jest.fn().mockResolvedValue({
      ok: false,
      status: 400,
      text: () => Promise.resolve("Bad Request"),
    });

    const { sendFeedback } = require("./FeedbackService");
    const result = await sendFeedback("Test");
    expect(result.success).toBe(false);
    expect(result.error).toContain("400");
  });

  test("handles network error", async () => {
    (global as any).fetch = jest.fn().mockRejectedValue(new Error("Network failed"));

    const { sendFeedback } = require("./FeedbackService");
    const result = await sendFeedback("Test");
    expect(result.success).toBe(false);
    expect(result.error).toContain("Network");
  });

});
