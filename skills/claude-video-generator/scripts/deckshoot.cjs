// Screenshot every #sN slide div of deck.html to slide-NN.png at 1920x1080.
// Style the deck by RENDERING the client's real template (unzip the pptx, pull the
// logo from ppt/media/, view real slides) - theme XML lies about ground colours.
const { chromium } = require('playwright');   // EDIT ME: repo's playwright path
const N = parseInt(process.env.SLIDES || '20', 10);
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1920, height: 1080 } });
  await p.goto('file://' + __dirname + '/deck.html');
  await p.waitForTimeout(600);
  for (let i = 1; i <= N; i++) {
    const id = '#s' + i;
    await p.locator(id).scrollIntoViewIfNeeded();
    await p.locator(id).screenshot({ path: __dirname + '/slide-' + String(i).padStart(2, '0') + '.png' });
  }
  await b.close();
  console.log(N + ' slides shot');
})();
