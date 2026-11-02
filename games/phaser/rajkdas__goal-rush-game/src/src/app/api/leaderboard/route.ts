/**
 * GOAL RUSH — leaderboard API.
 *
 * GET  /api/leaderboard        → top 10 by credits
 * POST /api/leaderboard        → submit { initials, credits, spins }
 *
 * Validation with zod, in-memory per-IP rate limiting (1 submit / 5 s) —
 * proportionate protection for an arcade leaderboard.
 */

import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { db } from '@/lib/db';

// Never prerender/cache this handler: on a fresh host the DB file may not
// exist yet at build time (start command creates it), and scores change constantly.
export const dynamic = 'force-dynamic';

const SubmitSchema = z.object({
  initials: z
    .string()
    .trim()
    .toUpperCase()
    .regex(/^[A-Z0-9]{2,3}$/, 'Initials must be 2-3 letters or digits'),
  credits: z.number().int().min(0).max(10_000_000),
  spins: z.number().int().min(0).max(10_000).default(0),
});

const lastSubmitByIp = new Map<string, number>();
const RATE_LIMIT_MS = 5000;

function clientIp(req: NextRequest): string {
  return (
    req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ??
    req.headers.get('x-real-ip') ??
    'local'
  );
}

export async function GET() {
  try {
    const scores = await db.score.findMany({
      orderBy: [{ credits: 'desc' }, { createdAt: 'asc' }],
      take: 10,
    });
    return NextResponse.json({ scores });
  } catch (error) {
    console.error('leaderboard GET failed', error);
    return NextResponse.json({ error: 'Leaderboard unavailable' }, { status: 500 });
  }
}

export async function POST(req: NextRequest) {
  const ip = clientIp(req);
  const now = Date.now();
  const last = lastSubmitByIp.get(ip) ?? 0;
  if (now - last < RATE_LIMIT_MS) {
    return NextResponse.json({ error: 'Too many submissions' }, { status: 429 });
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 });
  }

  const parsed = SubmitSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues[0]?.message ?? 'Invalid payload' },
      { status: 400 }
    );
  }

  try {
    const score = await db.score.create({
      data: {
        initials: parsed.data.initials,
        credits: parsed.data.credits,
        spins: parsed.data.spins,
      },
    });
    lastSubmitByIp.set(ip, now);
    // Trim: keep the table lean (best 200 rows).
    const count = await db.score.count();
    if (count > 200) {
      const overflow = await db.score.findMany({
        orderBy: [{ credits: 'desc' }, { createdAt: 'asc' }],
        skip: 200,
        take: count - 200,
        select: { id: true },
      });
      await db.score.deleteMany({ where: { id: { in: overflow.map((s) => s.id) } } });
    }
    return NextResponse.json({ score }, { status: 201 });
  } catch (error) {
    console.error('leaderboard POST failed', error);
    return NextResponse.json({ error: 'Could not save score' }, { status: 500 });
  }
}
