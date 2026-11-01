it('exports expected values', async () => {
  const main = await import('./main');
  expect(main.EMOJIS).toEqual(['🍭', '🌈', '🦄', '⭐', '💎', '🍬']);
  expect(typeof main.startGame).toBe('function');
});
