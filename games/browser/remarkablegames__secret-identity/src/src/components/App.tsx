import { MAX_GUESSES } from 'src/constants';
import { overMaxGuesses } from 'src/helpers';

import Chat from './Chat';

export default function App() {
  return (
    <section class="flex h-screen flex-col rounded-xl bg-white sm:h-[70vh] sm:border sm:shadow-sm">
      {overMaxGuesses() ? (
        <div class="flex h-screen flex-col items-center justify-center">
          <img alt="Incognito" class="mb-4 h-10 w-10" src="/incognito.svg" />
          <p class="mb-1 text-4xl">Thanks for playing!</p>
          <p class="text-lg text-gray-600 italic">
            You can only guess <span class="font-bold">{MAX_GUESSES}</span>{' '}
            times per day.
          </p>
        </div>
      ) : (
        <Chat />
      )}
    </section>
  );
}
