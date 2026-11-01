import { Module } from "@nestjs/common";
import { AuditModule } from "../audit/audit.module.js";
import { AuthModule } from "../auth/auth.module.js";
import { AdminCampaignController } from "./admin-campaign.controller.js";
import { CampaignService } from "./campaign.service.js";

@Module({
  imports: [AuthModule, AuditModule],
  controllers: [AdminCampaignController],
  providers: [CampaignService],
})
export class CampaignModule {}
