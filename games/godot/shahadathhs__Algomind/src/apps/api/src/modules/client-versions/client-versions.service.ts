import { Injectable } from "@nestjs/common";
import type { ClientVersion } from "../../generated/prisma/client.js";
import { conflict, isUniqueViolation, notFound } from "../../core/http/errors.js";
import { PrismaService } from "../../core/prisma/prisma.service.js";
import type {
  ClientVersionView,
  CreateClientVersion,
  UpdateClientVersion,
} from "./client-versions.schemas.js";

export function toClientVersionView(row: ClientVersion): ClientVersionView {
  return {
    id: row.id,
    version: row.version,
    supportedMechanics: row.supportedMechanics,
    isMinimum: row.isMinimum,
    releasedAt: row.releasedAt.toISOString(),
    createdAt: row.createdAt.toISOString(),
    updatedAt: row.updatedAt.toISOString(),
  };
}

@Injectable()
export class ClientVersionsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(): Promise<{ items: ClientVersionView[] }> {
    const rows = await this.prisma.clientVersion.findMany({ orderBy: { releasedAt: "desc" } });
    return { items: rows.map(toClientVersionView) };
  }

  /** The minimum supported version, or null when none is flagged. */
  minimum(): Promise<ClientVersion | null> {
    return this.prisma.clientVersion.findFirst({ where: { isMinimum: true } });
  }

  all(): Promise<ClientVersion[]> {
    return this.prisma.clientVersion.findMany({ orderBy: { releasedAt: "desc" } });
  }

  async create(input: CreateClientVersion): Promise<ClientVersionView> {
    try {
      const row = await this.prisma.$transaction(async (tx) => {
        if (input.isMinimum) {
          await tx.clientVersion.updateMany({
            where: { isMinimum: true },
            data: { isMinimum: false },
          });
        }
        return tx.clientVersion.create({
          data: {
            version: input.version,
            supportedMechanics: input.supportedMechanics,
            isMinimum: input.isMinimum,
            ...(input.releasedAt ? { releasedAt: new Date(input.releasedAt) } : {}),
          },
        });
      });
      return toClientVersionView(row);
    } catch (error) {
      if (isUniqueViolation(error)) {
        throw conflict("VERSION_EXISTS", `Version ${input.version} is already registered.`);
      }
      throw error;
    }
  }

  async update(id: string, input: UpdateClientVersion): Promise<ClientVersionView> {
    const row = await this.prisma.$transaction(async (tx) => {
      const existing = await tx.clientVersion.findUnique({ where: { id } });
      if (!existing) throw notFound("The client version");
      if (input.isMinimum) {
        await tx.clientVersion.updateMany({
          where: { isMinimum: true, NOT: { id } },
          data: { isMinimum: false },
        });
      }
      return tx.clientVersion.update({
        where: { id },
        data: {
          ...(input.supportedMechanics ? { supportedMechanics: input.supportedMechanics } : {}),
          ...(input.isMinimum ? { isMinimum: true } : {}),
          ...(input.releasedAt ? { releasedAt: new Date(input.releasedAt) } : {}),
        },
      });
    });
    return toClientVersionView(row);
  }
}
