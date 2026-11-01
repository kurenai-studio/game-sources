/**
 * Generates a pattern of unique cell indices for a round.
 *
 * @param cellCount - Total number of cells in the grid.
 * @param patternSize - Number of cells to light up.
 * @param random - Random source, injectable for tests.
 * @returns Sorted, unique cell indices, clamped to the grid bounds.
 */
export function createPattern(
  cellCount: number,
  patternSize: number,
  random: () => number = Math.random,
): number[] {
  const size = Math.min(Math.max(patternSize, 0), cellCount);
  const cells = Array.from({ length: cellCount }, (_, index) => index);

  // Partial Fisher-Yates: shuffle the first `size` slots into place.
  for (let i = 0; i < size; i++) {
    const j = i + Math.floor(random() * (cellCount - i));
    [cells[i], cells[j]] = [cells[j], cells[i]];
  }

  return cells.slice(0, size).sort((a, b) => a - b);
}
