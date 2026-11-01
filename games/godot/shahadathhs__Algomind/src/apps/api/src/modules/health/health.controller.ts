import { Controller, Get, ServiceUnavailableException } from "@nestjs/common";
import { ApiOkResponse, ApiTags } from "@nestjs/swagger";
import { PrismaService } from "../../core/prisma/prisma.service.js";

@ApiTags("health")
@Controller("health")
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}

  /** Liveness: the process is up. Never touches the database. */
  @Get()
  @ApiOkResponse({ description: "The API process is running." })
  live(): { status: "ok" } {
    return { status: "ok" };
  }

  /** Readiness: the database answers. */
  @Get("ready")
  @ApiOkResponse({ description: "The API and its database are ready." })
  async ready(): Promise<{ status: "ok"; database: "up" }> {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
    } catch {
      throw new ServiceUnavailableException({
        code: "DATABASE_UNAVAILABLE",
        message: "The database is not reachable.",
      });
    }
    return { status: "ok", database: "up" };
  }
}
