import { type FloorSpace } from '@warriorjs/core';

import getUnitAppearance from './getUnitAppearance.js';

export interface SpaceAppearance {
  character: string;
  color: string | undefined;
}

function getWallCharacter(row: number, col: number, totalRows: number, totalCols: number): string {
  const top = row === 0;
  const bottom = row === totalRows - 1;
  const left = col === 0;
  const right = col === totalCols - 1;
  if (top && left) return '\u2554';
  if (top && right) return '\u2557';
  if (bottom && left) return '\u255a';
  if (bottom && right) return '\u255d';
  if (top || bottom) return '\u2550';
  return '\u2551';
}

function getSpaceAppearance(
  space: FloorSpace,
  row: number,
  col: number,
  totalRows: number,
  totalCols: number,
): SpaceAppearance {
  if (space.unit) {
    const appearance = getUnitAppearance(space.unit.name, space.unit.warrior);
    return { character: appearance.character, color: appearance.color };
  }
  if (space.wall) {
    return {
      character: getWallCharacter(row, col, totalRows, totalCols),
      color: 'gray',
    };
  }
  if (space.stairs) {
    return { character: '>', color: 'yellow' };
  }
  return { character: ' ', color: undefined };
}

export default getSpaceAppearance;
