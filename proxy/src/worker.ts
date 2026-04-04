// FeedPush Proxy - Cloudflare Worker
// Receives feedback from mobile apps, rate limits by IP,
// and forwards to Telegram, Discord, or Slack.
// Credentials never leave this worker.

interface Env {
  CHANNEL: string; // "telegram", "discord", or "slack"
  TELEGRAM_BOT_TOKEN?: string;
  TELEGRAM_CHAT_ID?: string;
  DISCORD_WEBHOOK_URL?: string;
  SLACK_WEBHOOK_URL?: string;
  RATE_LIMIT_PER_MINUTE: string;
}

interface FeedbackPayload {
  app_name: string;
  app_version: string;
  platform: string;
  feedback: string;
}

// Simple in-memory rate limiter (resets on worker restart, which is fine)
const rateLimitMap = new Map<string, { count: number; resetAt: number }>();

function isRateLimited(ip: string, maxPerMinute: number): boolean {
  const now = Date.now();
  const entry = rateLimitMap.get(ip);

  if (!entry || now > entry.resetAt) {
    rateLimitMap.set(ip, { count: 1, resetAt: now + 60_000 });
    return false;
  }

  entry.count++;
  return entry.count > maxPerMinute;
}

function formatMessage(payload: FeedbackPayload): string {
  const now = new Date();
  const pad = (n: number) => n.toString().padStart(2, "0");
  const timestamp = `${now.getUTCFullYear()}-${pad(now.getUTCMonth() + 1)}-${pad(now.getUTCDate())} ${pad(now.getUTCHours())}:${pad(now.getUTCMinutes())}`;

  return [
    `\u{1F4F1} App: ${payload.app_name}`,
    `\u{1F4E6} Version: ${payload.app_version}`,
    `\u{1F4F2} Platform: ${payload.platform}`,
    `\u{1F554} Time: ${timestamp} UTC`,
    "",
    `\u{1F4AC} Feedback:`,
    payload.feedback,
  ].join("\n");
}

async function sendToTelegram(message: string, env: Env): Promise<Response> {
  const url = `https://api.telegram.org/bot${env.TELEGRAM_BOT_TOKEN}/sendMessage`;
  return fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      chat_id: env.TELEGRAM_CHAT_ID,
      text: message,
      parse_mode: "Markdown",
    }),
  });
}

async function sendToDiscord(message: string, env: Env): Promise<Response> {
  return fetch(env.DISCORD_WEBHOOK_URL!, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ content: message }),
  });
}

async function sendToSlack(message: string, env: Env): Promise<Response> {
  return fetch(env.SLACK_WEBHOOK_URL!, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ text: message }),
  });
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    // Only accept POST to /feedback
    const url = new URL(request.url);
    if (url.pathname !== "/feedback") {
      return new Response("Not found", { status: 404 });
    }
    if (request.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }

    // Rate limit by IP
    const ip = request.headers.get("cf-connecting-ip") || "unknown";
    const maxPerMinute = parseInt(env.RATE_LIMIT_PER_MINUTE || "5", 10);
    if (isRateLimited(ip, maxPerMinute)) {
      return Response.json(
        { ok: false, error: "Rate limited. Try again in a minute." },
        { status: 429 }
      );
    }

    // Parse and validate payload
    let payload: FeedbackPayload;
    try {
      payload = await request.json();
    } catch {
      return Response.json(
        { ok: false, error: "Invalid JSON" },
        { status: 400 }
      );
    }

    if (!payload.feedback?.trim()) {
      return Response.json(
        { ok: false, error: "Feedback text is required" },
        { status: 400 }
      );
    }

    if (payload.feedback.length > 2000) {
      return Response.json(
        { ok: false, error: "Feedback text exceeds 2000 characters" },
        { status: 400 }
      );
    }

    if (!payload.app_name || !payload.app_version || !payload.platform) {
      return Response.json(
        { ok: false, error: "Missing required fields: app_name, app_version, platform" },
        { status: 400 }
      );
    }

    // Format and send
    const message = formatMessage(payload);

    let result: Response;
    try {
      switch (env.CHANNEL) {
        case "telegram":
          result = await sendToTelegram(message, env);
          break;
        case "discord":
          result = await sendToDiscord(message, env);
          break;
        case "slack":
          result = await sendToSlack(message, env);
          break;
        default:
          return Response.json(
            { ok: false, error: "Invalid CHANNEL configured" },
            { status: 500 }
          );
      }
    } catch (e) {
      return Response.json(
        { ok: false, error: "Failed to send feedback" },
        { status: 502 }
      );
    }

    if (result.ok || (result.status >= 200 && result.status < 300)) {
      return Response.json({ ok: true });
    }

    const errorBody = await result.text();
    return Response.json(
      { ok: false, error: `Upstream error: ${errorBody}` },
      { status: 502 }
    );
  },
};
