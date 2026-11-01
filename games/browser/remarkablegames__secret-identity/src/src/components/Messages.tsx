import type { UIMessage } from '@ai-sdk/react';
import clsx from 'clsx';
import { useEffect, useRef } from 'preact/hooks';

interface Props {
  messages: UIMessage[];
}

function getMessageText(message: UIMessage): string {
  return message.parts
    .filter(
      (part): part is { text: string; type: 'text' } => part.type === 'text',
    )
    .map((part) => part.text)
    .join('');
}

export default function Messages(props: Props) {
  const { messages } = props;
  const messagesRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (messagesRef.current) {
      messagesRef.current.scrollTop = messagesRef.current.scrollHeight;
    }
  }, [messages]);

  return (
    <div class="flex-1 space-y-4 overflow-auto px-6" ref={messagesRef}>
      {messages.map((message) => (
        <p
          key={message.id}
          class={clsx(
            'flex w-max max-w-[75%] flex-col gap-2 rounded-lg px-3 py-2 text-sm',
            (message.role === 'assistant' || message.role === 'system') &&
              'bg-gray-100',
            message.role === 'user' && 'ml-auto bg-blue-600 text-gray-100',
          )}
        >
          {getMessageText(message)}
        </p>
      ))}
    </div>
  );
}
