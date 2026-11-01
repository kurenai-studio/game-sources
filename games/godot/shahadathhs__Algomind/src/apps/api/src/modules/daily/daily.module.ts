import { Module } from "@nestjs/common";
import { AuditModule } from "../audit/audit.module.js";
import { AuthModule } from "../auth/auth.module.js";
import { AdminDailyController } from "./admin-daily.controller.js";
import { DailyController } from "./daily.controller.js";
import { DailyService } from "./daily.service.js";

@Module({
  imports: [AuthModule, AuditModule],
  controllers: [DailyController, AdminDailyController],
  providers: [DailyService],
  exports: [DailyService],
})
export class DailyModule {}
