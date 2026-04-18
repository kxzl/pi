// Launches a headed Chromium browser with CDP on port 9222.
// Keeps running until the container stops so the browser stays live.
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({
    headless: false,
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--remote-debugging-port=9222',
      '--window-size=1920,1080',
    ],
  });

  // Open one blank tab so the window is immediately visible on VNC
  const ctx = await browser.newContext({ viewport: null });
  await ctx.newPage();

  process.stdout.write('Chromium started (CDP at localhost:9222)\n');

  process.stdin.resume();
  const shutdown = () => browser.close().finally(() => process.exit(0));
  process.on('SIGTERM', shutdown);
  process.on('SIGINT', shutdown);
})().catch(err => {
  process.stderr.write('Failed to launch browser: ' + err.message + '\n');
  process.exit(1);
});
