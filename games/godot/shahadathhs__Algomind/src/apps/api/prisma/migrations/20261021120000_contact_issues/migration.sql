-- The contact page lists the issues page where it used to list a location.
ALTER TABLE "SiteContact" RENAME COLUMN "location" TO "issues";
UPDATE "SiteContact" SET "issues" = '';
