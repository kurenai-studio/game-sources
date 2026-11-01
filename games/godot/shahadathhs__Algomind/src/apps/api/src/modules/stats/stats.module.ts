import { Module } from "@nestjs/common";
import { AuthModule } from "../auth/auth.module.js";
import { AdminStatsController } from "./admin-stats.controller.js";
import { LevelStatsService } from "./level-stats.service.js";

@Module({
  imports: [AuthModule],
  controllers: [AdminStatsController],
  providers: [LevelStatsService],
})
export class StatsModule {}
