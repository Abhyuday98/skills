// One app-tour scene = one fresh Chromium, recorded, closed. Template.
// Record against `vite preview` of a STATIC demo-mode build, NEVER the dev server.
const { chromium } = require('playwright');   // EDIT ME: point at your repo's playwright
const fs = require('fs');
const OUT = process.env.TOUR_OUT || __dirname;
const APP = process.env.APP_URL || 'http://localhost:4173/';

(async () => {
  const b = await chromium.launch();
  const ctx = await b.newContext({
    viewport: { width: 1920, height: 1080 },
    recordVideo: { dir: OUT, size: { width: 1920, height: 1080 } },
  });
  const p = await ctx.newPage();
  // Fake cursor: captured video has no OS cursor.
  await p.addInitScript(() => {
    window.addEventListener('DOMContentLoaded', () => {
      const c = document.createElement('div');
      c.style.cssText = 'position:fixed;z-index:99999;width:22px;height:22px;border-radius:50%;' +
        'background:rgba(200,30,40,.35);border:2.5px solid #c81e28;pointer-events:none;' +
        'transform:translate(-50%,-50%);top:-40px;left:-40px';
      document.body.appendChild(c);
      window.addEventListener('mousemove', e => {
        c.style.left = e.clientX + 'px'; c.style.top = e.clientY + 'px';
      }, true);
    });
  });

  const t0 = Date.now();
  let trim = 4.0;                    // lead to cut in assembly, refined below
  try {
    await p.goto(APP, { waitUntil: 'load', timeout: 45000 });
    // Readiness = TEXT that only exists once real data rendered. Verify against the
    // real DOM first; do not guess selectors.
    await p.waitForSelector('text=Welcome back', { timeout: 30000 });   // EDIT ME
    trim = Math.max(0, (Date.now() - t0) / 1000 - 1.0);
    await p.waitForTimeout(1500);

    // EDIT ME: the scene. Glide the mouse (steps: 20+) before each click. Film
    // parameterised routes by CLICKING THROUGH from a loaded page - a direct goto
    // flashes the router's Not Found state.
    // const el = p.getByRole('button', { name: /Open thing/i }).first();
    // const bb = await el.boundingBox();
    // if (bb) { await p.mouse.move(bb.x + bb.width/2, bb.y + bb.height/2, { steps: 24 }); }
    // await el.click();
    await p.waitForTimeout(5000);
  } catch (e) { console.log('partial:', e.message.split('\n')[0]); }

  const v = p.video();
  await ctx.close();                 // flushes the webm
  fs.writeFileSync(`${OUT}/scene.json`, JSON.stringify([await v.path(), +trim.toFixed(1)]));
  await b.close();
  console.log('recorded, trim', trim.toFixed(1));
  // Recording slows the app: sample frames (ffmpeg -ss N -frames:v 1) before
  // choosing the assembly trim; never trust the wall-clock action schedule.
})();
