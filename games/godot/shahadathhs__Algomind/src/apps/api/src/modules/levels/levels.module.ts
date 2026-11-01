import { Module } from "@nestjs/common";
import { AuditModule } from "../audit/audit.module.js";
import { AuthModule } from "../auth/auth.module.js";
import { ClientVersionsModule } from "../client-versions/client-versions.module.js";
import { AdminLevelsController } from "./admin-levels.controller.js";
import { LevelsPlaytestService } from "./levels-playtest.service.js";
import { LevelsPublishService } from "./levels-publish.service.js";
import { LevelsReadService } from "./levels-read.service.js";
import { LevelsTransferService } from "./levels-transfer.service.js";
import { LevelsService } from "./levels.service.js";

@Module({
  imports: [AuthModule, AuditModule, ClientVersionsModule],
  controllers: [AdminLevelsController],
  providers: [
    LevelsReadService,
    LevelsService,
    LevelsPublishService,
    LevelsPlaytestService,
    LevelsTransferService,
  ],
  exports: [LevelsReadService, LevelsService],
})
export class LevelsModule {}
