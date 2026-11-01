import { Injectable, Logger, type OnApplicationBootstrap } from "@nestjs/common";
import { AppConfig } from "../../core/config/app-config.js";
import { PrismaService } from "../../core/prisma/prisma.service.js";
import { normalizeEmail } from "./auth.service.js";
import { passwordProblem } from "./password-policy.js";
import { PasswordService } from "./password.service.js";

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/**
 * Creates the first admin from SUPER_ADMIN_EMAIL and SUPER_ADMIN_PASS when no admin exists.
 * Idempotent, and the password is never logged. The account must change its password on first
 * sign-in. Production refuses to start without a valid seed; development only warns.
 */
@Injectable()
export class AdminSeedService implements OnApplicationBootstrap {
  private readonly logger = new Logger(AdminSeedService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly passwords: PasswordService,
    private readonly config: AppConfig,
  ) {}

  async onApplicationBootstrap(): Promise<void> {
    const production = this.config.nodeEnv === "production";
    try {
      await this.seed(production);
    } catch (error) {
      if (production) throw error;
      this.logger.warn(`Admin seed skipped: ${error instanceof Error ? error.message : "failed"}`);
    }
  }

  private async seed(production: boolean): Promise<void> {
    if (await this.prisma.user.findFirst({ where: { role: "ADMIN" }, select: { id: true } }))
      return;

    const rawEmail = this.config.superAdminEmail;
    const password = this.config.superAdminPass;
    const email = rawEmail ? normalizeEmail(rawEmail) : undefined;
    const problem = !email
      ? "SUPER_ADMIN_EMAIL is not set"
      : !EMAIL_PATTERN.test(email)
        ? "SUPER_ADMIN_EMAIL is not a valid email address"
        : !password
          ? "SUPER_ADMIN_PASS is not set"
          : passwordProblem(password)
            ? `SUPER_ADMIN_PASS ${passwordProblem(password)}`
            : undefined;
    if (problem || !email || !password) {
      const message = `No admin exists and one cannot be created: ${problem}.`;
      if (production) throw new Error(message);
      this.logger.warn(`${message} Set both in .env (run \`make env\`) to create the first admin.`);
      return;
    }

    try {
      await this.prisma.user.create({
        data: {
          email,
          passwordHash: await this.passwords.hash(password),
          role: "ADMIN",
          mustChangePassword: true,
        },
      });
    } catch (error) {
      // Another instance may have created it between the check and the insert.
      if (await this.prisma.user.findFirst({ where: { role: "ADMIN" }, select: { id: true } }))
        return;
      throw error;
    }
    this.logger.log(
      `Created the first admin ${email}; it must change its password on first sign-in.`,
    );
  }
}
