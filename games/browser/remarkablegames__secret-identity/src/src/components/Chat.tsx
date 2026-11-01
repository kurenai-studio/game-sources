import { type UIMessage, useChat } from '@ai-sdk/react';
import { DefaultChatTransport } from 'ai';
import { useState } from 'preact/hooks';
import { API_URL, DEV } from 'src/constants';
import { incrementGuesses, overMaxGuesses } from 'src/helpers';
import { confirmation } from 'src/sounds';

import ChatError from './ChatError';
import Form from './Form';
import Header from './Header';
import Messages from './Messages';

const INITIAL_MESSAGE: UIMessage = {
  id: '1',
  role: 'assistant',
  parts: [
    {
      type: 'text',
      text: "I'm a superhero. Can you guess my secret identity?",
    },
  ],
};

export default function Chat() {
  const [input, setInput] = useState('');
  const { error, messages, regenerate, sendMessage, status } = useChat({
    transport: new DefaultChatTransport({
      api: `${API_URL}/api/chat`,
    }),
    messages: [INITIAL_MESSAGE],

    onFinish() {
      confirmation.play();
      incrementGuesses();
      if (overMaxGuesses()) {
        setTimeout(() => location.reload(), 10000);
      }
    },

    onError(error: Error) {
      if (DEV) {
        // eslint-disable-next-line no-console
        console.error(error);
      }
    },
  });

  const isLoading = status === 'submitted' || status === 'streaming';

  const handleSubmit = (event: Event) => {
    event.preventDefault();
    if (!input.trim() || isLoading) {
      return;
    }
    sendMessage({ text: input });
    setInput('');
  };

  return (
    <>
      <Header />
      <ChatError error={error} reload={regenerate} />
      <Messages messages={messages} />
      <Form
        isLoading={isLoading}
        onChange={(event: Event) =>
          setInput((event.currentTarget as HTMLInputElement).value)
        }
        onSubmit={handleSubmit}
        value={input}
      />
    </>
  );
}
