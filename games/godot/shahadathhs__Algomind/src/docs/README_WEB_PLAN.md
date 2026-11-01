# Algomind — Public Website Plan

> **Purpose:** Plan the public, user-facing part of `apps/web` (the `(public)` route group). The admin dashboard is covered in the architecture and visual-design docs.  
> **Reference renders:** [design/web/](design/web/) holds the landing and download pages in light and dark, at desktop and mobile widths. Values in them (version, size, hash, release notes, QR) are placeholders.  
> **Status:** The launch pages are built (landing, download, how to play, privacy, contact) and live at https://playalgomind.vercel.app. The level catalog and browser play (`/play`) are built; level pages and the account page are not. Deviations from this plan are noted where they apply.

## 1. Goal

**Get people to install the Android app.** Every page and every decision serves that. The site is not a second product. Browser play is a later, clearly secondary extra.

- **Distribution is APK only** (no Google Play). The APK is hosted on GitHub Releases, so site traffic costs no hosting bandwidth.
- Visitors are mostly on a phone (a link shared to them) or on a desktop (who need to get the link to a phone). Both must be served.
- The site must feel like the same product as the game: same tokens, shapes, and rules ([README_VISUAL_DESIGN.md](README_VISUAL_DESIGN.md)).

## 2. Sitemap and scope

**Launch (built once the first APK exists):**

| Route                      | Purpose                                                            | Rendering                                     |
| -------------------------- | ------------------------------------------------------------------ | --------------------------------------------- |
| `/`                        | Landing: explain the game and drive the download                   | Per request; fetches cached (see below)       |
| `/download`                | Install page: the APK, install steps, QR code for desktop visitors | Static shell, release data revalidated hourly |
| `/how-to-play`             | The commands, loops, the tape, what failure messages mean          | Static                                        |
| `/privacy`                 | What is and is not collected; account deletion instructions        | Static; wide layout                           |
| `/contact`                 | How to reach the developer; details read from `GET /v1/contact`    | Server-rendered, revalidated every 60 s; wide |
| `/robots`, `/sitemap`, 404 | `/admin` excluded from both                                        | n/a                                           |

**After launch (not blockers):**

| Route            | Purpose                                                                                                                                                                                                                                                                                                                                                                |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/levels`        | **Built.** The catalog organised by world and chapter, with a board thumbnail, difficulty, and command limit for each level. It reads the published campaign from the API (`GET /v1/campaign`, then each level's board from `GET /v1/levels/:slug`, revalidated every minute) and says the levels could not be loaded when the API is unreachable; nothing is bundled. |
| `/levels/[slug]` | Not built: spoiler-free level pages, with a generated share image per level                                                                                                                                                                                                                                                                                            |
| `/s/[code]`      | **Built.** A shared result: the level's board, the numbers (commands, par, steps) and a Play link. Noindex, not in the sitemap. See section 7a                                                                                                                                                                                                                         |
| `/play`          | **Built.** Browser play through the game's web export, as a "Play" link in the header and mobile menu. See section 7                                                                                                                                                                                                                                                   |
| `/account`       | Sign in, sync status, delete account, only when sync ships                                                                                                                                                                                                                                                                                                             |

## 3. Landing page

One primary action on the whole page: the yellow **Download for Android** button. Everything else is text or a rendered screen.

1. **Header:** the tile wordmark; links Levels, How to play, Download; a light/dark toggle. On narrow screens only the wordmark and toggle show.
2. **Hero:** a factual headline ("A programming puzzle for Android."), one sentence of detail, the primary button, a meta line (version, size, minimum Android), and a quiet "How to play" link. Beside it, the real game screen (running state, tape under the read-head) as a flat chamfered frame, no device bezel.
3. **How it works:** three steps, Build, Run, Debug, each drawn with the real tape renderings and one sentence.
4. **The screens:** four screens in sequence (levels, building, failed, solved).
5. **Levels:** a strip of level boards and the statement that new levels arrive without an app update. The boards come from published levels (fetched and revalidated, with a static fallback so the page never depends on the API being up).
6. **The short list:** offline first, no ads, no purchases, no account needed, sync if you want, light and dark.
7. **Closing download band:** "Free for Android." with the primary button repeated.
8. **Footer:** Privacy, Contact, copyright.

**As built:** the header's "Levels" link now points at `/levels`; on phones the nav links live in a side drawer (a `<details>` element, so it opens, closes, and navigates with no JavaScript; a small client component only closes it after navigation and on Escape, and the menu button turns into a close button while it is open). Interactive controls show a pointer cursor. The small "ANDROID" eyebrow label above the hero headline was dropped (the visual rules forbid eyebrow text, and the headline already says Android); the minimum Android version is left out of the meta line because none is defined yet (see open items). The landing page's download buttons always link to the internal `/download` page.

Not on the page: taglines, testimonials, stock imagery, store badges for stores we are not on, fake review counts, a newsletter, or a cookie banner.

## 4. Download page

The page must make sideloading feel safe and easy.

- **Primary button:** Download APK, linking to the latest GitHub Release asset. A meta line shows version, file size, and minimum Android version, all read from the release.
- **Verify:** show a shortened SHA-256 and link to the release page for the full hash.
- **QR code** (desktop widths only): encodes the `/download` page URL (not the direct APK link, so it never goes stale), generated at build time as inline SVG. Hidden on narrow screens, where it is useless.
- **Install steps** as numbered tiles: download, open the file, allow install of unknown apps (one-time), open the app.
- **What is new:** release notes for the latest version.
- **Other builds:** latest development build and all releases, as text links.
- **Good to know:** every build is signed with the same key so updates install over older versions; not available for iPhone; the app is not on Google Play.
- **Data source:** the GitHub Releases API (`GITHUB_REPOSITORY`, default `shahadathhs/Algomind`), revalidated hourly, with strict parsing of the response and of the `.sha256` checksum file. The optional server-side `GITHUB_TOKEN` is used only for the API calls, never for asset URLs.
- **APK info (when a release is available):** an "About this APK" section with the file name, version, release date, size, the architecture it runs on (64-bit ARM, `arm64-v8a`, kept in step with the Android export preset), the build type (a debug build signed with one fixed key), the full SHA-256, commands to check the file (macOS or Linux and Windows PowerShell), and direct links to the APK and the release page. The hero shows the direct **Download APK** button, version, and size.
- **Testing:** `GITHUB_API_URL` (default `https://api.github.com`) points the page at another GitHub API, such as a local stand-in; the available state was checked this way. Leave it unset in production.
- **Fallback:** if there is no release, the repository is private, or GitHub is down or answers unexpectedly, the page shows "No release available yet" with a plain link to the releases page and **no download button**, so a button never points at an unverified URL. **A private repository's release assets cannot be downloaded by anonymous visitors**, so until the repository (or its releases) is public, this fallback is what visitors see. No client JavaScript is needed to download.
- **Device detection:** none. Show everything; the layout, not user-agent sniffing, decides what matters.

