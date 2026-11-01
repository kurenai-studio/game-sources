import { timingSafeEqual } from "node:crypto";
import { revalidatePath } from "next/cache";

function sameSecret(given: string | null, expected: string): boolean {
  if (!given) return false;
  const a = Buffer.from(given);
  const b = Buffer.from(expected);
  return a.length === b.length && timingSafeEqual(a, b);
}

/**
 * Called by the API after a publish, unpublish, or reorder so the public pages refresh at once
 * instead of waiting for their timed revalidation. Disabled unless REVALIDATE_SECRET is set.
 */
export async function POST(request: Request): Promise<Response> {
  const secret = process.env.REVALIDATE_SECRET;
  if (!secret) return new Response(null, { status: 404 });
  if (!sameSecret(request.headers.get("x-revalidate-secret"), secret)) {
    return new Response(null, { status: 401 });
  }
  revalidatePath("/levels");
  revalidatePath("/contact");
  return Response.json({ revalidated: true });
}
