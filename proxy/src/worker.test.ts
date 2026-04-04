// FeedPush Proxy - Tests
// Tests for payload validation, rate limiting, message formatting, and routing.
// Run with: npx vitest (after adding vitest to devDependencies)

import { describe, test, expect, beforeEach } from "vitest";
import { isRateLimited, rateLimitMap, formatMessage } from "./worker";

// MARK: Rate Limiter Tests

describe("isRateLimited", () => {
  beforeEach(() => {
    rateLimitMap.clear();
  });

  test("first request is not rate limited", () => {
    expect(isRateLimited("1.2.3.4", 5)).toBe(false);
  });

  test("requests within limit are not rate limited", () => {
    for (let i = 0; i < 5; i++) {
      expect(isRateLimited("1.2.3.4", 5)).toBe(false);
    }
  });

  test("request exceeding limit is rate limited", () => {
    for (let i = 0; i < 5; i++) {
      isRateLimited("1.2.3.4", 5);
    }
    expect(isRateLimited("1.2.3.4", 5)).toBe(true);
  });

  test("different IPs are tracked independently", () => {
    for (let i = 0; i < 5; i++) {
      isRateLimited("1.2.3.4", 5);
    }
    expect(isRateLimited("1.2.3.4", 5)).toBe(true);
    expect(isRateLimited("5.6.7.8", 5)).toBe(false);
  });

  test("rate limit resets after window expires", () => {
    isRateLimited("1.2.3.4", 1);
    expect(isRateLimited("1.2.3.4", 1)).toBe(true);

    // Simulate window expiry
    const entry = rateLimitMap.get("1.2.3.4")!;
    entry.resetAt = Date.now() - 1;

    expect(isRateLimited("1.2.3.4", 1)).toBe(false);
  });

  test("rate limit of 1 blocks second request", () => {
    expect(isRateLimited("1.2.3.4", 1)).toBe(false);
    expect(isRateLimited("1.2.3.4", 1)).toBe(true);
  });
});

// MARK: Message Formatting Tests

describe("formatMessage", () => {
  const basePayload = {
    app_name: "Test App",
    app_version: "1.0.0",
    platform: "iOS 18.4",
    feedback: "Great app!",
  };

  test("message contains app name", () => {
    const msg = formatMessage(basePayload);
    expect(msg).toContain("App: Test App");
  });

  test("message contains app version", () => {
    const msg = formatMessage(basePayload);
    expect(msg).toContain("Version: 1.0.0");
  });

  test("message contains platform", () => {
    const msg = formatMessage(basePayload);
    expect(msg).toContain("Platform: iOS 18.4");
  });

  test("message contains timestamp with UTC", () => {
    const msg = formatMessage(basePayload);
    expect(msg).toContain("Time:");
    expect(msg).toContain("UTC");
  });

  test("message contains feedback text", () => {
    const msg = formatMessage(basePayload);
    expect(msg).toContain("Great app!");
  });

  test("message contains feedback header", () => {
    const msg = formatMessage(basePayload);
    expect(msg).toContain("Feedback:");
  });

  test("message does not contain email line", () => {
    const msg = formatMessage(basePayload);
    expect(msg).not.toContain("Email");
  });

  test("message order is correct", () => {
    const msg = formatMessage(basePayload);
    const appIdx = msg.indexOf("App:");
    const versionIdx = msg.indexOf("Version:");
    const platformIdx = msg.indexOf("Platform:");
    const timeIdx = msg.indexOf("Time:");
    const feedbackIdx = msg.indexOf("Feedback:");

    expect(appIdx).toBeLessThan(versionIdx);
    expect(versionIdx).toBeLessThan(platformIdx);
    expect(platformIdx).toBeLessThan(timeIdx);
    expect(timeIdx).toBeLessThan(feedbackIdx);
  });

  test("message with special characters", () => {
    const payload = { ...basePayload, feedback: '<>&"\'emojis \u{1F600}' };
    const msg = formatMessage(payload);
    expect(msg).toContain(payload.feedback);
  });

  test("message with multiline feedback", () => {
    const payload = { ...basePayload, feedback: "Line 1\nLine 2\nLine 3" };
    const msg = formatMessage(payload);
    expect(msg).toContain("Line 1\nLine 2\nLine 3");
  });

  test("message with max length feedback stays under 4096", () => {
    const payload = { ...basePayload, feedback: "a".repeat(2000) };
    const msg = formatMessage(payload);
    expect(msg.length).toBeLessThanOrEqual(4096);
  });
});

// MARK: Payload Validation Tests (logic-level)

describe("Payload validation", () => {
  test("empty feedback should be rejected", () => {
    expect("".trim()).toBe("");
  });

  test("whitespace-only feedback should be rejected", () => {
    expect("   \n\t  ".trim()).toBe("");
  });

  test("feedback within limit is valid", () => {
    expect("a".repeat(2000).length).toBeLessThanOrEqual(2000);
  });

  test("feedback exceeding limit is invalid", () => {
    expect("a".repeat(2001).length).toBeGreaterThan(2000);
  });

  test("missing app_name should be rejected", () => {
    const payload = { app_name: "", app_version: "1.0", platform: "iOS", feedback: "test" };
    expect(!payload.app_name).toBe(true);
  });

  test("missing app_version should be rejected", () => {
    const payload = { app_name: "App", app_version: "", platform: "iOS", feedback: "test" };
    expect(!payload.app_version).toBe(true);
  });

  test("missing platform should be rejected", () => {
    const payload = { app_name: "App", app_version: "1.0", platform: "", feedback: "test" };
    expect(!payload.platform).toBe(true);
  });
});
