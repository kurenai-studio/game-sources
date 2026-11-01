import type { Metadata } from "next";
import { Suspense } from "react";
import { connection } from "next/server";
import { JsonLd } from "@/components/public/json-ld";
import { DownloadBand } from "@/components/public/download-band";
import { Hero } from "@/components/public/hero";
import { LoadingBlock } from "@/components/public/loading-block";
import { HowItWorks } from "@/components/public/how-it-works";
import { LevelsStrip } from "@/components/public/levels-strip";
import { ScreensSection } from "@/components/public/screens-section";
import { ShortList } from "@/components/public/short-list";
import { WorldsSection } from "@/components/public/worlds-section";
import { getLatestRelease } from "@/lib/releases";
import { mobileApplicationJsonLd, pageMetadata, websiteJsonLd } from "@/lib/seo";

// Rendered per request (see LandingPage): the levels strip reads the live campaign, and a build made
// while the API is down or asleep must not bake in its fallback. The fetches inside still cache.

export const metadata: Metadata = pageMetadata({
  title: "Algomind: a programming puzzle for Android",
  absoluteTitle: true,
  shareTitle: "Algomind",
  description:
    "Build a program from instruction tiles, run it, and guide the automaton to the target. Free for Android. Offline first. No ads. No purchases.",
  path: "/",
});

/** The hero with the latest release (a call to GitHub), streamed in after the rest of the page. */
async function HeroWithRelease() {
  const release = await getLatestRelease();
  return (
    <>
      <JsonLd
        data={mobileApplicationJsonLd(release.status === "available" ? release.release : undefined)}
      />
      <Hero release={release} />
    </>
  );
}

export default async function LandingPage() {
  await connection();
  return (
    <>
      <JsonLd data={websiteJsonLd()} />
      <Suspense fallback={<Hero release={null} />}>
        <HeroWithRelease />
      </Suspense>
      <HowItWorks />
      <ScreensSection />
      <Suspense fallback={<LoadingBlock label="levels" tall />}>
        <LevelsStrip />
      </Suspense>
      <Suspense fallback={<LoadingBlock label="worlds" tiles={6} />}>
        <WorldsSection />
      </Suspense>
      <ShortList />
      <DownloadBand />
    </>
  );
}
