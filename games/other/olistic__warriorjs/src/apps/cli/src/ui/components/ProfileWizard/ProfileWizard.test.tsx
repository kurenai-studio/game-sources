import { render } from 'ink-testing-library';
import { beforeEach, describe, expect, test, vi } from 'vitest';

import { type GameContext } from '../../../Game.js';
import type Profile from '../../../Profile.js';
import type Tower from '../../../Tower.js';
import { waitForRender } from '../../../testing/index.js';
import ProfileWizard from './ProfileWizard.js';

function createMockTower(name: string): Tower {
  return {
    toString: () => name,
  } as unknown as Tower;
}

function createMockProfile(name: string): Profile {
  return {
    toString: () => name,
    makeProfileDirectory: vi.fn(),
  } as unknown as Profile;
}

function createMockContext(overrides: Partial<GameContext> = {}): GameContext {
  return {
    version: '1.0.0',
    runDirectoryPath: '/tmp',
    practiceLevel: undefined,
    silencePlay: false,
    towers: [createMockTower('The Narrow Path')],
    profile: null,
    profiles: [],
    needsProfileSetup: true,
    onCreateProfile: vi.fn(() => createMockProfile('TestWarrior - The Narrow Path')),
    onIsExistingProfile: vi.fn(() => false),
    onPrepareNextLevel: vi.fn(),
    onPrepareEpicMode: vi.fn(),
    onGenerateProfileFiles: vi.fn(),
    onProfileSelected: vi.fn(),
    ...overrides,
  };
}

