import { isMobile, overMaxGuesses } from 'src/helpers';
import { drop, tick } from 'src/sounds';

import SubmitButton from './SubmitButton';

interface Props {
  isLoading: boolean;
  onChange: (event: Event) => void;
  onSubmit: (event: Event) => void;
  value: string;
}

export default function Form(props: Props) {
  return (
    <form
      class="flex w-full space-x-2 p-6"
      onSubmit={(event) => {
        props.onSubmit(event);
        drop.play();
      }}
    >
      <input
        autocomplete="off"
        class="border-input flex h-9 w-full flex-1 rounded-md border bg-transparent px-3 py-1 text-base shadow-xs transition-colors focus-visible:border-blue-400 focus-visible:outline-hidden disabled:cursor-not-allowed disabled:opacity-50"
        onInput={(event) => {
          props.onChange(event);
          if (!isMobile) {
            tick.play();
          }
        }}
        placeholder="Type your guess..."
        value={props.value}
      />

      <SubmitButton disabled={props.isLoading || overMaxGuesses()} />
    </form>
  );
}
