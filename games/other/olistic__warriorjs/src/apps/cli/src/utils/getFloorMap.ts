import { type FloorSpace } from '@warriorjs/core';

import getSpaceAppearance from './getSpaceAppearance.js';

function getFloorMap(map: FloorSpace[][]): string {
  const totalRows = map.length;
  const totalCols = map[0]?.length ?? 0;
  return map
    .map((row, rowIndex) =>
      row
        .map(
          (space, colIndex) =>
            getSpaceAppearance(space, rowIndex, colIndex, totalRows, totalCols).character,
        )
        .join(''),
    )
    .join('\n');
}

export default getFloorMap;