describe('ProfileWizard', () => {
  let onComplete: ReturnType<typeof vi.fn<(profile: Profile) => void>>;
  let onCancel: ReturnType<typeof vi.fn<() => void>>;
  let onError: ReturnType<typeof vi.fn<(message: string) => void>>;

  beforeEach(() => {
    onComplete = vi.fn<(profile: Profile) => void>();
    onCancel = vi.fn<() => void>();
    onError = vi.fn<(message: string) => void>();
  });

  describe('choose-profile step', () => {
    test('renders existing profiles and "New profile" option', () => {
      const profile1 = createMockProfile('Warrior1 - Tower1');
      const profile2 = createMockProfile('Warrior2 - Tower2');
      const context = createMockContext({ profiles: [profile1, profile2] });

      const { lastFrame } = render(
        <ProfileWizard
          context={context}
          suggestedName="Hero"
          initialStep="choose-profile"
          onComplete={onComplete}
          onCancel={onCancel}
          onError={onError}
        />,
      );
      const output = lastFrame()!;
      expect(output).toContain('Warrior1 - Tower1');
      expect(output).toContain('Warrior2 - Tower2');
      expect(output).toContain('New profile');
      expect(output).toContain('Which warrior answers the call?');
    });

    test('selecting an existing profile calls onComplete', async () => {
      const profile = createMockProfile('Warrior1 - Tower1');
      const context = createMockContext({ profiles: [profile] });

      const { stdin, lastFrame } = render(
        <ProfileWizard
          context={context}
          suggestedName="Hero"
          initialStep="choose-profile"
          onComplete={onComplete}
          onCancel={onCancel}
          onError={onError}
        />,
      );

      // First item is selected by default, press enter.
      await waitForRender();
      stdin.write('\r');
      await waitForRender();

      expect(lastFrame()!).toContain('Warrior1 - Tower1');
      expect(onComplete).toHaveBeenCalledWith(profile);
    });

    test('selecting "New profile" transitions to name input', async () => {
      const profile = createMockProfile('Warrior1 - Tower1');
      const context = createMockContext({ profiles: [profile] });

      const { stdin, lastFrame } = render(
        <ProfileWizard
          context={context}
          suggestedName="Hero"
          initialStep="choose-profile"
          onComplete={onComplete}
          onCancel={onCancel}
          onError={onError}
        />,
      );

      // Move down past the profile and separator to "New profile".
      await waitForRender();
      stdin.write('\x1B[B');
      await waitForRender();
      stdin.write('\r');
      await waitForRender();

      const output = lastFrame()!;
      expect(output).toContain('Enter one for your warrior');
      expect(output).toContain('New profile');
    });
  });

  describe('create-name step', () => {
    test('renders name input with suggested name as default', () => {
      const context = createMockContext();

      const { lastFrame } = render(
        <ProfileWizard
          context={context}
          suggestedName="Hero"
          initialStep="new"
          onComplete={onComplete}
          onCancel={onCancel}
          onError={onError}
        />,
      );
      const output = lastFrame()!;
      expect(output).toContain('Enter one for your warrior');
      expect(output).toContain('Hero');
    });

    test('typing a name and submitting transitions to language selection', async () => {
      const context = createMockContext();

      const { stdin, lastFrame } = render(
        <ProfileWizard
          context={context}
          suggestedName=""
          initialStep="new"
          onComplete={onComplete}
          onCancel={onCancel}
          onError={onError}
        />,
      );

      await waitForRender();
      stdin.write('Braveheart');
      await waitForRender();
      stdin.write('\r');
      await waitForRender();

      const output = lastFrame()!;
      expect(output).toContain('Choose your language');
      expect(output).toContain('Braveheart');
    });

    test('submitting with default name uses suggested name', async () => {
      const context = createMockContext();

      const { stdin, lastFrame } = render(
        <ProfileWizard
          context={context}
          suggestedName="Hero"
          initialStep="new"
          onComplete={onComplete}
          onCancel={onCancel}
          onError={onError}
        />,
      );

      await waitForRender();
      stdin.write('\r');
      await waitForRender();

      const output = lastFrame()!;
      expect(output).toContain('Choose your language');
      expect(output).toContain('Hero');
    });

    test('submitting empty name with no default shows error', async () => {
      const context = createMockContext();

      const { stdin, lastFrame } = render(
        <ProfileWizard
          context={context}
          suggestedName=""
          initialStep="new"
          onComplete={onComplete}
          onCancel={onCancel}
          onError={onError}
        />,
      );

      await waitForRender();
      stdin.write('\r');
      await waitForRender();

      const output = lastFrame()!;
      expect(output).toContain('A warrior without a name is just a shadow');
    });

    test('escape from name step when from "new" calls onCancel', async () => {
      const context = createMockContext();

      const { stdin } = render(
        <ProfileWizard
          context={context}
          suggestedName="Hero"
          initialStep="new"
          onComplete={onComplete}
          onCancel={onCancel}
          onError={onError}
        />,
      );

      await waitForRender();
      stdin.write('\x1B');
      await waitForRender();

      expect(onCancel).toHaveBeenCalled();
    });

    test('escape from name step when from "choose-profile" goes back to choose-profile', async () => {
      const profile = createMockProfile('Warrior1 - Tower1');
      const context = createMockContext({ profiles: [profile] });

      const { stdin, lastFrame } = render(
        <ProfileWizard
          context={context}
          suggestedName="Hero"
          initialStep="choose-profile"
          onComplete={onComplete}
          onCancel={onCancel}
          onError={onError}
        />,
      );

      // Navigate to "New profile" and select it.
      await waitForRender();
      stdin.write('\x1B[B');
      await waitForRender();
      stdin.write('\r');
      await waitForRender();

      // Verify we transitioned to name step (history entry for the selection was added).
      expect(lastFrame()!).toContain('Enter one for your warrior');

      // Now we should be on the name step, press escape to go back.
      stdin.write('\x1B');
      await waitForRender();

      const output = lastFrame()!;
      expect(output).toContain('Which warrior answers the call?');
    });
  });

  describe('create-name-error step', () => {
    test('dismissing error goes back to name input', async () => {
      const context = createMockContext();

      const { stdin, lastFrame } = render(
        <ProfileWizard
          context={context}
          suggestedName=""
          initialStep="new"
          onComplete={onComplete}
          onCancel={onCancel}
          onError={onError}
        />,
      );

      // Submit empty name to trigger error.
      await waitForRender();
      stdin.write('\r');
      await waitForRender();

      expect(lastFrame()!).toContain('A warrior without a name is just a shadow');

      // Press any key to dismiss.
      stdin.write(' ');
      await waitForRender();

      const output = lastFrame()!;
      expect(output).toContain('Enter one for your warrior');
    });
  });

  describe('create-language step', () => {
    test('renders language options', async () => {
      const context = createMockContext();

      const { stdin, lastFrame } = render(
        <ProfileWizard
          context={context}
          suggestedName="Hero"
          initialStep="new"
          onComplete={onComplete}
          onCancel={onCancel}
          onError={onError}
        />,
      );

      // Submit default name.
      await waitForRender();
      stdin.write('\r');
      await waitForRender();

      const output = lastFrame()!;
      expect(output).toContain('Choose your language');
      expect(output).toContain('TypeScript (recommended)');
      expect(output).toContain('JavaScript');
    });

    test('selecting TypeScript transitions to tower selection', async () => {
      const context = createMockContext();

      const { stdin, lastFrame } = render(
        <ProfileWizard
          context={context}
          suggestedName="Hero"
          initialStep="new"
          onComplete={onComplete}
          onCancel={onCancel}
          onError={onError}
        />,
      );

      // Submit name.
      await waitForRender();
      stdin.write('\r');
      await waitForRender();

      // Select TypeScript (default).
      stdin.write('\r');
      await waitForRender();

      const output = lastFrame()!;
      expect(output).toContain('Choose a tower');
      expect(output).toContain('TypeScript');
    });

    test('selecting JavaScript transitions to tower selection', async () => {
      const context = createMockContext();

      const { stdin, lastFrame } = render(
        <ProfileWizard
          context={context}
          suggestedName="Hero"
          initialStep="new"
          onComplete={onComplete}
          onCancel={onCancel}
          onError={onError}
        />,
      );

      // Submit name.
      await waitForRender();
      stdin.write('\r');
      await waitForRender();

      // Move to JavaScript and select.
      stdin.write('\x1B[B');
      await waitForRender();
      stdin.write('\r');
      await waitForRender();

      const output = lastFrame()!;
      expect(output).toContain('Choose a tower');
      expect(output).toContain('JavaScript');
    });

    test('escape from language goes back to name input', async () => {
      const context = createMockContext();

      const { stdin, lastFrame } = render(
        <ProfileWizard
          context={context}
          suggestedName="Hero"
          initialStep="new"
          onComplete={onComplete}
          onCancel={onCancel}
          onError={onError}
        />,
      );

      // Submit name.
      await waitForRender();
      stdin.write('\r');
      await waitForRender();

      // Verify history entry was added.
      expect(lastFrame()!).toContain('Hero');

      // Escape from language.
      stdin.write('\x1B');
      await waitForRender();

      const output = lastFrame()!;
      expect(output).toContain('Enter one for your warrior');
    });
  });

  describe('create-tower step', () => {
    test('renders tower options', async () => {
      const tower1 = createMockTower('The Narrow Path');
      const tower2 = createMockTower('The Powder Keep');
      const context = createMockContext({ towers: [tower1, tower2] });

      const { stdin, lastFrame } = render(
        <ProfileWizard
          context={context}
          suggestedName="Hero"
          initialStep="new"
          onComplete={onComplete}
          onCancel={onCancel}
          onError={onError}
        />,
      );

      // Submit name, then select language.
      await waitForRender();
      stdin.write('\r');
      await waitForRender();
      stdin.write('\r');
      await waitForRender();

      const output = lastFrame()!;
      expect(output).toContain('Choose a tower');
      expect(output).toContain('The Narrow Path');
      expect(output).toContain('The Powder Keep');
    });

    test('selecting tower with no existing profile completes wizard', async () => {
      const tower = createMockTower('The Narrow Path');
      const mockProfile = createMockProfile('Hero - The Narrow Path');
      const context = createMockContext({
        towers: [tower],
        onCreateProfile: vi.fn(() => mockProfile),
        onIsExistingProfile: vi.fn(() => false),
      });

      const { stdin } = render(
        <ProfileWizard
          context={context}
          suggestedName="Hero"
          initialStep="new"
          onComplete={onComplete}
          onCancel={onCancel}
          onError={onError}
        />,
      );

      // Submit name, select language, select tower.
      await waitForRender();
      stdin.write('\r');
      await waitForRender();
      stdin.write('\r');
      await waitForRender();
      stdin.write('\r');
      await waitForRender();

      expect(context.onCreateProfile).toHaveBeenCalledWith('Hero', 'typescript', tower);
      expect(context.onIsExistingProfile).toHaveBeenCalledWith(mockProfile);
      expect(mockProfile.makeProfileDirectory).toHaveBeenCalled();
      expect(onComplete).toHaveBeenCalledWith(mockProfile);
    });

    test('selecting tower with existing profile shows confirm-replace', async () => {
      const tower = createMockTower('The Narrow Path');
      const mockProfile = createMockProfile('Hero - The Narrow Path');
      const context = createMockContext({
        towers: [tower],
        onCreateProfile: vi.fn(() => mockProfile),
        onIsExistingProfile: vi.fn(() => true),
      });

      const { stdin, lastFrame } = render(
        <ProfileWizard
          context={context}
          suggestedName="Hero"
          initialStep="new"
          onComplete={onComplete}
          onCancel={onCancel}
          onError={onError}
        />,
      );

      // Submit name, select language, select tower.
      await waitForRender();
      stdin.write('\r');
      await waitForRender();
      stdin.write('\r');
      await waitForRender();
      stdin.write('\r');
      await waitForRender();

      const output = lastFrame()!;
      expect(output).toContain('already climbing');
      expect(output).toContain('The Narrow Path');
      expect(output).toContain('Do you want to replace');
      expect(onComplete).not.toHaveBeenCalled();
    });

    test('escape from tower goes back to language selection', async () => {
      const context = createMockContext();

      const { stdin, lastFrame } = render(
        <ProfileWizard
          context={context}
          suggestedName="Hero"
          initialStep="new"
          onComplete={onComplete}
          onCancel={onCancel}
          onError={onError}
        />,
      );

      // Submit name, select language.
      await waitForRender();
      stdin.write('\r');
      await waitForRender();
      stdin.write('\r');
      await waitForRender();

      // Verify history entries exist.
      expect(lastFrame()!).toContain('TypeScript');

      // Escape from tower.
      stdin.write('\x1B');
      await waitForRender();

      const output = lastFrame()!;
      expect(output).toContain('Choose your language');
    });

    test('escape from tower after selecting JavaScript restores language index', async () => {
      const context = createMockContext();

      const { stdin, lastFrame } = render(
        <ProfileWizard
          context={context}
          suggestedName="Hero"
          initialStep="new"
          onComplete={onComplete}
          onCancel={onCancel}
          onError={onError}
        />,
      );

      // Submit name.
      await waitForRender();
      stdin.write('\r');
      await waitForRender();

      // Select JavaScript (index ).
      stdin.write('\x1B[B');
      await waitForRender();
      stdin.write('\r');
      await waitForRender();

      // Escape from tower to go back to language.
      stdin.write('\x1B');
      await waitForRender();

      const output = lastFrame()!;
      expect(output).toContain('Choose your language');
      // JavaScript should be pre-selected (indicator on JavaScript line).
      expect(output).toContain('JavaScript');
    });
  });

  describe('create-confirm-replace step', () => {
    test('confirming replace calls onComplete', async () => {
      const tower = createMockTower('The Narrow Path');
      const mockProfile = createMockProfile('Hero - The Narrow Path');
      const context = createMockContext({
        towers: [tower],
        onCreateProfile: vi.fn(() => mockProfile),
        onIsExistingProfile: vi.fn(() => true),
      });

      const { stdin } = render(
        <ProfileWizard
          context={context}
          suggestedName="Hero"
          initialStep="new"
          onComplete={onComplete}
          onCancel={onCancel}
          onError={onError}
        />,
      );

      // Submit name, select language, select tower.
      await waitForRender();
      stdin.write('\r');
      await waitForRender();
      stdin.write('\r');
      await waitForRender();
      stdin.write('\r');
      await waitForRender();

      // Confirm replace with 'y'.
      stdin.write('y');
      await waitForRender();

      expect(context.onCreateProfile).toHaveBeenCalledTimes(2);
      expect(onComplete).toHaveBeenCalledWith(mockProfile);
    });

    test('declining replace calls onError', async () => {
      const tower = createMockTower('The Narrow Path');
      const mockProfile = createMockProfile('Hero - The Narrow Path');
      const context = createMockContext({
        towers: [tower],
        onCreateProfile: vi.fn(() => mockProfile),
        onIsExistingProfile: vi.fn(() => true),
      });

      const { stdin } = render(
        <ProfileWizard
          context={context}
          suggestedName="Hero"
          initialStep="new"
          onComplete={onComplete}
          onCancel={onCancel}
          onError={onError}
        />,
      );

      // Submit name, select language, select tower.
      await waitForRender();
      stdin.write('\r');
      await waitForRender();
      stdin.write('\r');
      await waitForRender();
      stdin.write('\r');
      await waitForRender();

      // Decline replace with 'n'.
      stdin.write('n');
      await waitForRender();

      expect(onComplete).not.toHaveBeenCalled();
      expect(onError).toHaveBeenCalledWith('Unable to continue without a profile.');
    });
  });

  describe('full flow', () => {
    test('complete flow from new: name -> language -> tower -> done', async () => {
      const tower = createMockTower('The Narrow Path');
      const mockProfile = createMockProfile('Braveheart - The Narrow Path');
      const context = createMockContext({
        towers: [tower],
        onCreateProfile: vi.fn(() => mockProfile),
        onIsExistingProfile: vi.fn(() => false),
      });

      const { stdin, lastFrame } = render(
        <ProfileWizard
          context={context}
          suggestedName=""
          initialStep="new"
          onComplete={onComplete}
          onCancel={onCancel}
          onError={onError}
        />,
      );

      // Type name.
      await waitForRender();
      stdin.write('Braveheart');
      await waitForRender();
      stdin.write('\r');
      await waitForRender();

      // Select TypeScript.
      stdin.write('\r');
      await waitForRender();

      // Select tower.
      stdin.write('\r');
      await waitForRender();

      expect(context.onCreateProfile).toHaveBeenCalledWith('Braveheart', 'typescript', tower);
      expect(mockProfile.makeProfileDirectory).toHaveBeenCalled();
      expect(onComplete).toHaveBeenCalledWith(mockProfile);
      // Verify history entries are rendered.
      const output = lastFrame()!;
      expect(output).toContain('Braveheart');
      expect(output).toContain('TypeScript');
      expect(output).toContain('The Narrow Path');
    });

    test('complete flow from choose-profile: select existing -> done', async () => {
      const profile = createMockProfile('Warrior1 - Tower1');
      const context = createMockContext({ profiles: [profile] });

      const { stdin, lastFrame } = render(
        <ProfileWizard
          context={context}
          suggestedName="Hero"
          initialStep="choose-profile"
          onComplete={onComplete}
          onCancel={onCancel}
          onError={onError}
        />,
      );

      await waitForRender();
      stdin.write('\r');
      await waitForRender();

      expect(onComplete).toHaveBeenCalledWith(profile);
      // Verify history entry is rendered.
      expect(lastFrame()!).toContain('Warrior1 - Tower1');
    });
  });
});
