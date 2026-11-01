-- CreateTable
CREATE TABLE "SiteContact" (
    "id" TEXT NOT NULL DEFAULT 'contact',
    "displayName" TEXT NOT NULL,
    "email" TEXT NOT NULL DEFAULT '',
    "github" TEXT NOT NULL DEFAULT '',
    "website" TEXT NOT NULL DEFAULT '',
    "location" TEXT NOT NULL DEFAULT '',
    "note" TEXT NOT NULL DEFAULT '',
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "updatedBy" TEXT,

    CONSTRAINT "SiteContact_pkey" PRIMARY KEY ("id")
);