## 5. Trust and safety

- Be explicit that this is a direct install and why (no store).
- Always sign with the same key; publish the SHA-256 on every release.
- Link to the source repository only if it is public (decision pending).
- No tracking, no third-party scripts, no third-party fonts at runtime, no cookies.
- The privacy page states in plain terms what the app stores on the device, what an optional account stores, and how to delete it.

## 6. Technical decisions

- **Same Next.js app** as the dashboard, in the `(public)` route group, with its own components (`components/public`) sharing `components/ui` and the generated design tokens.
- **Static first:** the legal and help pages are pre-rendered; the download page revalidates hourly. The landing page and `/levels` read the live campaign, so they render per request (`connection()`) while their fetches cache for a minute; a build made while the API is down or asleep therefore never bakes in a fallback or an error.
- **The landing drawings** are computed from one real level and one real world (`lib/landing-level.ts`, a copy of the seed) with the contract's solver and simulator, and `apps/api/test/landing-sync.test.ts` fails when the seed and the copy disagree. The levels strip shows real published boards spread over the campaign, falling back to static samples only when the API cannot be reached.
- **No JavaScript required** for any content or for downloading. The theme follows `prefers-color-scheme`; the toggle is a progressive enhancement (it appears only after hydration, and an explicit choice is kept in `localStorage` on the device only, never sent anywhere).
- **Responsive by container:** the landing and download pages collapse to one column on narrow screens; nothing is clipped horizontally.
- **Boards and tape are rendered from real data** by the shared tile renderer (also used by the dashboard preview), as inline SVG, never as screenshots.
- **SEO:** one title and description per page, a generated Open Graph image (the tile wordmark and a board), sitemap and robots; admin routes are `noindex`.
- **Performance:** no heavy images; fonts bundled and self-hosted; the landing page is mostly HTML and SVG.
- **Accessibility:** both themes pass contrast; every control is keyboard reachable with visible focus; headings are real headings; reduced-motion is respected; nothing loops.
- **Analytics:** none at launch.

## 7. Browser play

**Built** as `/play`. It uses the **same Godot project exported to the web**, never a separate web implementation (that would duplicate the simulator, editor, themes, and sync).

