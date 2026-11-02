import { type FloorSpace } from '@warriorjs/core';
import { Box, Text } from 'ink';
import type React from 'react';

import getSpaceAppearance from '../../../utils/getSpaceAppearance.js';

interface FloorMapProps {
  floorMap: FloorSpace[][];
}

export default function FloorMap({ floorMap }: FloorMapProps): React.ReactElement {
  const totalRows = floorMap.length;
  const totalCols = floorMap[0]?.length ?? 0;
  return (
    <Box flexDirection="column" marginX={1} marginY={1}>
      {floorMap.map((row, rowIndex) => (
        // biome-ignore lint/suspicious/noArrayIndexKey: static grid
        <Box key={rowIndex}>
          {row.map((space, colIndex) => {
            const { character, color } = getSpaceAppearance(
              space,
              rowIndex,
              colIndex,
              totalRows,
              totalCols,
            );
            return (
              // biome-ignore lint/suspicious/noArrayIndexKey: static grid
              <Text key={colIndex} color={color}>
                {character}
              </Text>
            );
          })}
        </Box>
      ))}
    </Box>
  );
}
