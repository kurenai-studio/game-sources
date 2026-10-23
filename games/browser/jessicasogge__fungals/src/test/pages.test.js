// Checks the things every page shares: the FunGals tab icon (not the
// browser's generic globe), the home-screen icon, and Jess's signature at the foot.
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

const file = (name) => new URL(`../public/${name}`, import.meta.url);
const PAGES = ['index.html', 'pal-picker.html', 'petri-dish.html', 'whos-that-gal.html'];

describe('tab icon', () => {
  it.each(PAGES)('%s links the icon, with a PNG for browsers without SVG icons', (page) => {
    const html = readFileSync(file(page), 'utf8');
    expect(html).toContain('<link rel="icon" href="./favicon.svg" type="image/svg+xml" />');
    expect(html).toContain('<link rel="icon" href="./favicon-32.png" type="image/png" sizes="32x32" />');
  });

  it.each(PAGES)('%s links the home-screen icon, named FunGals', (page) => {
    const html = readFileSync(file(page), 'utf8');
    expect(html).toContain('<link rel="apple-touch-icon" href="./apple-touch-icon.png" />');
    expect(html).toContain('<meta name="apple-mobile-web-app-title" content="FunGals" />');
  });

  it('has a 180 x 180 home-screen icon with no see-through parts', () => {
    const png = readFileSync(file('apple-touch-icon.png'));
    expect(png.readUInt32BE(16)).toBe(180); // width, from the PNG header
    expect(png.readUInt32BE(20)).toBe(180); // height
    expect(png[25]).toBe(2); // plain RGB, no alpha: iOS fills see-through parts with black
  });

  it('has both icon files', () => {
    expect(existsSync(file('favicon.svg'))).toBe(true);
    expect(existsSync(file('favicon-32.png'))).toBe(true);
  });
});

describe('stylesheet', () => {
  // The deploy (.github/workflows/pages.yml) stamps this exact link with a
  // fingerprint of styles.css, so browsers fetch new styles when they change.
  it.each(PAGES)('%s links styles.css the way the deploy expects', (page) => {
    const html = readFileSync(file(page), 'utf8');
    expect(html).toContain('<link rel="stylesheet" href="./styles.css" />');
  });

  it('every page in public/ is listed here, so none misses the stamp', () => {
    const pages = readdirSync(new URL('../public/', import.meta.url))
      .filter((name) => name.endsWith('.html') && !name.startsWith('google'));
    expect(pages.sort()).toEqual([...PAGES].sort());
  });
});

describe('visit counting', () => {
  // GoatCounter counts page visits (no cookies, nothing personal), on the
  // same dashboard as PetriPals. FunGals' pages show up there under /fungals/.
  it.each(PAGES)('%s loads the GoatCounter script', (page) => {
    const html = readFileSync(file(page), 'utf8');
    expect(html).toContain('<script data-goatcounter="https://petripals.goatcounter.com/count"\n            async src="https://gc.zgo.at/count.js"></script>');
  });
});

describe('signature', () => {
  it.each(PAGES)('%s is signed at the foot', (page) => {
    const html = readFileSync(file(page), 'utf8');
    expect(html).toContain('<footer class="signature">jsogge 2026</footer>');
  });
});

describe('the home page title', () => {
  const html = readFileSync(file('index.html'), 'utf8');
  const css = readFileSync(file('styles.css'), 'utf8');

  it('says what the game is under its name', () => {
    expect(html).toContain('<h1 class="logo">FunGals</h1>');
    expect(html).toContain('<p class="tagline">Grow your colony. Dodge antifungals.</p>');
  });

  it("has every font file the stylesheet uses, each with its license", () => {
    const fonts = [...css.matchAll(/url\(\.\/(fonts\/[^)]+\.woff2)\)/g)].map((m) => m[1]);
    expect(fonts.length).toBeGreaterThan(0);
    for (const font of fonts) expect(existsSync(file(font)), font).toBe(true);
    expect(existsSync(file('fonts/Fredoka-OFL.txt'))).toBe(true);
    expect(existsSync(file('fonts/Nunito-OFL.txt'))).toBe(true);
  });

  it('preloads the title font, so the name shows up in it quickly', () => {
    const [, preloaded] = html.match(/<link rel="preload" href="\.\/([^"]+)" as="font"/);
    expect(css).toContain(`url(./${preloaded})`);
  });
});

describe('search engines and shared links', () => {
  const SITE = 'https://jessicasogge.github.io/fungals/';
  const meta = (html, attr, name) => html.match(new RegExp(`<meta ${attr}="${name}" content="([^"]*)"`))?.[1];

  it('names the game and what it is in the home page title', () => {
    expect(readFileSync(file('index.html'), 'utf8')).toContain('<title>FunGals: A Mycology Game</title>');
  });

  it.each(PAGES)('%s has a description short enough for a search result', (page) => {
    const description = meta(readFileSync(file(page), 'utf8'), 'name', 'description');
    expect(description).toBeTruthy();
    expect(description.length).toBeLessThanOrEqual(160);
  });

  it.each(PAGES)('%s says where it lives, for search engines and shared links', (page) => {
    const html = readFileSync(file(page), 'utf8');
    const address = page === 'index.html' ? SITE : SITE + page;
    expect(html).toContain(`<link rel="canonical" href="${address}" />`);
    expect(meta(html, 'property', 'og:url')).toBe(address);
  });

  it.each(PAGES)('%s shows a picture when its link is shared', (page) => {
    const html = readFileSync(file(page), 'utf8');
    const image = meta(html, 'property', 'og:image');
    expect(image.startsWith(SITE)).toBe(true); // apps need the full address
    expect(existsSync(file(image.slice(SITE.length)))).toBe(true);
    expect(meta(html, 'property', 'og:image:width')).toBe('1200');
    expect(meta(html, 'property', 'og:image:height')).toBe('630');
    expect(meta(html, 'property', 'og:image:alt')).toBeTruthy();
    expect(meta(html, 'property', 'og:title')).toBeTruthy();
    expect(meta(html, 'property', 'og:description')).toBe(meta(html, 'name', 'description'));
    expect(meta(html, 'name', 'twitter:card')).toBe('summary_large_image');
  });

  it('has a link picture the size apps expect (1200 x 630)', () => {
    const png = readFileSync(file('social-preview.png'));
    expect(png.readUInt32BE(16)).toBe(1200); // width, from the PNG header
    expect(png.readUInt32BE(20)).toBe(630); // height
  });

  it('lists real pages in the sitemap', () => {
    const sitemap = readFileSync(file('sitemap.xml'), 'utf8');
    const pages = [...sitemap.matchAll(/<loc>([^<]+)<\/loc>/g)].map((m) => m[1]);
    expect(pages).toContain(SITE);
    for (const address of pages) {
      expect(address.startsWith(SITE)).toBe(true);
      expect(existsSync(file(address.slice(SITE.length) || 'index.html')), address).toBe(true);
    }
  });
});

describe('Google Search Console', () => {
  // Proves to Google that Jess owns the site. Google checks it again from
  // time to time, so deleting or changing it would undo the verification.
  it('keeps the verification file, exactly as Google gave it', () => {
    const name = 'google32efa8321a61b455.html';
    expect(readFileSync(file(name), 'utf8')).toBe(`google-site-verification: ${name}`);
  });
});
