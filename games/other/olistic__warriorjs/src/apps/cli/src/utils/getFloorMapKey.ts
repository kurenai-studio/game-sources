import { type FloorSpace } from '@warriorjs/core';

import getUnitAppearance from './getUnitAppearance.js';

function formatEntry(unit: NonNullable<FloorSpace['unit']>): string {
  const { character } = getUnitAppearance(unit.name, unit.warrior);
  return `${character} = ${unit.name} (${unit.maxHealth} HP)`;
}

function getFloorMapKey(map: FloorSpace[][]): string {
  const seen = new Set<string>();
  let warriorEntry = '';
  const entries: string[] = [];

  for (const row of map) {
    for (const space of row) {
      if (space.unit && !seen.has(space.unit.name)) {
        seen.add(space.unit.name);
        if (space.unit.warrior) {
          warriorEntry = formatEntry(space.unit);
        } else {
          entries.push(formatEntry(space.unit));
        }
      }
    }
  }

  return [warriorEntry, ...entries, '> = stairs'].filter(Boolean).join('\n');
}

export default getFloorMapKey;
