import { Module } from "@nestjs/common";
import { AuditModule } from "../audit/audit.module.js";
import { AuthModule } from "../auth/auth.module.js";
import { AdminPlayersController } from "./admin-players.controller.js";
import { PlayersActionsService } from "./players-actions.service.js";
import { PlayersReadService } from "./players-read.service.js";

@Module({
  imports: [AuthModule, AuditModule],
  controllers: [AdminPlayersController],
  providers: [PlayersReadService, PlayersActionsService],
})
export class PlayersModule {}
