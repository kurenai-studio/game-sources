import { Module } from "@nestjs/common";
import { AuthModule } from "../auth/auth.module.js";
import { ShareController } from "./share.controller.js";
import { ShareService } from "./share.service.js";

@Module({
  imports: [AuthModule],
  controllers: [ShareController],
  providers: [ShareService],
})
export class ShareModule {}
