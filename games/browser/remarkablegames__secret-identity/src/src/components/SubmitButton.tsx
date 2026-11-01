import SendIcon from './SendIcon';
import Spinner from './Spinner';

export default function SubmitButton({ disabled = false }) {
  return (
    <button
      class="inline-flex h-9 w-9 items-center justify-center gap-2 rounded-md text-sm font-medium whitespace-nowrap shadow-sm transition-colors hover:border hover:border-blue-400 hover:bg-blue-50 focus-visible:outline-hidden disabled:pointer-events-none disabled:opacity-50"
      disabled={disabled}
      type="submit"
    >
      {disabled ? <Spinner /> : <SendIcon />}
    </button>
  );
}
