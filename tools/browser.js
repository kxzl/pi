#!/usr/bin/env node
// Browser control tool for the Pi agent.
//
// Usage (via bash tool):
//   node /usr/local/lib/browser.js '<json>'
//
// Actions:
//   navigate  {url}                  Go to URL, returns title + url
//   screenshot {path?}               Save PNG (default /tmp/screenshot.png)
//   click     {selector}             Click element by CSS selector
//   fill      {selector, value}      Fill an input field
//   evaluate  {script}               Run JavaScript, return result
//   text      {selector?}            Get page text or element text (max 5000 chars)
//   back      {}                     Navigate back
//   forward   {}                     Navigate forward

const { chromium } = require('playwright');

async function run() {
  const cmd = JSON.parse(process.argv[2] || '{}');

  let browser;
  try {
    browser = await chromium.connectOverCDP('http://localhost:9222');
  } catch {
    out({ ok: false, error: 'Browser not reachable — is the container running with browser support?' });
    return;
  }

  // Use the most recently active page, or open a new tab
  let page;
  const allPages = browser.contexts().flatMap(c => c.pages());
  page = allPages.length > 0 ? allPages[allPages.length - 1] : await browser.newPage();

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

  await browser.disconnect();
  out(result);
}

function out(obj) { console.log(JSON.stringify(obj)); }

run().catch(err => {
  out({ ok: false, error: err.message });
  process.exit(1);
});
