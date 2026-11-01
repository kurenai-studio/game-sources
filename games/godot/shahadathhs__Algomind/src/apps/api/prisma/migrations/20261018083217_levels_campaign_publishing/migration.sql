-- CreateEnum
CREATE TYPE "LevelStatus" AS ENUM ('DRAFT', 'PUBLISHED', 'ARCHIVED');

-- CreateEnum
CREATE TYPE "VersionState" AS ENUM ('DRAFT', 'PUBLISHED', 'SUPERSEDED');

-- CreateTable
CREATE TABLE "World" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL DEFAULT '',
    "order" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "World_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Chapter" (
    "id" TEXT NOT NULL,
    "worldId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "order" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Chapter_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Level" (
    "id" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "difficulty" TEXT NOT NULL,
    "status" "LevelStatus" NOT NULL DEFAULT 'DRAFT',
    "chapterId" TEXT,
    "orderInChapter" INTEGER NOT NULL DEFAULT 0,
    "currentPublishedVersionId" TEXT,
    "createdBy" TEXT,
    "updatedBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Level_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "LevelVersion" (
    "id" TEXT NOT NULL,
    "levelId" TEXT NOT NULL,
    "versionNumber" INTEGER NOT NULL,
    "schemaVersion" INTEGER NOT NULL DEFAULT 1,
    "state" "VersionState" NOT NULL DEFAULT 'DRAFT',
    "content" JSONB NOT NULL,
    "referenceSolution" JSONB NOT NULL,
    "par" JSONB,
    "contentHash" TEXT NOT NULL,
    "validationSummary" JSONB,
    "createdBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "publishedAt" TIMESTAMP(3),

    CONSTRAINT "LevelVersion_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PlaytestRecord" (
    "id" TEXT NOT NULL,
    "levelVersionId" TEXT NOT NULL,
    "contentHash" TEXT NOT NULL,
    "testerName" TEXT NOT NULL,
    "solved" BOOLEAN NOT NULL,
    "commandsUsed" INTEGER,
    "perceivedDifficulty" TEXT,
    "notes" TEXT NOT NULL DEFAULT '',
    "createdBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PlaytestRecord_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ClientVersion" (
    "id" TEXT NOT NULL,
    "version" TEXT NOT NULL,
    "supportedMechanics" TEXT[],
    "isMinimum" BOOLEAN NOT NULL DEFAULT false,
    "releasedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ClientVersion_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AuditEvent" (
    "id" TEXT NOT NULL,
    "userId" TEXT,
    "action" TEXT NOT NULL,
    "entityType" TEXT NOT NULL,
    "entityId" TEXT NOT NULL,
    "detail" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AuditEvent_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "World_order_idx" ON "World"("order");

-- CreateIndex
CREATE INDEX "Chapter_worldId_order_idx" ON "Chapter"("worldId", "order");

-- CreateIndex
CREATE UNIQUE INDEX "Level_slug_key" ON "Level"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "Level_currentPublishedVersionId_key" ON "Level"("currentPublishedVersionId");

-- CreateIndex
CREATE INDEX "Level_chapterId_orderInChapter_idx" ON "Level"("chapterId", "orderInChapter");

-- CreateIndex
CREATE INDEX "Level_status_idx" ON "Level"("status");

-- CreateIndex
CREATE INDEX "LevelVersion_levelId_state_idx" ON "LevelVersion"("levelId", "state");

-- CreateIndex
CREATE UNIQUE INDEX "LevelVersion_levelId_versionNumber_key" ON "LevelVersion"("levelId", "versionNumber");

-- CreateIndex
CREATE INDEX "PlaytestRecord_levelVersionId_idx" ON "PlaytestRecord"("levelVersionId");

-- CreateIndex
CREATE INDEX "PlaytestRecord_contentHash_idx" ON "PlaytestRecord"("contentHash");

-- CreateIndex
CREATE UNIQUE INDEX "ClientVersion_version_key" ON "ClientVersion"("version");

-- CreateIndex
CREATE INDEX "AuditEvent_action_createdAt_idx" ON "AuditEvent"("action", "createdAt");

-- CreateIndex
CREATE INDEX "AuditEvent_createdAt_idx" ON "AuditEvent"("createdAt");

-- AddForeignKey
ALTER TABLE "Chapter" ADD CONSTRAINT "Chapter_worldId_fkey" FOREIGN KEY ("worldId") REFERENCES "World"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Level" ADD CONSTRAINT "Level_chapterId_fkey" FOREIGN KEY ("chapterId") REFERENCES "Chapter"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Level" ADD CONSTRAINT "Level_currentPublishedVersionId_fkey" FOREIGN KEY ("currentPublishedVersionId") REFERENCES "LevelVersion"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LevelVersion" ADD CONSTRAINT "LevelVersion_levelId_fkey" FOREIGN KEY ("levelId") REFERENCES "Level"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlaytestRecord" ADD CONSTRAINT "PlaytestRecord_levelVersionId_fkey" FOREIGN KEY ("levelVersionId") REFERENCES "LevelVersion"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- A level has at most one working draft, at most one published version, and the registry has at
-- most one minimum supported client version. Prisma cannot declare partial indexes.
CREATE UNIQUE INDEX "LevelVersion_one_draft_per_level" ON "LevelVersion"("levelId") WHERE "state" = 'DRAFT';
CREATE UNIQUE INDEX "LevelVersion_one_published_per_level" ON "LevelVersion"("levelId") WHERE "state" = 'PUBLISHED';
CREATE UNIQUE INDEX "ClientVersion_one_minimum" ON "ClientVersion"("isMinimum") WHERE "isMinimum";

-- Published versions are immutable. A DRAFT row can change freely (including becoming PUBLISHED);
-- a PUBLISHED row can only become SUPERSEDED with every content column untouched; a SUPERSEDED row
-- never changes; only a DRAFT row can be deleted.
CREATE FUNCTION "LevelVersion_guard_immutable"() RETURNS trigger AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF OLD."state" <> 'DRAFT' THEN
      RAISE EXCEPTION 'LevelVersion % is % and cannot be deleted', OLD."id", OLD."state"
        USING ERRCODE = 'restrict_violation';
    END IF;
    RETURN OLD;
  END IF;

  IF OLD."state" = 'DRAFT' THEN
    RETURN NEW;
  END IF;

  IF OLD."state" = 'PUBLISHED' AND NEW."state" = 'SUPERSEDED'
     AND NEW."id" = OLD."id"
     AND NEW."levelId" = OLD."levelId"
     AND NEW."versionNumber" = OLD."versionNumber"
     AND NEW."schemaVersion" = OLD."schemaVersion"
     AND NEW."content" = OLD."content"
     AND NEW."referenceSolution" = OLD."referenceSolution"
     AND NEW."par" IS NOT DISTINCT FROM OLD."par"
     AND NEW."contentHash" = OLD."contentHash"
     AND NEW."validationSummary" IS NOT DISTINCT FROM OLD."validationSummary"
     AND NEW."publishedAt" IS NOT DISTINCT FROM OLD."publishedAt"
     AND NEW."createdAt" = OLD."createdAt" THEN
    RETURN NEW;
  END IF;

  RAISE EXCEPTION 'LevelVersion % is % and is immutable', OLD."id", OLD."state"
    USING ERRCODE = 'restrict_violation';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "LevelVersion_immutable"
  BEFORE UPDATE OR DELETE ON "LevelVersion"
  FOR EACH ROW EXECUTE FUNCTION "LevelVersion_guard_immutable"();
