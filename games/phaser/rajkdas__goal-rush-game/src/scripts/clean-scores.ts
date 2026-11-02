/** QA helper: wipe leaderboard test rows (run: bun scripts/clean-scores.ts). */
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main(): Promise<void> {
  const del = await prisma.score.deleteMany({});
  console.log('deleted rows:', del.count);
}

main()
  .catch((e) => {
    console.error(e);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
