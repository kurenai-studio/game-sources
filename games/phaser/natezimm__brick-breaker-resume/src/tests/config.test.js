describe('config', () => {
  beforeAll(() => {
    Object.defineProperty(window, 'innerWidth', {
      writable: true,
      value: 1024,
    });
    Object.defineProperty(window, 'innerHeight', {
      writable: true,
      value: 768,
    });
  });

  test('builds Phaser configuration from window dimensions', async () => {
    const { createConfig } = await import('../src/config.js');
    const MockPhaser = { AUTO: 'AUTO' };
    const config = createConfig(MockPhaser);

    expect(config.type).toBe('AUTO');
    expect(config.width).toBe(1024);
    expect(config.height).toBe(768);
    expect(config.scene).toHaveProperty('preload');
    expect(config.scene).toHaveProperty('create');
    expect(config.scene).toHaveProperty('update');
  });
});