- **Measured on a comparable project:** the engine `.wasm` is about 39 MB raw and about 9.5 MB over the wire compressed; the game data about 0.5 MB. First visit is about 10 MB, then cached.
- **Hosting:** keep the export out of git. CI attaches it to a GitHub release; the site fetches it at build time into a gitignored folder; a Vercel deploy hook rebuilds the site after a new export.
- **How it is wired:** the game has a `Web` export preset (single-threaded, no extensions). `make game-web` exports it with the Godot container into `apps/web/public/play-build/`. CI exports it in the `apk` job (same version) and attaches `algomind-web-<version>.tar.gz` to the rolling `latest` release and to versioned releases. `pnpm --filter @algomind/web build` runs `scripts/fetch-play-build.mjs` first, which downloads that asset from the release tagged `PLAY_BUILD_TAG` (default `latest`) unless an export is already in `public/play-build`; a failed fetch never fails the build. A site built without an export shows "The browser version is not available right now."
- **The page:** a server component checks for the export at build time. The client island (`play-frame.tsx`) loads nothing until Play is pressed, shows a percentage while loading, and has failure states (no WebAssembly, no WebGL 2, download error) with a retry. Without JavaScript the page says it needs it. The browser build is always offline-only (`ApiClient.base_url()` returns "" on the `web` feature) and leaves out what only makes sense in the app: the Account link, the Vibration setting, the Privacy link (the site has one), and quitting on Back: it uses the bundled levels, keeps progress in the browser, and never calls the API, so it needs no CORS entry.
- **Free plan:** Vercel's free (Hobby) tier has bandwidth and use limits that must be checked against current terms before launch. A traffic spike is the risk.
- **Web-build guards:** single-threaded export (no cross-origin isolation headers needed), non-fatal storage failures, audio unlocked by the Play gesture, keyboard controls, and real loading and failure states.
- **Presentation:** a secondary "Try in your browser" link only. The download stays primary.
- **Cost:** a CI job, hosting, and extra QA. This is why it is not a launch blocker.

## 7a. Share page

`/s/[code]` shows a result a player shared from the app: a caption (Shared result, or Daily with the date), the level title and difficulty, the board as the puzzle (no solution), the result as text ("7 commands, par 5, 9 steps", with a plain note when it matches par), one primary button (Play in the browser) and a secondary link (Download for Android). It reads `GET /v1/share/:code` and the level's board, renders per request (`connection()`) with fetches cached for a minute, and needs no JavaScript. The code is random and the response holds no name, email or program. An unknown code shows a plain "Result not found" notice with a link home (`notFound()`); an API outage shows a plain "could not be loaded" notice. The page is `noindex`, has a canonical URL, and its `opengraph-image` and `twitter-image` use the shared card renderer (level title, caption, result; token colors only). It sets no cookies and loads nothing from other sites. The privacy page describes opted-in profiles, what others see, reporting, share links and deletion.

## 8. Implementation phases (web)

These slot into the main plan; see [README_IMPLEMENTATION_PLAN.md](README_IMPLEMENTATION_PLAN.md).

1. **Skeleton:** `(public)` route group, shared layout, header and footer, tile wordmark, theme tokens, light/dark.
2. **Landing:** all sections, built from the real tile renderer and sample levels; responsive; no JavaScript.
3. **Download:** GitHub Releases integration with revalidation and fallback; QR generation; install steps.
4. **Legal and help:** how to play, privacy, contact; sitemap, robots, Open Graph image.
5. **Quality:** accessibility and contrast checks in both themes, performance budget, link checks, and a pass of the visual checklist at desktop and mobile widths.
6. **After launch:** level catalog and level pages, then optional browser play, then the account page when sync ships.

### Exit criteria for launch

- A visitor on a phone can go from landing to an installed app in a few taps, following only the page.
- A visitor on a desktop can get the link onto a phone (QR or a copyable link).
- The download button always points at the latest release, and the page still works if GitHub is slow or unavailable (fallback link).
- Pages work with JavaScript disabled.
- No third-party requests, cookies, or trackers.
- Both themes and both widths pass the visual checklist.

## 9. Open items

- Minimum supported Android version and real APK size (renders show placeholders).
- Whether the source repository is public, which decides the "Source" link.
- Contact details are no longer an open item: an admin sets them in the dashboard (Contact page) and `/contact` reads them from the API. If the API is down the page shows a plain notice and a link to the GitHub issues; with no email set it says no address is published. `/api/revalidate` also refreshes `/contact`.
- Real QR generation (the render's QR is a placeholder pattern, not scannable).
- Whether the first release notes come from GitHub's generated notes or a curated file.
- Final font (shared decision with the game).
