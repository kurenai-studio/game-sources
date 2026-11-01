import { Module } from "@nestjs/common";
import { AuthModule } from "../auth/auth.module.js";
import { AuditController } from "./audit.controller.js";
import { AuditService } from "./audit.service.js";
import { WebRevalidator } from "./web-revalidator.js";

@Module({
  imports: [AuthModule],
  controllers: [AuditController],
  providers: [AuditService, WebRevalidator],
  exports: [AuditService],
})
export class AuditModule {}
