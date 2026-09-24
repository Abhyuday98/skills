// Three capture templates in one file: doc viewer, console evidence card, and
// annotated before/after card. All shoot 1920x1080 PNGs via Playwright.
// FOOTGUN baked in below: never give the first child a top margin on these fixed
// 1080p pages - it collapses THROUGH body and pushes bottom captions out of frame.
const { chromium } = require('playwright');   // EDIT ME: repo's playwright path
const fs = require('fs');
const OUT = process.env.CARD_OUT || __dirname;

const esc = t => t.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
const b64 = f => 'data:image/png;base64,' + fs.readFileSync(f).toString('base64');

// ---- 1. Document capture: a REAL markdown file in a light "paper" viewer.
// Render your md -> html however you like; the chrome is what sells it:
const docPage = (relPath, bodyHtml) => `<!doctype html><meta charset="utf-8"><style>
  body{margin:0;background:#ECECF1;font-family:'Segoe UI',system-ui,sans-serif}
  .bar{position:fixed;top:0;left:0;right:0;height:64px;background:#fff;border-bottom:1px solid #D8D8DE;
       display:flex;align-items:center;gap:14px;padding:0 36px;z-index:2}
  .dot{width:12px;height:12px;border-radius:50%}
  .path{font-family:Consolas,monospace;font-size:20px;color:#1A1A24;font-weight:600}
  .git{margin-left:auto;font-size:16px;color:#747480}
  .doc{max-width:1250px;margin:100px auto 60px;background:#fff;border:1px solid #D8D8DE;border-radius:6px;
       box-shadow:0 4px 22px rgba(46,46,56,.10);padding:56px 72px;color:#3C3C46;font-size:21px;line-height:1.66}
  h1{color:#1A1A24;font-size:40px;border-bottom:4px solid #FFD400;padding-bottom:14px}
</style>
<div class="bar"><span class="dot" style="background:#ff5f57"></span><span class="dot" style="background:#febc2e"></span><span class="dot" style="background:#28c840"></span>
  <span class="path">${esc(relPath)}</span><span class="git">tracked in git</span></div>
<div class="doc">${bodyHtml}</div>`;

// ---- 2. Console evidence card: REAL command output, curated by DELETING lines
// only (never rewrite what remains), key tokens highlighted.
const evPage = (cmd, body, caption) => `<!doctype html><meta charset="utf-8"><style>
  body{margin:0;background:#fff;font-family:Arial,sans-serif;height:1080px;position:relative}
  .card{max-width:1500px;margin:70px auto 0;background:#1A1A24;box-shadow:0 4px 22px rgba(46,46,56,.18)}
  .bar{background:#23232F;border-bottom:1px solid #4A4A58;padding:18px 30px;display:flex;gap:12px;align-items:center}
  .dot{width:12px;height:12px;border-radius:50%}
  .cmd{font-family:Consolas,monospace;font-size:24px;color:#FFD400;margin-left:10px}
  pre{margin:0;padding:34px 40px;font-family:Consolas,monospace;font-size:23px;line-height:1.6;color:#D8D8E0;white-space:pre-wrap}
  .cap{max-width:1500px;margin:34px auto 0;color:#55555F;font-size:30px;line-height:1.5}
  .hl{color:#FFD400}
</style>
<div class="card"><div class="bar">
  <span class="dot" style="background:#ff5f57"></span><span class="dot" style="background:#febc2e"></span><span class="dot" style="background:#28c840"></span>
  <span class="cmd">${esc(cmd)}</span></div>
<pre>${esc(body).replace(/PASS/g,'<span class="hl">PASS</span>')}</pre></div>
<div class="cap">${esc(caption)}</div>`;

// ---- 3. Annotated card from verified row strips. Boxes positioned in NATIVE
// strip pixels converted to percentages - never drawn by eye on a full page.
// rows: [label, stripPngPath, stripHeightPx, [x1,y1,x2,y2], 'solid'|'dashed', note]
const findingPage = (title, rows, caption, stripW = 1448) => {
  const items = rows.map(([label, img, h, box, style, note]) => {
    const [x1, y1, x2, y2] = box;
    const px = v => (v / (stripW / 100)).toFixed(2);
    const py = v => (v / (h / 100)).toFixed(2);
    return `<div class="row"><div class="lab">${esc(label)}</div>
      <div class="imgbox"><img src="${b64(img)}">
        <div class="mark ${style}" style="left:${px(x1)}%;top:${py(y1)}%;width:${px(x2-x1)}%;height:${py(y2-y1)}%"></div>
        <div class="note" style="left:${px(x2+24)}%;top:${py(y1+(y2-y1)/2-16)}%">${esc(note)}</div>
      </div></div>`;
  }).join('');
  return `<!doctype html><meta charset="utf-8"><style>
    body{margin:0;background:#fff;font-family:Arial,sans-serif;width:1920px;height:1080px;position:relative;overflow:hidden}
    .title{margin:0 90px 8px;padding-top:30px;font-size:44px;font-weight:bold;color:#2E2E38;border-bottom:5px solid #FFD400;padding-bottom:14px}
    .wrap{width:980px;margin:10px auto 0}
    .row{margin-bottom:8px}
    .lab{color:#55555F;font-size:21px;font-weight:bold;margin:0 0 3px 2px}
    .imgbox{position:relative;border:1px solid #D8D8DE;line-height:0;box-shadow:0 3px 16px rgba(46,46,56,.12)}
    .imgbox img{width:100%;height:auto}
    .mark{position:absolute;border-radius:8px;box-shadow:0 0 0 2px rgba(46,46,56,.28)}
    .mark.solid{border:4px solid #FFD400}
    .mark.dashed{border:4px dashed #FFD400;box-shadow:none}
    .note{position:absolute;background:#FFD400;color:#1A1A24;font-size:19px;font-weight:bold;padding:5px 13px;border-radius:3px;white-space:nowrap;box-shadow:0 2px 8px rgba(46,46,56,.25)}
    .cap{position:absolute;left:90px;right:90px;bottom:16px;color:#55555F;font-size:26px}
  </style>
  <div class="title">${esc(title)}</div><div class="wrap">${items}</div>
  <div class="cap">${esc(caption)}</div>`;
};

async function shoot(html, png) {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1920, height: 1080 } });
  const tmp = `${OUT}/.card-tmp.html`;
  fs.writeFileSync(tmp, html);
  await p.goto('file://' + tmp);
  await p.waitForTimeout(250);
  await p.screenshot({ path: png });
  await b.close();
  console.log('shot', png);
}

module.exports = { docPage, evPage, findingPage, shoot };
