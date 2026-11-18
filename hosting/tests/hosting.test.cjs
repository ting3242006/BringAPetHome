const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const root = path.resolve(__dirname, '../..');
const read = relative => fs.readFileSync(path.join(root, relative), 'utf8');

test('Hosting serves the hand-authored AASA and animal fallback', () => {
  const { hosting } = JSON.parse(read('firebase.json'));
  assert.equal(hosting.site, 'bringapethome');
  assert.equal(hosting.public, 'hosting/public');
  assert.equal(hosting.appAssociation, 'NONE');
  assert.equal(hosting.redirects?.length ?? 0, 0);
  assert.ok(!hosting.ignore.includes('**/.*'), '.well-known must be deployed');
  const header = hosting.headers.find(rule => rule.source === '/.well-known/apple-app-site-association');
  assert.ok(header.headers.some(item => item.key === 'Content-Type' && item.value === 'application/json'));
  assert.ok(hosting.rewrites.some(rule => rule.source === '/animal/**' && rule.destination === '/index.html'));
  const aasa = JSON.parse(read('hosting/public/.well-known/apple-app-site-association'));
  assert.deepEqual(aasa.applinks.details[0].appIDs, ['J3XG5W7SR9.com.YiTing.BringAPetHome']);
  assert.deepEqual(aasa.applinks.details[0].components, [{ '/': '/animal/*' }]);
});

test('fallback has a real App Store link without requiring JavaScript', () => {
  const html = read('hosting/public/index.html');
  assert.match(html, /lang="zh-Hant"/);
  assert.match(html, /href="https:\/\/apps\.apple\.com\/app\/id1536547532"/);
  assert.match(html, /<h1>讓浪回家<\/h1>/);
});

function render(pathname) {
  const elements = {
    'open-app': { hidden: true },
    'animal-reference': { textContent: '' }
  };
  const context = {
    location: Object.freeze({ pathname }),
    document: { getElementById: id => elements[id] }
  };
  vm.runInNewContext(read('hosting/public/animal-link.js'), context);
  return elements;
}

test('a valid animal path exposes only a manual Custom Scheme action', () => {
  const elements = render('/animal/443673');
  assert.equal(elements['open-app'].hidden, false);
  assert.equal(elements['open-app'].href, 'bringapethome://animal/443673');
  assert.match(elements['animal-reference'].textContent, /443673/);
});

test('invalid or overflowing animal paths cannot open the app', () => {
  const invalid = ['/', '/animal/0', '/animal/-1', '/animal/+1', '/animal/123/', '/animal/123/extra',
    '/animal/%31%32%33', '/animal/999999999999999999999999999', '/animal/<script>'];
  for (const pathname of invalid) {
    const elements = render(pathname);
    assert.equal(elements['open-app'].hidden, true, pathname);
    assert.equal(elements['open-app'].href, undefined, pathname);
  }
});
