import { Injectable, Logger, type OnApplicationBootstrap } from "@nestjs/common";
import { PrismaService } from "../../core/prisma/prisma.service.js";
import { AuditService } from "../audit/audit.service.js";
import { AppConfig } from "../../core/config/app-config.js";
import { contactSeed } from "./contact.defaults.js";
import type { AdminContactView, ContactInput, ContactView } from "./contact.schemas.js";

const ID = "contact";

@Injectable()
export class ContactService implements OnApplicationBootstrap {
  private readonly logger = new Logger(ContactService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly config: AppConfig,
  ) {}

  /** Creates the row from the CONTACT_* settings when there is none. Never replaces what an admin saved. */
  async onApplicationBootstrap(): Promise<void> {
    try {
      const created = await this.prisma.siteContact.createMany({
        data: [{ id: ID, ...contactSeed(this.config) }],
        skipDuplicates: true,
      });
      if (created.count > 0)
        this.logger.log("Seeded the contact details from the CONTACT_* settings.");
    } catch (error) {
      this.logger.warn(
        `Contact seed skipped: ${error instanceof Error ? error.message : "failed"}`,
      );
    }
  }

  private async row() {
    return (
      (await this.prisma.siteContact.findUnique({ where: { id: ID } })) ??
      (await this.prisma.siteContact.create({ data: { id: ID, ...contactSeed(this.config) } }))
    );
  }

  async get(): Promise<ContactView> {
    const row = await this.row();
    return {
      displayName: row.displayName,
      email: row.email,
      github: row.github,
      website: row.website,
      issues: row.issues,
      note: row.note,
    };
  }

  async getAdmin(): Promise<AdminContactView> {
    const row = await this.row();
    const editor = row.updatedBy
      ? await this.prisma.user.findUnique({
          where: { id: row.updatedBy },
          select: { email: true },
        })
      : null;
    return {
      ...(await this.get()),
      updatedAt: row.updatedAt.toISOString(),
      updatedByEmail: editor?.email ?? null,
    };
  }

  async update(input: ContactInput, adminId: string): Promise<AdminContactView> {
    await this.row();
    await this.prisma.$transaction(async (tx) => {
      await tx.siteContact.update({ where: { id: ID }, data: { ...input, updatedBy: adminId } });
      await this.audit.record(tx, {
        userId: adminId,
        action: "CONTACT_UPDATED",
        entityType: "contact",
        entityId: ID,
        detail: { fields: Object.keys(input) },
      });
    });
    return this.getAdmin();
  }
}
