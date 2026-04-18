---
name: browser
description: Control the live Chromium browser running in this container. Use for web scraping, form submission, login flows, JavaScript-heavy pages, and anything that needs a real browser session. Prefer this over ollama_web_fetch when pages require JS rendering, authentication, or interactive elements. The browser session persists across calls — cookies and navigation history are retained.
---

# Browser Control

Controls the headed Chromium browser in this container. The session is always visible at **http://localhost:6080/vnc.html**.

## IMPORTANT: This is NOT a tool. Use the bash tool to invoke browser commands.

**WRONG** — do NOT call "browser" as a tool:
```
browser({"action": "navigate", "url": "https://example.com"})
```

**RIGHT** — use the bash tool with this command:
```bash
node /usr/local/lib/browser.js '{"action":"navigate","url":"https://example.com"}'
```

All actions return JSON with `{"ok": true, ...}` on success or `{"ok": false, "error": "..."}` on failure.

## Actions

### navigate
Go to a URL. Waits for `DOMContentLoaded`.
```bash
node /usr/local/lib/browser.js '{"action":"navigate","url":"https://example.com"}'
# → {"ok":true,"title":"Example Domain","url":"https://example.com/"}
```

### text
Get visible page text (up to 5000 chars). Optionally scope to a CSS selector.
```bash
node /usr/local/lib/browser.js '{"action":"text"}'
node /usr/local/lib/browser.js '{"action":"text","selector":"#main-content"}'
# → {"ok":true,"text":"..."}
```

### screenshot
Save a PNG of the current page. Default path: `/tmp/screenshot.png`.
```bash
node /usr/local/lib/browser.js '{"action":"screenshot"}'
node /usr/local/lib/browser.js '{"action":"screenshot","path":"/workspace/page.png"}'
# → {"ok":true,"saved":"/tmp/screenshot.png"}
```

### click
Click an element by CSS selector. Waits for the element to be visible.
```bash
node /usr/local/lib/browser.js '{"action":"click","selector":"button[type=\"submit\"]"}'
node /usr/local/lib/browser.js '{"action":"click","selector":"a[href*=\"login\"]"}'
# → {"ok":true,"url":"https://example.com/next-page"}
```

### fill
Fill an input field. Clears the field first.
```bash
node /usr/local/lib/browser.js '{"action":"fill","selector":"#username","value":"admin"}'
node /usr/local/lib/browser.js '{"action":"fill","selector":"input[name=\"q\"]","value":"search term"}'
# → {"ok":true}
```

### evaluate
Run arbitrary JavaScript in the page context and return the result.
```bash
node /usr/local/lib/browser.js '{"action":"evaluate","script":"document.title"}'
node /usr/local/lib/browser.js '{"action":"evaluate","script":"[...document.querySelectorAll(\"h2\")].map(e=>e.innerText)"}'
# → {"ok":true,"result": ...}
```

### back / forward
Navigate browser history.
```bash
node /usr/local/lib/browser.js '{"action":"back"}'
node /usr/local/lib/browser.js '{"action":"forward"}'
# → {"ok":true,"url":"https://example.com/previous"}
```

## Common Workflows

### Scrape a page
```bash
node /usr/local/lib/browser.js '{"action":"navigate","url":"https://target.com/page"}'
node /usr/local/lib/browser.js '{"action":"text"}'
# or for structured data:
node /usr/local/lib/browser.js '{"action":"evaluate","script":"[...document.querySelectorAll(\".item\")].map(e=>e.innerText)"}'
```

### Submit a form
```bash
node /usr/local/lib/browser.js '{"action":"navigate","url":"https://site.com/form"}'
node /usr/local/lib/browser.js '{"action":"fill","selector":"#name","value":"John"}'
node /usr/local/lib/browser.js '{"action":"fill","selector":"#email","value":"john@example.com"}'
node /usr/local/lib/browser.js '{"action":"click","selector":"button[type=\"submit\"]"}'
node /usr/local/lib/browser.js '{"action":"text"}'
```

### Login then act
```bash
node /usr/local/lib/browser.js '{"action":"navigate","url":"https://site.com/login"}'
node /usr/local/lib/browser.js '{"action":"fill","selector":"#username","value":"myuser"}'
node /usr/local/lib/browser.js '{"action":"fill","selector":"#password","value":"mypass"}'
node /usr/local/lib/browser.js '{"action":"click","selector":"button[type=\"submit\"]"}'
# session cookie is now set — navigate freely
node /usr/local/lib/browser.js '{"action":"navigate","url":"https://site.com/dashboard"}'
node /usr/local/lib/browser.js '{"action":"text"}'
```

### Inspect what's on screen
```bash
node /usr/local/lib/browser.js '{"action":"screenshot"}'
# read the file to understand the current page state
read /tmp/screenshot.png
```

## Tips

- **Selector not found?** Use `evaluate` to inspect the DOM: `{"action":"evaluate","script":"document.body.innerHTML.slice(0,2000)"}`
- **Page not loaded yet?** Call `navigate` again to retry, or use `evaluate` with `document.readyState`
- **Text truncated?** Use `evaluate` with a targeted query to extract only what you need
- **Cookies persist** for the life of the container — log in once, stay logged in
