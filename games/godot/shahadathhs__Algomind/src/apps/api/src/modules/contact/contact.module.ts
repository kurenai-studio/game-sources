import { Module } from "@nestjs/common";
import { AuditModule } from "../audit/audit.module.js";
import { AuthModule } from "../auth/auth.module.js";
import { AdminContactController, ContactController } from "./contact.controller.js";
import { ContactService } from "./contact.service.js";

@Module({
  imports: [AuthModule, AuditModule],
  controllers: [ContactController, AdminContactController],
  providers: [ContactService],
})
export class ContactModule {}
