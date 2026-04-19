#!/usr/bin/env node
// Browser control tool for the Pi agent.
//
// Usage (via bash tool):
//
//   Simple CLI format (recommended — avoids shell quoting issues):
//     node /usr/local/lib/browser.js navigate https://example.com
//     node /usr/local/lib/browser.js text
//     node /usr/local/lib/browser.js text "#main-content"
//     node /usr/local/lib/browser.js click "button.submit"
//     node /usr/local/lib/browser.js fill "#email" "user@example.com"
//     node /usr/local/lib/browser.js evaluate 'document.title'
//     node /usr/local/lib/browser.js screenshot /tmp/shot.png
//     node /usr/local/lib/browser.js back
//     node /usr/local/lib/browser.js forward
//
//   JSON format (still supported):
//     node /usr/local/lib/browser.js '{"action":"navigate","url":"https://example.com"}'
//
// Actions:
//   navigate  <url>                  Go to URL, returns title + url
//   screenshot [path]                Save PNG (default /tmp/screenshot.png)
//   click     <selector>             Click element by CSS selector
//   fill      <selector> <value>     Fill an input field
//   evaluate  <script>               Run JavaScript, return result
//   text      [selector]             Get page text or element text (max 5000 chars)
//   back                             Navigate back
//   forward                          Navigate forward

const { chromium } = require('playwright');

const HEADLESS_PROFILE = '/home/piuser/.pi/browser-headless-profile';

// Parse command: try JSON first, fall back to simple CLI args
function parseCommand(argv) {
  const args = argv.slice(2);
  if (args.length === 0) return {};

  // If first arg looks like JSON, parse it
  if (args[0].startsWith('{')) {
    const parsed = JSON.parse(args[0]);
    // Accept both "script" and "code" for evaluate
    if (parsed.code && !parsed.script) parsed.script = parsed.code;
    return parsed;
  }

  // Simple CLI format: action [arg1] [arg2]
  const action = args[0];
  switch (action) {
    case 'navigate':
      return { action, url: args[1] };
    case 'text':
      return { action, selector: args[1] || undefined };
    case 'screenshot':
      return { action, path: args[1] || undefined };
    case 'click':
      return { action, selector: args[1] };
    case 'fill':
      return { action, selector: args[1], value: args[2] };
    case 'evaluate':
      return { action, script: args[1] };
    case 'back':
    case 'forward':
      return { action };
    default:
      return { action };
  }
}

async function run() {
  const cmd = parseCommand(process.argv);
  const headless = !!cmd.headless;

  let cleanup;
  let page;

  if (headless) {
    // Silent mode: own Playwright context, no VNC, persistent profile
    const ctx = await chromium.launchPersistentContext(HEADLESS_PROFILE, {
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox'],
    });
    const pages = ctx.pages();
    page = pages.length > 0 ? pages[0] : await ctx.newPage();
    cleanup = () => ctx.close();
  } else {
    // Headed mode: connect to the running VNC browser via CDP
    let browser;
    try {
      browser = await chromium.connectOverCDP('http://localhost:9222');
    } catch {
      out({ ok: false, error: 'Browser not reachable — is the container running with browser support?' });
      return;
    }
    const allPages = browser.contexts().flatMap(c => c.pages());
    page = allPages.length > 0 ? allPages[allPages.length - 1] : await browser.newPage();
    cleanup = () => browser.close();
  }

  let result;
  try {
    switch (cmd.action) {
      case 'navigate':
        await page.goto(cmd.url, { waitUntil: 'domcontentloaded', timeout: 30000 });
        result = { ok: true, title: await page.title(), url: page.url() };
        break;

      case 'screenshot': {
        const dest = cmd.path || '/tmp/screenshot.png';
        await page.screenshot({ path: dest, fullPage: !!cmd.fullPage });
        result = { ok: true, saved: dest };
        break;
      }

      case 'click':
        await page.click(cmd.selector, { timeout: 10000 });
        await page.waitForLoadState('domcontentloaded').catch(() => {});
        result = { ok: true, url: page.url() };
        break;

      case 'fill':
        await page.fill(cmd.selector, cmd.value);
        result = { ok: true };
        break;

      case 'evaluate':
        result = { ok: true, result: await page.evaluate(cmd.script) };
        break;

      case 'text': {
        const raw = cmd.selector
          ? await page.textContent(cmd.selector)
          : await page.evaluate(() => document.body.innerText);
        result = { ok: true, text: (raw || '').slice(0, 5000) };
        break;
      }

      case 'back':
        await page.goBack({ waitUntil: 'domcontentloaded', timeout: 10000 });
        result = { ok: true, url: page.url() };
        break;

      case 'forward':
        await page.goForward({ waitUntil: 'domcontentloaded', timeout: 10000 });
        result = { ok: true, url: page.url() };
        break;

      default:
        result = { ok: false, error: 'Unknown action: ' + cmd.action };
    }
  } catch (err) {
    result = { ok: false, error: err.message };
  }

  await cleanup();
  out(result);
}

function out(obj) { console.log(JSON.stringify(obj)); }

run().catch(err => {
  out({ ok: false, error: err.message });
  process.exit(1);
});
