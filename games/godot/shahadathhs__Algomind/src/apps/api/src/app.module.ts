import { Module } from "@nestjs/common";
import { ConfigModule } from "./core/config/config.module.js";
import { PrismaModule } from "./core/prisma/prisma.module.js";
import { AchievementsModule } from "./modules/achievements/achievements.module.js";
import { ContactModule } from "./modules/contact/contact.module.js";
import { AuditModule } from "./modules/audit/audit.module.js";
import { AuthModule } from "./modules/auth/auth.module.js";
import { CampaignModule } from "./modules/campaign/campaign.module.js";
import { CatalogModule } from "./modules/catalog/catalog.module.js";
import { ClientVersionsModule } from "./modules/client-versions/client-versions.module.js";
import { DailyModule } from "./modules/daily/daily.module.js";
import { HealthModule } from "./modules/health/health.module.js";
import { LeaderboardsModule } from "./modules/leaderboards/leaderboards.module.js";
import { LevelsModule } from "./modules/levels/levels.module.js";
import { MeModule } from "./modules/me/me.module.js";
import { PlayersModule } from "./modules/players/players.module.js";
import { PointsModule } from "./modules/points/points.module.js";
import { ProfileModule } from "./modules/profile/profile.module.js";
import { SeedModule } from "./modules/seed/seed.module.js";
import { ShareModule } from "./modules/share/share.module.js";
import { StatsModule } from "./modules/stats/stats.module.js";

@Module({
  imports: [
    ConfigModule,
    PrismaModule,
    HealthModule,
    AuthModule,
    AuditModule,
    ClientVersionsModule,
    LevelsModule,
    CampaignModule,
    CatalogModule,
    MeModule,
    PointsModule,
    ProfileModule,
    LeaderboardsModule,
    DailyModule,
    AchievementsModule,
    ContactModule,
    ShareModule,
    StatsModule,
    PlayersModule,
    SeedModule,
  ],
})
export class AppModule {}
