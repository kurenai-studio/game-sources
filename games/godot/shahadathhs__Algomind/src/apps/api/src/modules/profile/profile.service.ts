import { Injectable } from "@nestjs/common";
import { conflict, isUniqueViolation, notFound, unprocessable } from "../../core/http/errors.js";
import { PrismaService } from "../../core/prisma/prisma.service.js";
import { checkDisplayName, nameKey } from "./name-rules.js";
import type { ProfileBody, ProfileView } from "./profile.schemas.js";
import { rankFor } from "./ranks.js";

/** How the player appears to others: a display name and the choice to be on the leaderboards. */
@Injectable()
export class ProfileService {
  constructor(private readonly prisma: PrismaService) {}

  async get(userId: string): Promise<ProfileView> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw notFound("The account");
    const sum = await this.prisma.pointsLedger.aggregate({
      where: { userId },
      _sum: { delta: true },
    });
    const total = sum._sum.delta ?? 0;
    return {
      displayName: user.displayName,
      leaderboardOptIn: user.leaderboardOptIn,
      hideName: user.hideName,
      publicId: user.publicId,
      total,
      rank: rankFor(total),
    };
  }

  async update(userId: string, input: ProfileBody): Promise<ProfileView> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw notFound("The account");

    let displayName = user.displayName;
    if (input.displayName !== undefined) {
      if (input.displayName === null) {
        displayName = null;
      } else {
        const checked = checkDisplayName(input.displayName);
        if (!checked.ok) throw unprocessable(checked.code, checked.message);
        displayName = checked.name;
      }
    }
    const hideName = input.hideName ?? user.hideName;
    let optIn = input.leaderboardOptIn ?? user.leaderboardOptIn;
    // Appearing under a name needs a name; appearing as "Anonymous" does not.
    if (optIn && !displayName && !hideName) {
      throw unprocessable(
        "NAME_REQUIRED",
        "Choose a display name, or hide your name, before you appear on the leaderboards.",
      );
    }
    // A cleared name with the name shown would leave nothing to show.
    if (displayName === null && !hideName) optIn = false;

    try {
      await this.prisma.user.update({
        where: { id: userId },
        data: {
          displayName,
          displayNameKey: displayName ? nameKey(displayName) : null,
          hideName,
          leaderboardOptIn: optIn,
        },
      });
    } catch (error) {
      if (isUniqueViolation(error)) throw conflict("NAME_TAKEN", "That name is already taken.");
      throw error;
    }
    return this.get(userId);
  }
}
