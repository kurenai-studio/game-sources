import { Module } from "@nestjs/common";
import { StarterCampaignSeed } from "./starter-campaign.seed.js";

@Module({ providers: [StarterCampaignSeed] })
export class SeedModule {}
