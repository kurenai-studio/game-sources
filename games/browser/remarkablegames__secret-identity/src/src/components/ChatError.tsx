interface Props {
  error?: Error;
  reload: () => void;
}

export default function ChatError(props: Props) {
  const { error, reload } = props;

  if (!error) {
    return null;
  }

  return (
    <p
      class="mb-4 flex items-center justify-between rounded-sm border border-red-200 bg-red-100 px-4 py-2 text-red-700"
      role="alert"
    >
      <span>{error.message || 'An error occurred.'}</span>

      <button
        class="w-16 rounded-md bg-white px-4 py-2 text-sm font-medium text-black shadow-sm hover:bg-gray-50 focus-visible:ring-1 focus-visible:outline-hidden"
        type="button"
        onClick={reload}
      >
        Retry
      </button>
    </p>
  );
}
