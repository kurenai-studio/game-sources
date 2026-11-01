import {
  convertToModelMessages,
  createUIMessageStreamResponse,
  streamText,
  toUIMessageStream,
  type UIMessage,
} from 'ai';
import { createWorkersAI } from 'workers-ai-provider';

interface Env {
  AI: Ai;
  NODE_ENV: 'development' | 'preview' | 'production';
}

const PROMPT =
  "You are secretly a well-known superhero from Marvel or DC comics. Pick one hero and commit to that identity for the entire conversation. Never change who you are. The player gets exactly 5 questions to guess your secret identity. Keep count of how many questions the player has asked. After each answer, remind them how many questions they have left (e.g. '4 left'). You can offer clues as long as you don't reveal who you are. If the player guesses correctly, congratulate them and confirm your identity. After 5 questions without a correct guess, reveal who you are and tell them they lost. Only use real, well-known superhero characters. Do not invent fictional heroes. Only state facts that are true about this character in official canon. Respond in plain text only. Do not use markdown, bullet points, numbered lists, or any formatting. Write casually like a text message.";

const MAX_TOKENS = 150;

/**
 * POST /api/chat
 *
 * @param context - Event context.
 * @returns - Response.
 */
export const onRequestPost: PagesFunction<Env> = async (context) => {
  try {
    const { messages } = await context.request.json<{
      messages: UIMessage[];
    }>();

    const workersai = createWorkersAI({ binding: context.env.AI });

    // https://sdk.vercel.ai/providers/community-providers/cloudflare-workers-ai#streamtext
    const result = streamText({
      model: workersai('@cf/meta/llama-3.1-8b-instruct-fp8'),
      maxOutputTokens: MAX_TOKENS,
      temperature: 0.6,
      instructions: PROMPT,
      messages: await convertToModelMessages(messages),
    });

    return createUIMessageStreamResponse({
      stream: toUIMessageStream({ stream: result.stream }),
      ...getResponseInit(context),
    });
  } catch (error) {
    // InferenceUpstreamError: you have used up your daily free allocation of 10,000 neurons, please upgrade to Cloudflare's Workers Paid plan if you would like to continue usage.
    if (
      error instanceof Error &&
      /you have used up your daily free allocation/.test(error.message)
    ) {
      return new Response('Daily quota exceeded.', {
        ...getResponseInit(context),
        status: 429,
      });
    } else {
      throw error;
    }
  }
};

/**
 * OPTIONS /api/chat
 *
 * @param context - Event context.
 * @returns - Response.
 */
export const onRequestOptions: PagesFunction<Env> = async (context) => {
  return new Response(null, { ...getResponseInit(context), status: 204 });
};

/**
 * Get response init.
 *
 * @param context - Event context.
 * @returns - Response init.
 */
function getResponseInit(
  context: EventContext<Env, '', unknown>,
): ResponseInit {
  if (context.env.NODE_ENV === 'development') {
    return {
      headers: {
        'Access-Control-Allow-Headers': '*',
        'Access-Control-Allow-Origin': '*',
      },
    };
  }
  return {};
}
