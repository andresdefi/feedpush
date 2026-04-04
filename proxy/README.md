# FeedPush Proxy - Cloudflare Worker

A lightweight proxy that receives feedback from mobile apps and forwards it to Telegram, Discord, or Slack. All credentials stay on the server -- the app only needs the proxy URL.

## Why Use a Proxy?

Without a proxy, the app holds the bot token or webhook URL in its binary. Even obfuscated, a determined attacker can extract it. The proxy eliminates this:

- The app only knows the proxy URL (e.g., `https://feedpush-proxy.your-name.workers.dev/feedback`)
- Bot tokens and webhook URLs are stored as Cloudflare secrets
- Server-side rate limiting by IP (not bypassable like client-side cooldowns)

## Setup

### 1. Install Wrangler

```bash
npm install -g wrangler
```

### 2. Log in to Cloudflare

```bash
wrangler login
```

### 3. Deploy

```bash
cd proxy
npx wrangler deploy
```

This gives you a URL like `https://feedpush-proxy.your-name.workers.dev`.

### 4. Set your delivery channel

```bash
echo "telegram" | npx wrangler secret put CHANNEL
```

Valid values: `telegram`, `discord`, `slack`

### 5. Set credentials for your chosen channel

**For Telegram:**
```bash
echo "YOUR_BOT_TOKEN" | npx wrangler secret put TELEGRAM_BOT_TOKEN
echo "YOUR_CHAT_ID" | npx wrangler secret put TELEGRAM_CHAT_ID
```

**For Discord:**
```bash
echo "YOUR_WEBHOOK_URL" | npx wrangler secret put DISCORD_WEBHOOK_URL
```

**For Slack:**
```bash
echo "YOUR_WEBHOOK_URL" | npx wrangler secret put SLACK_WEBHOOK_URL
```

### 6. Test

```bash
curl -X POST https://feedpush-proxy.your-name.workers.dev/feedback \
  -H "Content-Type: application/json" \
  -d '{"app_name":"Test","app_version":"1.0","platform":"CLI","feedback":"Hello from the proxy!"}'
```

You should receive the message on your chosen channel.

### 7. Configure your app

In your app's `FeedbackConfig`, set the channel to `.proxy` and provide the proxy URL:

```swift
// Swift example
static let channel: FeedbackChannel = .proxy
static let proxyURL = "https://feedpush-proxy.your-name.workers.dev/feedback"
```

No tokens or webhook URLs needed in the app.

## Configuration

### Rate Limiting

The default rate limit is 5 requests per minute per IP. To change it, edit `wrangler.toml`:

```toml
[vars]
RATE_LIMIT_PER_MINUTE = "10"
```

Then redeploy: `npx wrangler deploy`

### Switching Channels

To switch from Telegram to Discord (for example):

```bash
echo "discord" | npx wrangler secret put CHANNEL
echo "YOUR_WEBHOOK_URL" | npx wrangler secret put DISCORD_WEBHOOK_URL
```

No app update needed -- the proxy handles the routing.

## API

### POST /feedback

**Request body:**
```json
{
  "app_name": "My App",
  "app_version": "1.0.0",
  "platform": "iOS 18.4",
  "feedback": "This is great!"
}
```

**Success response (200):**
```json
{ "ok": true }
```

**Error responses:**
- `400` -- Invalid JSON, missing fields, empty feedback, or feedback exceeds 2000 characters
- `404` -- Wrong endpoint (only `/feedback` is valid)
- `405` -- Wrong HTTP method (only POST)
- `429` -- Rate limited
- `502` -- Upstream delivery failed

## How It Works

```
App  -->  POST /feedback  -->  Cloudflare Worker  -->  Telegram / Discord / Slack
```

1. App sends a JSON payload with app info and feedback text
2. Worker validates the payload and checks rate limits
3. Worker formats the message with emojis and metadata
4. Worker forwards to the configured channel using server-side credentials
5. Worker returns success or error to the app
