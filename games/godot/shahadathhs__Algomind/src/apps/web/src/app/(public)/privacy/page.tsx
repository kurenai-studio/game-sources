import type { Metadata } from "next";
import Link from "next/link";
import { ProsePage } from "@/components/public/prose-page";
import { ProseSection } from "@/components/public/prose-section";
import { pageMetadata } from "@/lib/seo";

const DESCRIPTION =
  "What Algomind does and does not collect: the website sets no cookies and collects nothing, the app keeps progress on your device, and an optional account stores your email, progress, the programs you solved levels with, and, only if you turn it on, a public profile.";

export const metadata: Metadata = pageMetadata({
  title: "Privacy",
  shareTitle: "Algomind privacy",
  description: DESCRIPTION,
  path: "/privacy",
});

export default function PrivacyPage() {
  return (
    <ProsePage
      title="Privacy"
      lead="Algomind collects as little as it can. This page says what is and is not collected."
      wide
    >
      <ProseSection title="This website">
        <p>
          The website collects nothing and sets no cookies. It has no analytics, no tracking, no
          advertising, and loads no third-party scripts, fonts, or images.
        </p>
        <p>
          If you use the light and dark toggle, your choice is saved in your browser on your device.
          It is never sent anywhere.
        </p>
        <p>
          Like any web host, the service that serves this site may keep standard server logs, such
          as your IP address and the page you asked for, under its own policy. The Android build is
          downloaded from GitHub Releases, so GitHub handles that download under its own policy.
        </p>
      </ProseSection>

      <ProseSection title="The app, with no account">
        <p>
          Your progress, settings, and downloaded levels are stored on your device. Playing without
          an account uploads none of it. No account is needed to play.
        </p>
        <p>
          The app asks the Algomind server for published levels so that new levels arrive without an
          app update. That request does not contain your progress.
        </p>
        <p>There are no ads and no purchases in the app.</p>
      </ProseSection>

      <ProseSection title="An optional account" spread>
        <p className="max-w-[680px]">Accounts are optional. An account stores:</p>
        <ul className="grid max-w-[1000px] gap-x-12 gap-y-2 md:grid-cols-2">
          <li>your email address;</li>
          <li>a hash of your password, never the password itself;</li>
          <li>your progress and the settings you sync, so they follow you between devices;</li>
          <li>
            the programs you solved levels with, which the server checks and re-runs to give your
            stars and points, and the points you have earned;
          </li>
          <li>when you last used the app, and a record of your signed-in devices.</li>
        </ul>
        <p className="max-w-[680px]">
          Progress is saved on your device first. It, and the programs of levels you solved, are
          uploaded only while you are signed in. A failed sync never changes what is saved on your
          device. The server never trusts a score from the app: it scores the program itself.
          Nothing is sold or shared for advertising.
        </p>
        <p className="max-w-[680px]">
          The person who runs Algomind can see these records in the dashboard, to help with support
          and to keep the game fair. They can sign you out, reset your server-side progress, suspend
          an account, set or clear a display name, export your data, or delete the account. Each of
          these is written to a log. They can also hide a player from the leaderboards, which is
          written to the log too.
        </p>
      </ProseSection>

      <ProseSection title="Leaderboards, daily challenge, and badges" spread>
        <p className="max-w-[680px]">
          Nothing about you is public until you turn it on. An account alone shows nothing to other
          players. Under your profile in the app you can opt in to the leaderboards, and you can opt
          out again at any time.
        </p>
        <p className="max-w-[680px]">An opted-in profile stores:</p>
        <ul className="grid max-w-[1000px] gap-x-12 gap-y-2 md:grid-cols-2">
          <li>
            a display name, or your choice to be shown as Anonymous, plus a random public id that is
            not your account id;
          </li>
          <li>your verified results and the points they earned;</li>
          <li>your daily challenge results and your daily streak;</li>
          <li>the badges you have earned.</li>
        </ul>
        <p className="max-w-[680px]">
          Other players see only your name (or Anonymous), your rank, and your points or result on a
          level or a day. They never see your email address, your account id, or your programs.
          Players who have not opted in do not appear on the boards at all. Badges and your daily
          streak are for you; the boards show points and results.
        </p>
        <p className="max-w-[680px]">
          Any player can report a name on a board, and the person who runs Algomind can then clear
          the name, take the player off the boards, or dismiss the report. A report stores the
          reason written, the name reported, and the account that reported it, so one player cannot
          report the same name twice. The dashboard shows the reported name and the reason, not who
          reported.
        </p>
      </ProseSection>

      <ProseSection title="Share links">
        <p>
          When you share a result, the server makes a link with a random code. The link shows the
          level, the number of commands and steps, and par. It holds no name, no email, and no
          program, and anyone with the link can open it, so share it only where you want it seen.
          Opening a link does not set cookies or load anything from other sites.
        </p>
      </ProseSection>

      <ProseSection title="Deleting your data">
        <p>
          Without an account, everything is on your device: clear the app&apos;s data or uninstall
          the app and it is gone.
        </p>
        <p>
          With an account, you can delete it from the account screen in the app, which removes your
          email address, your synced progress, your solved programs, your points, your profile and
          name, your daily results, your badges, reports you made or that name you, your share links
          (which stop working), and your sessions. You can also ask for deletion, or for a copy of
          your data, by writing to the address on the <Link href="/contact">contact page</Link>.
        </p>
      </ProseSection>

      <ProseSection title="Changes to this page">
        <p>
          If what Algomind collects changes, this page changes first. Last updated: October 2026,
          when optional leaderboards, the daily challenge, badges, and share links were added.
        </p>
      </ProseSection>
    </ProsePage>
  );
}
