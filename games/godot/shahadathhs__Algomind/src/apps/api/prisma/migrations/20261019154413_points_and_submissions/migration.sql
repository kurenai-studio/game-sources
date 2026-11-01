-- CreateTable
CREATE TABLE "PointsRuleSet" (
    "id" TEXT NOT NULL,
    "version" INTEGER NOT NULL,
    "rules" JSONB NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT false,
    "createdBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PointsRuleSet_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Submission" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "levelVersionId" TEXT NOT NULL,
    "levelSlug" TEXT NOT NULL,
    "programHash" TEXT NOT NULL,
    "program" JSONB NOT NULL,
    "slots" INTEGER NOT NULL,
    "steps" INTEGER NOT NULL,
    "stars" INTEGER NOT NULL,
    "points" INTEGER NOT NULL,
    "ruleVersion" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Submission_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PointsLedger" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "reason" TEXT NOT NULL,
    "delta" INTEGER NOT NULL,
    "levelSlug" TEXT,
    "levelVersion" INTEGER,
    "ruleVersion" INTEGER NOT NULL,
    "submissionId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PointsLedger_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "PointsRuleSet_version_key" ON "PointsRuleSet"("version");

-- CreateIndex
CREATE INDEX "Submission_userId_levelSlug_idx" ON "Submission"("userId", "levelSlug");

-- CreateIndex
CREATE UNIQUE INDEX "Submission_userId_levelVersionId_programHash_key" ON "Submission"("userId", "levelVersionId", "programHash");

-- CreateIndex
CREATE INDEX "PointsLedger_userId_idx" ON "PointsLedger"("userId");

-- CreateIndex
CREATE INDEX "PointsLedger_userId_levelSlug_idx" ON "PointsLedger"("userId", "levelSlug");

-- AddForeignKey
ALTER TABLE "Submission" ADD CONSTRAINT "Submission_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Submission" ADD CONSTRAINT "Submission_levelVersionId_fkey" FOREIGN KEY ("levelVersionId") REFERENCES "LevelVersion"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PointsLedger" ADD CONSTRAINT "PointsLedger_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
