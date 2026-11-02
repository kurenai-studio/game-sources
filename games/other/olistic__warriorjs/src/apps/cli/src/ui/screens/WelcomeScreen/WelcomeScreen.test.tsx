import { render } from 'ink-testing-library';
import { describe, expect, test } from 'vitest';

// @ts-expect-error -- JSON import
import { version } from '../../../../package.json';
import WelcomeScreen from './WelcomeScreen.js';

describe('WelcomeScreen', () => {
  test('renders warrior art, title, version, and directory', () => {
    const versionString = `v${version}`;
    const { lastFrame } = render(
      <WelcomeScreen version={versionString} directory="~/Projects/warriorjs" />,
    );
    const output = lastFrame()!;
    expect(output).toContain('WarriorJS');
    expect(output).toContain(versionString);
    expect(output).toContain('~/Projects/warriorjs');
  });
});
