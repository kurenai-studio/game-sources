// @vitest-environment jsdom
// placeAntifungals adds the disks to the page, so these tests run in jsdom,
// a simulated browser page.
import { beforeEach, describe, expect, it } from 'vitest';
import { placeAntifungals } from '../public/game/antifungal.js';
import { SPECIES } from '../public/game/config.js';

beforeEach(() => {
  document.body.innerHTML = '<div class="agar"></div>';
});

describe("a mold's disks", () => {
  it.each(['fumi', 'penelope', 'miri'])("%s's all have zones: no drug she shrugs off, and no fluconazole", (gal) => {
    for (const drug of SPECIES[gal].antifungals) expect(drug.zone, drug.code).toBeGreaterThan(0);
    expect(SPECIES[gal].antifungals.map((drug) => drug.code)).not.toContain('FLC');
  });
});

describe('placing the disks', () => {
  it('puts one disk per antifungal on the agar, labeled with its code', () => {
    const disks = placeAntifungals(SPECIES.candi.antifungals.slice(0, 3));
    const els = [...document.querySelectorAll('.agar .antifungal')];
    expect(els).toHaveLength(3);
    expect(els.map((el) => el.textContent)).toEqual(['FLC', 'NY', 'VOR']);
    expect(disks.map((d) => d.el)).toEqual(els);
  });

  it('names the antifungal for the hover label, starting with a capital letter', () => {
    placeAntifungals([{ code: 'FLC', name: 'fluconazole' }, { code: 'AMB', name: 'amphotericin B' }]);
    const names = [...document.querySelectorAll('.antifungal')].map((el) => el.dataset.name);
    expect(names).toEqual(['Fluconazole', 'Amphotericin B']);
  });

  it("doesn't also show the browser's own slow tooltip", () => {
    placeAntifungals([{ code: 'FLC', name: 'fluconazole' }]);
    expect(document.querySelector('.antifungal').hasAttribute('title')).toBe(false);
  });

  it('tells screen readers what the disk is', () => {
    placeAntifungals([{ code: 'NY', name: 'nystatin' }]);
    expect(document.querySelector('.antifungal').getAttribute('aria-label')).toMatch(/nystatin/);
  });
});

describe("a disk for a drug she's resistant to", () => {
  it("tells screen readers there's no clear zone, but the disk still counts", () => {
    placeAntifungals([{ code: 'FLC', name: 'fluconazole', zone: null }]);
    expect(document.querySelector('.antifungal').getAttribute('aria-label'))
      .toBe("Antifungal disk: fluconazole. No clear zone (resistant), but don't touch the disk!");
  });
});
