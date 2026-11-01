import { Injectable, Logger } from "@nestjs/common";
import { AppConfig } from "../../core/config/app-config.js";

const DELAY_MS = 750;
const TIMEOUT_MS = 5000;

/**
 * Tells the web app to refresh its public pages after the campaign changed. Best effort: it never
 * delays or fails the request that caused it, and the web app also refreshes on its own schedule.
 * The call is delayed a moment and merged with others so it lands after the database commit.
 */
@Injectable()
export class WebRevalidator {
  private readonly logger = new Logger(WebRevalidator.name);
  private timer: NodeJS.Timeout | undefined;

  constructor(private readonly config: AppConfig) {}

  notify(): void {
    const { webRevalidateUrl, revalidateSecret } = this.config;
    if (!webRevalidateUrl || !revalidateSecret || this.timer) return;
    this.timer = setTimeout(() => {
      this.timer = undefined;
      void this.send(webRevalidateUrl, revalidateSecret);
    }, DELAY_MS);
    this.timer.unref();
  }

  private async send(url: string, secret: string): Promise<void> {
    try {
      const res = await fetch(url, {
        method: "POST",
        headers: { "x-revalidate-secret": secret },
        signal: AbortSignal.timeout(TIMEOUT_MS),
      });
      if (!res.ok) this.logger.warn(`Web revalidation answered ${res.status}`);
    } catch (error) {
      this.logger.warn(
        `Web revalidation failed: ${error instanceof Error ? error.message : "unknown error"}`,
      );
    }
  }
}
