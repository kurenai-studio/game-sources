// GOAL RUSH — demo leaderboard seed.
//
// Free hosts (Render free tier, etc.) have an ephemeral disk: every fresh
// boot starts with an empty database. This script inserts a few arcade-style
// scores IF the Score table is empty, so a fresh deploy never shows an empty
// Hall of Fame. Real submissions then pile on top as usual.
//
// Run:  node scripts/seed-demo.mjs   (needs DATABASE_URL in the environment)

import { PrismaClient } from '@prisma/client';

const db = new PrismaClient({ log: ['error'] });

const DEMO_SCORES = [
  { initials: 'ZAI', credits: 18750, spins: 52 },
  { initials: 'ACE', credits: 14200, spins: 44 },
  { initials: 'MLS', credits: 9875, spins: 37 },
  { initials: 'KIX', credits: 6400, spins: 29 },
  { initials: 'PIN', credits: 4125, spins: 21 },
  { initials: 'NEO', credits: 2380, spins: 14 },
];

try {
  const count = await db.score.count();
  if (count === 0) {
    for (const data of DEMO_SCORES) {
      await db.score.create({ data });
    }
    console.log(`[seed] inserted ${DEMO_SCORES.length} demo scores into the Hall of Fame`);
  } else {
    console.log(`[seed] leaderboard already has ${count} row(s) — skipping`);
  }
} catch (err) {
  // Non-fatal: the game itself doesn't need the DB; leaderboard just stays empty.
  console.error('[seed] failed (game remains playable):', err?.message ?? err);
} finally {
  await db.$disconnect();
}
