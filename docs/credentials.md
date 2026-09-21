# Getting your Canvas credentials

`canvas.mjs` needs two things from `.env`: your school's Canvas base URL, and either a session cookie or an API token.

## The base URL

Whatever you see in the browser address bar when you're logged into Canvas, with no trailing slash and no path:

```
CANVAS_API_BASE=https://school.instructure.com
```

## Option A: session cookie (always works, prefer this)

Schools increasingly disable API tokens for students, but the browser session always works. Copy the `cookie:` request header straight out of DevTools:

1. Log into Canvas in your browser.
2. Press `F12` to open DevTools → **Network** tab.
3. Refresh the page.
4. Click any request going to your Canvas domain.
5. Under **Request Headers**, find the `cookie:` line and copy its **entire** value.
6. Paste it after `CANVAS_COOKIE=` in `.env` — one line, no quotes.

Two gotchas that trip everyone up:

- DevTools **truncates** long cookie values with a `…` (ellipsis). If your value contains non-ASCII characters the script will refuse it with an explicit error. To get the untruncated value: right-click a request → **Copy** → **Copy as cURL**, then extract everything after `cookie:`.
- The cookie expires when your browser session does. Treat refreshing it as routine maintenance; `canvas.mjs` prints a clear hint when it's stale.

## Option B: API access token (if your school allows it)

Canvas → Account → Settings → New Access Token. Paste into `.env` instead:

```
CANVAS_API_TOKEN=<token>
```

## Verifying

From the `canvas` folder:

```
node canvas.mjs whoami
```

Success looks like: `Authenticated as Your Name (12345)`.