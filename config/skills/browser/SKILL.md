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

**RIGHT** — use the bash tool with simple arguments:
```bash
node /usr/local/lib/browser.js navigate https://example.com
```

All actions return JSON with `{"ok": true, ...}` on success or `{"ok": false, "error": "..."}` on failure.

## Actions

### navigate
Go to a URL. Waits for `DOMContentLoaded`.
```bash
node /usr/local/lib/browser.js navigate https://example.com
# → {"ok":true,"title":"Example Domain","url":"https://example.com/"}
```

### text
Get visible page text (up to 5000 chars). Optionally scope to a CSS selector.
```bash
node /usr/local/lib/browser.js text
node /usr/local/lib/browser.js text "#main-content"
# → {"ok":true,"text":"..."}
```

### screenshot
Save a PNG of the current page. Default path: `/tmp/screenshot.png`.
```bash
node /usr/local/lib/browser.js screenshot
node /usr/local/lib/browser.js screenshot /workspace/page.png
# → {"ok":true,"saved":"/tmp/screenshot.png"}
```

### click
Click an element by CSS selector. Waits for the element to be visible.
```bash
node /usr/local/lib/browser.js click "button[type=submit]"
node /usr/local/lib/browser.js click "a.login-link"
# → {"ok":true,"url":"https://example.com/next-page"}
```

### fill
Fill an input field. Clears the field first. Takes selector then value as separate arguments.
```bash
node /usr/local/lib/browser.js fill "#username" "admin"
node /usr/local/lib/browser.js fill "input[name=q]" "search term"
# → {"ok":true}
```

### evaluate
Run arbitrary JavaScript in the page context and return the result.
```bash
node /usr/local/lib/browser.js evaluate 'document.title'
node /usr/local/lib/browser.js evaluate '[...document.querySelectorAll("h2")].map(e=>e.innerText)'
node /usr/local/lib/browser.js evaluate 'document.querySelectorAll("a").length'
# → {"ok":true,"result": ...}
```

### back / forward
Navigate browser history.
```bash
node /usr/local/lib/browser.js back
node /usr/local/lib/browser.js forward
# → {"ok":true,"url":"https://example.com/previous"}
```

## Common Workflows

### Scrape a page
```bash
node /usr/local/lib/browser.js navigate https://target.com/page
node /usr/local/lib/browser.js text
# or for structured data:
node /usr/local/lib/browser.js evaluate '[...document.querySelectorAll(".item")].map(e=>e.innerText)'
```

### Submit a form
```bash
node /usr/local/lib/browser.js navigate https://site.com/form
node /usr/local/lib/browser.js fill "#name" "John"
node /usr/local/lib/browser.js fill "#email" "john@example.com"
node /usr/local/lib/browser.js click "button[type=submit]"
node /usr/local/lib/browser.js text
```

### Login then act
```bash
node /usr/local/lib/browser.js navigate https://site.com/login
node /usr/local/lib/browser.js fill "#username" "myuser"
node /usr/local/lib/browser.js fill "#password" "mypass"
node /usr/local/lib/browser.js click "button[type=submit]"
# session cookie is now set — navigate freely
node /usr/local/lib/browser.js navigate https://site.com/dashboard
node /usr/local/lib/browser.js text
```

### Inspect what's on screen
```bash
node /usr/local/lib/browser.js screenshot
# read the file to understand the current page state
read /tmp/screenshot.png
```

## Tips

- **Selector not found?** Use `evaluate` to inspect the DOM: `node /usr/local/lib/browser.js evaluate 'document.body.innerHTML.slice(0,2000)'`
- **Page not loaded yet?** Call `navigate` again to retry, or use `evaluate` with `document.readyState`
- **Text truncated?** Use `evaluate` with a targeted query to extract only what you need
- **Cookies persist** for the life of the container — log in once, stay logged in
- **Shell quoting tip:** Use single quotes around JavaScript with double quotes inside: `'[...document.querySelectorAll("a")].map(e=>e.href)'`
