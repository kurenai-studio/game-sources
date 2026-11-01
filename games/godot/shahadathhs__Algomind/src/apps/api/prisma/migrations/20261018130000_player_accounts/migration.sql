-- CreateTable
CREATE TABLE "LevelProgress" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "levelSlug" TEXT NOT NULL,
    "levelVersion" INTEGER NOT NULL,
    "bestCommands" INTEGER NOT NULL,
    "completedAt" TIMESTAMP(3) NOT NULL,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "LevelProgress_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PlayerSettings" (
    "userId" TEXT NOT NULL,
    "settings" JSONB NOT NULL,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PlayerSettings_pkey" PRIMARY KEY ("userId")
);

-- CreateIndex
CREATE UNIQUE INDEX "LevelProgress_userId_levelSlug_key" ON "LevelProgress"("userId", "levelSlug");

-- AddForeignKey
ALTER TABLE "LevelProgress" ADD CONSTRAINT "LevelProgress_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlayerSettings" ADD CONSTRAINT "PlayerSettings_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
