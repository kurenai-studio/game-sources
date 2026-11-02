import { render } from 'ink-testing-library';
import { beforeEach, describe, expect, test, vi } from 'vitest';

import { type GameContext } from '../../../Game.js';
import type Profile from '../../../Profile.js';
import type Tower from '../../../Tower.js';
import { getLastContentFrame, waitForRender } from '../../../testing/index.js';
import GameMenu from './GameMenu.js';

vi.mock('./utils/getWarriorNameSuggestions.js', () => ({
  default: () => ['TestHero'],
}));

function createMockTower(name: string, overrides: Partial<Tower> = {}): Tower {
  return {
    id: name.toLowerCase().replace(/\s+/g, '-'),
    name,
    description: '',
    levels: [{}, {}, {}],
    hasLevel: (n: number) => n >= 1 && n <= 3,
    getLevel: (n: number) => (n >= 1 && n <= 3 ? {} : undefined),
    toString: () => name,
    ...overrides,
  } as unknown as Tower;
}

function createMockProfile(name: string, overrides: Partial<Profile> = {}): Profile {
  return {
    warriorName: name,
    tower: createMockTower('The Narrow Path'),
    directoryPath: `/tmp/warriorjs/${name.toLowerCase()}`,
    language: 'javascript',
    levelNumber: 1,
    score: 0,
    epic: false,
    isEpic: () => false,
    getReadmeFilePath: () => `/tmp/warriorjs/${name.toLowerCase()}/README.md`,
    makeProfileDirectory: vi.fn(),
    toString: () => name,
    ...overrides,
  } as unknown as Profile;
}

function createMockContext(overrides: Partial<GameContext> = {}): GameContext {
  return {
    version: 'v1.0.0',
    runDirectoryPath: '/tmp',
    practiceLevel: undefined,
    silencePlay: false,
    towers: [createMockTower('The Narrow Path')],
    profile: null,
    profiles: [],
    needsProfileSetup: true,
    onCreateProfile: vi.fn(() => createMockProfile('TestHero')),
    onIsExistingProfile: vi.fn(() => false),
    onPrepareNextLevel: vi.fn(),
    onPrepareEpicMode: vi.fn(),
    onGenerateProfileFiles: vi.fn(),
    onProfileSelected: vi.fn(),
    ...overrides,
  };
}

