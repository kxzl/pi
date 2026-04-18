---
name: browserbase
description: Headless browser automation for quiet background research — reading live API documentation, checking npm/PyPI package pages, scraping Stack Overflow answers, or rendering a local dev server to verify output. Runs silently without affecting the visible VNC browser window. Use this when you need web content that requires JavaScript rendering but don't need the user to see the session. Use the 'browser' skill instead for interactive or visible sessions.
---

# Browserbase (Headless Browser)

Silent headless browser for automated research. Invisible to VNC — does not disturb the live browser window.

Add `"headless": true` to any `browser.js` command to run silently.

## Invoke

```bash
node /usr/local/lib/browser.js '{"headless": true, "action": "...", ...}'
```

## Common Research Workflows

### Read live API documentation
```bash
node /usr/local/lib/browser.js '{"headless":true,"action":"navigate","url":"https://docs.example.com/api"}'
node /usr/local/lib/browser.js '{"headless":true,"action":"text"}'
```

### Check a Stack Overflow answer
```bash
node /usr/local/lib/browser.js '{"headless":true,"action":"navigate","url":"https://stackoverflow.com/q/12345"}'
node /usr/local/lib/browser.js '{"headless":true,"action":"text","selector":".answer"}'
```

### Read npm package page
```bash
node /usr/local/lib/browser.js '{"headless":true,"action":"navigate","url":"https://www.npmjs.com/package/express"}'
node /usr/local/lib/browser.js '{"headless":true,"action":"text","selector":"#readme"}'
```

### Test a local dev server
```bash
node /usr/local/lib/browser.js '{"headless":true,"action":"navigate","url":"http://localhost:3000"}'
node /usr/local/lib/browser.js '{"headless":true,"action":"screenshot","path":"/workspace/render.png"}'
node /usr/local/lib/browser.js '{"headless":true,"action":"text"}'
```

### Extract structured data with JavaScript
```bash
node /usr/local/lib/browser.js '{"headless":true,"action":"navigate","url":"https://example.com/data"}'
node /usr/local/lib/browser.js '{"headless":true,"action":"evaluate","script":"[...document.querySelectorAll(\".item\")].map(e=>({title:e.querySelector(\"h2\")?.innerText,link:e.querySelector(\"a\")?.href}))"}'
```

## All Supported Actions

Same as the `browser` skill: `navigate`, `screenshot`, `click`, `fill`, `evaluate`, `text`, `back`, `forward` — just add `"headless": true` to each call.

## Notes

- Headless sessions use a **separate persistent profile** (`~/.pi/browser-headless-profile`) — cookies and auth from headed sessions are not shared
- JavaScript-heavy SPAs work fine — wait for DOM content with `waitUntil: domcontentloaded` (automatic)
- For large pages where `text` is truncated, use `evaluate` with a targeted query to extract exactly what you need
- Session state (login cookies) persists across calls within the same container run
