import { render } from 'ink';
import React from 'react';

import Game from './Game.js';
import parseArgs from './parseArgs.js';
import App from './ui/components/App/index.js';

/**
 * Starts the game.
 *
 * @param args The command line arguments.
 */
async function run(args: string[]): Promise<void> {
  const { directory, level, silent } = parseArgs(args);
  const game = new Game(directory, level, silent);
  const context = game.buildContext();

  const { waitUntilExit } = render(React.createElement(App, { context }));
  await waitUntilExit();
}

export { run };