describe('GameMenu', () => {
  let onStart: ReturnType<typeof vi.fn<(profile: Profile, levelNumber: number) => void>>;

  beforeEach(() => {
    onStart = vi.fn<(profile: Profile, levelNumber: number) => void>();
  });

  test('renders error message when context has error', async () => {
    const context = createMockContext({
      error: 'Tower not found',
      needsProfileSetup: false,
    });

    const { frames } = render(<GameMenu context={context} onStart={onStart} />);
    await waitForRender();

    const output = getLastContentFrame(frames);
    expect(output).toContain('Tower not found');
    expect(onStart).not.toHaveBeenCalled();
  });

  test('calls onStart for returning player with existing profile', async () => {
    const profile = createMockProfile('Warrior', { levelNumber: 3 });
    const context = createMockContext({
      profile,
      needsProfileSetup: false,
    });

    render(<GameMenu context={context} onStart={onStart} />);
    await waitForRender();

    expect(context.onProfileSelected).toHaveBeenCalledWith(profile);
    expect(onStart).toHaveBeenCalledWith(profile, 3);
  });

  test('renders first-level message for returning player at level 0', async () => {
    const profile = createMockProfile('Warrior', { levelNumber: 0 });
    const context = createMockContext({
      profile,
      needsProfileSetup: false,
    });

    const { frames } = render(<GameMenu context={context} onStart={onStart} />);
    await waitForRender();

    const output = getLastContentFrame(frames);
    expect(output).toContain('Level 1 is ready');
    expect(output).toContain('README.md');
    expect(context.onPrepareNextLevel).toHaveBeenCalled();
    expect(onStart).not.toHaveBeenCalled();
  });

  test('renders start prompt for new player', async () => {
    const context = createMockContext({ needsProfileSetup: true, profiles: [] });

    const { lastFrame } = render(<GameMenu context={context} onStart={onStart} />);
    await waitForRender();

    const output = lastFrame()!;
    expect(output).toContain('A tower of enemies awaits');
    expect(output).toContain('Venture forth');
    expect(output).toContain('Retreat');
  });

  test('selecting "Venture forth" transitions to wizard', async () => {
    const context = createMockContext({ needsProfileSetup: true, profiles: [] });

    const { stdin, lastFrame } = render(<GameMenu context={context} onStart={onStart} />);
    await waitForRender();

    // Select "Venture forth" (first item, press enter).
    stdin.write('\r');
    await waitForRender();

    const output = lastFrame()!;
    expect(output).toContain('Venture forth');
    expect(output).toContain('Enter one for your warrior');
  });

  test('selecting "Retreat" shows exit message', async () => {
    const context = createMockContext({ needsProfileSetup: true, profiles: [] });

    const { stdin, frames } = render(<GameMenu context={context} onStart={onStart} />);
    await waitForRender();

    // Move down to "Retreat" and select.
    stdin.write('\x1B[B');
    await waitForRender();
    stdin.write('\r');
    await waitForRender();

    const output = getLastContentFrame(frames);
    expect(output).toContain('Even the bravest need a moment to prepare');
  });

  test('renders wizard with choose-profile when profiles exist', async () => {
    const profile = createMockProfile('Warrior1');
    const context = createMockContext({
      needsProfileSetup: true,
      profiles: [profile],
    });

    const { lastFrame } = render(<GameMenu context={context} onStart={onStart} />);
    await waitForRender();

    const output = lastFrame()!;
    expect(output).toContain('Which warrior answers the call?');
    expect(output).toContain('Warrior1');
  });

  test('renders error for practice level in normal mode', async () => {
    const profile = createMockProfile('Warrior', { levelNumber: 2 });
    const context = createMockContext({
      profile,
      needsProfileSetup: false,
      practiceLevel: 1,
    });

    const { frames } = render(<GameMenu context={context} onStart={onStart} />);
    await waitForRender();

    const output = getLastContentFrame(frames);
    expect(output).toContain('The -l option is only available in epic mode');
    expect(onStart).not.toHaveBeenCalled();
  });

  test('calls onStart with level 1 for epic mode', async () => {
    const profile = createMockProfile('Warrior', {
      epic: true,
      isEpic: () => true,
    });
    const context = createMockContext({
      profile,
      needsProfileSetup: false,
    });

    render(<GameMenu context={context} onStart={onStart} />);
    await waitForRender();

    expect(onStart).toHaveBeenCalledWith(profile, 1);
  });

  test('calls onStart with practice level for epic mode', async () => {
    const profile = createMockProfile('Warrior', {
      epic: true,
      isEpic: () => true,
    });
    const context = createMockContext({
      profile,
      needsProfileSetup: false,
      practiceLevel: 2,
    });

    render(<GameMenu context={context} onStart={onStart} />);
    await waitForRender();

    expect(onStart).toHaveBeenCalledWith(profile, 2);
  });

  test('renders error for invalid practice level in epic mode', async () => {
    const tower = createMockTower('The Narrow Path', {
      levels: [{}, {}, {}] as Tower['levels'],
      hasLevel: (n: number) => n >= 1 && n <= 3,
    });
    const profile = createMockProfile('Warrior', {
      epic: true,
      isEpic: () => true,
      tower,
    });
    const context = createMockContext({
      profile,
      needsProfileSetup: false,
      practiceLevel: 10,
    });

    const { frames } = render(<GameMenu context={context} onStart={onStart} />);
    await waitForRender();

    const output = getLastContentFrame(frames);
    expect(output).toContain("Level 10 doesn't exist");
    expect(output).toContain('3 levels');
    expect(onStart).not.toHaveBeenCalled();
  });
});
