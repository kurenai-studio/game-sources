import { Module } from "@nestjs/common";
import { AuditModule } from "../audit/audit.module.js";
import { AuthModule } from "../auth/auth.module.js";
import { DailyModule } from "../daily/daily.module.js";
import {
  AdminAchievementsController,
  MyAchievementsController,
} from "./achievements.controller.js";
import { AchievementsService } from "./achievements.service.js";

@Module({
  imports: [AuthModule, AuditModule, DailyModule],
  controllers: [MyAchievementsController, AdminAchievementsController],
  providers: [AchievementsService],
  exports: [AchievementsService],
})
export class AchievementsModule {}
