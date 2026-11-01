jest.mock('../src/ui.js', () => ({
  setupUIButtons: jest.fn(),
  setupWindowResize: jest.fn(),
}));

jest.mock('../src/settings.js', () => ({
  setupSettings: jest.fn(),
  initializeTheme: jest.fn(),
  applyTheme: jest.fn(),
}));

jest.mock('../src/overlay.js', () => ({
  renderOverlayBricks: jest.fn(),
  enableSeamDrag: jest.fn(),
}));

describe('main entrypoint', () => {
  const startScreen = `
    <div id="startOverlay">
      <button id="startLight" data-theme-choice="light"></button>
      <button id="startDark" data-theme-choice="dark"></button>
    </div>`;

  beforeEach(() => {
    jest.clearAllMocks();
    jest.resetModules();
    document.body.innerHTML = '';

    jest.mock(
      'phaser',
      () => ({
        Game: jest.fn(() => ({})),
        AUTO: 'AUTO',
      }),
      { virtual: true }
    );
  });

  test('draws the start screen and waits for a look to be chosen', async () => {
    document.body.innerHTML = startScreen;

    const { initializeTheme } = await import('../src/settings.js');
    const { renderOverlayBricks, enableSeamDrag } =
      await import('../src/overlay.js');
    await import('../main.js');
    const { default: Phaser } = await import('phaser');

    expect(initializeTheme).toHaveBeenCalled();
    expect(renderOverlayBricks).toHaveBeenCalledTimes(1);
    expect(enableSeamDrag).toHaveBeenCalledTimes(1);
    expect(Phaser.Game).not.toHaveBeenCalled();
  });

  test('choosing a side starts the game in that look', async () => {
    document.body.innerHTML = startScreen;
    const startOverlay = document.getElementById('startOverlay');
    const startDark = document.getElementById('startDark');
    const startLight = document.getElementById('startLight');

    const { setupUIButtons, setupWindowResize } = await import('../src/ui.js');
    const { setupSettings, applyTheme } = await import('../src/settings.js');
    await import('../main.js');
    const { default: Phaser } = await import('phaser');

    // A finger may have left the seam off-centre before the choice.
    startOverlay.classList.add('is-dragging');
    startOverlay.style.setProperty('--split', '70%');

    jest.useFakeTimers();
    startDark.click();
    expect(startOverlay.style.getPropertyValue('--split')).toBe('');
    expect(startOverlay.classList.contains('is-dragging')).toBe(false);

    // The game waits for the chosen look to finish sweeping across.
    expect(Phaser.Game).not.toHaveBeenCalled();
    jest.advanceTimersByTime(550);
    jest.useRealTimers();
    await new Promise((resolve) => setTimeout(resolve, 0));

    expect(applyTheme).toHaveBeenCalledWith('dark');
    expect(startOverlay.dataset.chosen).toBe('dark');
    expect(startOverlay.classList.contains('hidden')).toBe(true);
    expect(startDark.disabled).toBe(true);
    expect(startLight.disabled).toBe(true);

    expect(Phaser.Game).toHaveBeenCalledTimes(1);
    const gameInstance = Phaser.Game.mock.instances[0];
    expect(setupUIButtons).toHaveBeenCalledWith(gameInstance);
    expect(setupWindowResize).toHaveBeenCalledWith(gameInstance);
    expect(setupSettings).toHaveBeenCalledWith(gameInstance);
  });

  test('the other side starts the other look', async () => {
    document.body.innerHTML = startScreen;

    const { applyTheme } = await import('../src/settings.js');
    await import('../main.js');

    jest.useFakeTimers();
    document.getElementById('startLight').click();
    jest.useRealTimers();

    expect(applyTheme).toHaveBeenCalledWith('light');
    expect(document.getElementById('startOverlay').dataset.chosen).toBe(
      'light'
    );
  });

  test('with no sweep to wait for, the game starts at once', async () => {
    document.body.innerHTML =
      '<button id="startDark" data-theme-choice="dark"></button>';

    await import('../main.js');
    const { default: Phaser } = await import('phaser');

    document.getElementById('startDark').click();
    await new Promise((resolve) => setTimeout(resolve, 0));

    expect(Phaser.Game).toHaveBeenCalledTimes(1);
  });

  test('reduced motion skips the sweep and starts at once', async () => {
    document.body.innerHTML = startScreen;
    window.matchMedia = jest.fn(() => ({ matches: true }));

    await import('../main.js');
    const { default: Phaser } = await import('phaser');

    document.getElementById('startLight').click();
    await new Promise((resolve) => setTimeout(resolve, 0));

    expect(window.matchMedia).toHaveBeenCalledWith(
      '(prefers-reduced-motion: reduce)'
    );
    expect(Phaser.Game).toHaveBeenCalledTimes(1);
    delete window.matchMedia;
  });
});
