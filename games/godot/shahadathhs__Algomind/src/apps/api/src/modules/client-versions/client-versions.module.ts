import { Module } from "@nestjs/common";
import { AuthModule } from "../auth/auth.module.js";
import { ClientVersionsController } from "./client-versions.controller.js";
import { ClientVersionsService } from "./client-versions.service.js";

@Module({
  imports: [AuthModule],
  controllers: [ClientVersionsController],
  providers: [ClientVersionsService],
  exports: [ClientVersionsService],
})
export class ClientVersionsModule {}
