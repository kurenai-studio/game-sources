import { Module } from "@nestjs/common";
import { AuditModule } from "../audit/audit.module.js";
import { AchievementsModule } from "../achievements/achievements.module.js";
import { AuthModule } from "../auth/auth.module.js";
import { DailyModule } from "../daily/daily.module.js";
import { AdminPointsController } from "./admin-points.controller.js";
import { PointsMeController } from "./points-me.controller.js";
import { PointsRulesService } from "./points-rules.service.js";
import { SubmissionsService } from "./submissions.service.js";

@Module({
  imports: [AuthModule, AuditModule, DailyModule, AchievementsModule],
  controllers: [PointsMeController, AdminPointsController],
  providers: [PointsRulesService, SubmissionsService],
})
export class PointsModule {}
