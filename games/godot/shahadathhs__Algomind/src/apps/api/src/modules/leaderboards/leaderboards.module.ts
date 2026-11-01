import { Module } from "@nestjs/common";
import { AuditModule } from "../audit/audit.module.js";
import { AuthModule } from "../auth/auth.module.js";
import { AdminReportsController } from "./admin-reports.controller.js";
import { LeaderboardsController } from "./leaderboards.controller.js";
import { LeaderboardsService } from "./leaderboards.service.js";
import { ReportsService } from "./reports.service.js";

@Module({
  imports: [AuthModule, AuditModule],
  controllers: [LeaderboardsController, AdminReportsController],
  providers: [LeaderboardsService, ReportsService],
})
export class LeaderboardsModule {}
