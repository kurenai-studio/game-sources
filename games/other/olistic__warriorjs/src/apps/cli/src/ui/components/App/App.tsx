import type React from 'react';
import { useState } from 'react';

import { type GameContext } from '../../../Game.js';
import type Profile from '../../../Profile.js';
import GameMenu from '../GameMenu/index.js';
import PlaySession from '../PlaySession/index.js';

interface AppProps {
  context: GameContext;
}

export default function App({ context }: AppProps): React.ReactElement {
  const [session, setSession] = useState<{
    profile: Profile;
    initialLevel: number;
  } | null>(null);

  if (session) {
    return (
      <PlaySession
        context={context}
        profile={session.profile}
        initialLevel={session.initialLevel}
      />
    );
  }

  return (
    <GameMenu
      context={context}
      onStart={(profile, level) => setSession({ profile, initialLevel: level })}
    />
  );
}
