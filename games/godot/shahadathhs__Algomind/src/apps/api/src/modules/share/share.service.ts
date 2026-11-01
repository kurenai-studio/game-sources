import { randomBytes } from "node:crypto";
import { Injectable } from "@nestjs/common";
import { conflict, notFound } from "../../core/http/errors.js";
import { PrismaService } from "../../core/prisma/prisma.service.js";
import { asPar } from "../levels/level-views.js";
import type { ShareBody, ShareView } from "./share.schemas.js";

const ALPHABET = "0123456789abcdefghjkmnpqrstvwxyz";

/** Eight random characters (40 bits): not guessable in practice, and nothing in them identifies anyone. */
export function newCode(): string {
  const bytes = randomBytes(5);
  let value = 0n;
  for (const byte of bytes) value = (value << 8n) | BigInt(byte);
  let code = "";
  for (let i = 0; i < 8; i += 1) {
    code += ALPHABET[Number(value & 31n)];
    value >>= 5n;
  }
  return code;
}

/**
 * Share links: a code that leads to a public page with the player's verified result for a level or
 * a daily challenge. Only a result the server holds can be shared, so a link never shows a claim.
 */
@Injectable()
export class ShareService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, input: ShareBody): Promise<{ code: string; path: string }> {
    const level = await this.prisma.level.findUnique({
      where: { slug: input.levelSlug },
      include: { currentPublishedVersion: true },
    });
    const par = asPar(level?.currentPublishedVersion?.par);
    if (!level || !par) throw notFound("The level");

    const result =
      input.kind === "daily"
        ? await this.prisma.dailyResult.findUnique({
            where: { userId_date: { userId, date: input.date! } },
          })
        : await this.prisma.submission.findFirst({
            where: { userId, levelSlug: input.levelSlug, levelVersion: { state: "PUBLISHED" } },
            orderBy: [{ slots: "asc" }, { steps: "asc" }],
          });
    if (!result || result.levelSlug !== input.levelSlug) {
      throw conflict("NO_RESULT", "There is no solved result to share for that.");
    }

    const date = input.kind === "daily" ? input.date! : null;
    const existing = await this.prisma.shareLink.findFirst({
      where: { userId, kind: input.kind, levelSlug: input.levelSlug, date },
    });
    if (existing) {
      await this.prisma.shareLink.update({
        where: { id: existing.id },
        data: { slots: result.slots, steps: result.steps, par: par.commands },
      });
      return { code: existing.code, path: `/s/${existing.code}` };
    }
    const code = newCode();
    await this.prisma.shareLink.create({
      data: {
        code,
        userId,
        kind: input.kind,
        levelSlug: input.levelSlug,
        date,
        slots: result.slots,
        steps: result.steps,
        par: par.commands,
      },
    });
    return { code, path: `/s/${code}` };
  }

  async get(code: string): Promise<ShareView> {
    const link = await this.prisma.shareLink.findUnique({ where: { code } });
    if (!link) throw notFound("The shared result");
    const level = await this.prisma.level.findUnique({ where: { slug: link.levelSlug } });
    if (!level || level.status !== "PUBLISHED") throw notFound("The shared result");
    return {
      kind: link.kind === "daily" ? "daily" : "level",
      levelSlug: link.levelSlug,
      title: level.title,
      difficulty: level.difficulty,
      date: link.date,
      slots: link.slots,
      steps: link.steps,
      par: link.par,
    };
  }
}
