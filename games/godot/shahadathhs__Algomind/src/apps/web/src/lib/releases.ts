const DEFAULT_REPOSITORY = "shahadathhs/Algomind";
const REPOSITORY_PATTERN = /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/;
const REVALIDATE_SECONDS = 3600;
const FETCH_TIMEOUT_MS = 5000;

/** The GitHub repository that hosts the releases. Set GITHUB_REPOSITORY as "owner/name". */
export function releaseRepository(): string {
  const value = process.env.GITHUB_REPOSITORY?.trim();
  return value && REPOSITORY_PATTERN.test(value) ? value : DEFAULT_REPOSITORY;
}

/**
 * The GitHub API address. Defaults to api.github.com; set GITHUB_API_URL to point at a GitHub
 * Enterprise server, or at a local stand-in when testing the download page.
 */
export function githubApiBase(): string {
  const value = process.env.GITHUB_API_URL?.trim();
  if (value) {
    try {
      const url = new URL(value);
      if (url.protocol === "https:" || url.protocol === "http:") return url.href.replace(/\/$/, "");
    } catch {
      // Fall through to the default.
    }
  }
  return "https://api.github.com";
}

/** The releases page. A plain link that is always safe to render. */
export function releasesPageUrl(repository = releaseRepository()): string {
  return `https://github.com/${repository}/releases`;
}

/** The rolling development build that CI refreshes on every push to main. */
export function developmentBuildUrl(repository = releaseRepository()): string {
  return `https://github.com/${repository}/releases/tag/latest`;
}

export type Release = {
  /** Version without a leading "v", for example "0.1.0". */
  version: string;
  tag: string;
  /** Release page on GitHub. */
  pageUrl: string;
  /** When the release was published (ISO 8601), or null when GitHub did not say. */
  publishedAt: string | null;
  /** Direct APK download. Always an https URL. */
  apkUrl: string;
  apkName: string;
  apkBytes: number;
  /** Lowercase 64-character hex SHA-256 of the APK, or null when it could not be read. */
  sha256: string | null;
  /** Plain-text release note lines. */
  notes: string[];
};

export type ReleaseState =
  | { status: "available"; release: Release }
  | { status: "unavailable"; reason: "none" | "private" | "error" };

type Asset = { name: string; size: number; url: string };

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function httpsUrl(value: unknown): string | null {
  if (typeof value !== "string") return null;
  try {
    const url = new URL(value);
    return url.protocol === "https:" ? url.href : null;
  } catch {
    return null;
  }
}

function isoDate(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const time = Date.parse(value);
  return Number.isNaN(time) ? null : new Date(time).toISOString();
}

/** "18 Oct 2026" in UTC, so the server and every visitor read the same date. */
export function formatReleaseDate(iso: string | null): string {
  if (!iso) return "";
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return "";
  return date.toLocaleDateString("en-GB", {
    day: "numeric",
    month: "short",
    year: "numeric",
    timeZone: "UTC",
  });
}

/**
 * The CPU architecture the APK is built for. Keep this in step with the Android export preset
 * (apps/game/export_presets.cfg: only arm64-v8a is enabled).
 */
export const APK_ARCHITECTURE = "64-bit ARM (arm64-v8a)";

function parseAssets(value: unknown): Asset[] {
  if (!Array.isArray(value)) return [];
  const assets: Asset[] = [];
  for (const item of value) {
    if (!isRecord(item)) continue;
    const url = httpsUrl(item.browser_download_url);
    if (typeof item.name !== "string" || typeof item.size !== "number" || !url) continue;
    if (!Number.isFinite(item.size) || item.size <= 0) continue;
    assets.push({ name: item.name, size: item.size, url });
  }
  return assets;
}

/** The release before its checksum is read; null when the response is not a usable release. */
export type ParsedRelease = Omit<Release, "sha256"> & { checksumUrl: string | null };

/**
 * Validates a GitHub "release" response strictly. Returns null for anything that is not a
 * published release with an .apk asset, so the caller falls back instead of rendering bad data.
 */
export function parseRelease(json: unknown): ParsedRelease | null {
  if (!isRecord(json)) return null;
  if (json.draft === true) return null;
  const tag = json.tag_name;
  if (typeof tag !== "string" || tag.trim() === "") return null;
  const pageUrl = httpsUrl(json.html_url);
  if (!pageUrl) return null;

  const assets = parseAssets(json.assets);
  const apk = assets.find((asset) => asset.name.toLowerCase().endsWith(".apk"));
  if (!apk) return null;
  const checksum =
    assets.find((asset) => asset.name === `${apk.name}.sha256`) ??
    assets.find((asset) => asset.name.toLowerCase().endsWith(".sha256"));

  return {
    version: versionFromTag(tag),
    tag,
    pageUrl,
    publishedAt: isoDate(json.published_at),
    apkUrl: apk.url,
    apkName: apk.name,
    apkBytes: apk.size,
    checksumUrl: checksum?.url ?? null,
    notes: releaseNoteLines(typeof json.body === "string" ? json.body : ""),
  };
}

export function versionFromTag(tag: string): string {
  return tag.trim().replace(/^v(?=\d)/i, "");
}

/**
 * Reads a checksum file. Accepts a bare hash or the `sha256sum` format ("hash  filename"), and
 * when several files are listed prefers the line for `filename`.
 */
export function parseChecksum(text: string, filename?: string): string | null {
  const hashes: { hash: string; file: string | null }[] = [];
  for (const line of text.split(/\r?\n/)) {
    const match = /^\s*([0-9a-fA-F]{64})(?:\s+\*?(.+?))?\s*$/.exec(line);
    if (match) hashes.push({ hash: match[1].toLowerCase(), file: match[2] ?? null });
  }
  if (hashes.length === 0) return null;
  const named = filename ? hashes.find((entry) => entry.file === filename) : undefined;
  return (named ?? hashes[0]).hash;
}

/** "24 MB" style size using decimal megabytes, as phones and file managers show it. */
export function formatFileSize(bytes: number): string {
  if (!Number.isFinite(bytes) || bytes <= 0) return "";
  if (bytes < 1_000_000) return `${Math.max(1, Math.round(bytes / 1000))} KB`;
  const megabytes = bytes / 1_000_000;
  return `${megabytes >= 10 ? Math.round(megabytes) : Math.round(megabytes * 10) / 10} MB`;
}

/** The meta line facts of a release: version and file size. */
export function releaseMeta(release: Pick<Release, "version" | "apkBytes">): string[] {
  return [`Version ${release.version}`, formatFileSize(release.apkBytes)].filter(Boolean);
}

/** "9F2C…E41A": the first and last four characters in capitals. */
export function shortHash(hash: string): string {
  return `${hash.slice(0, 4)}…${hash.slice(-4)}`.toUpperCase();
}

/**
 * Turns Markdown release notes into a few plain lines: headings and blank lines go, list markers
 * are dropped, links and emphasis are flattened, and the count is capped.
 */
export function releaseNoteLines(body: string, max = 8): string[] {
  const lines: string[] = [];
  for (const raw of body.split(/\r?\n/)) {
    let line = raw.trim();
    if (line === "" || /^#{1,6}\s/.test(line) || /^(-{3,}|\*{3,}|_{3,})$/.test(line)) continue;
    line = line
      .replace(/^[-*+]\s+/, "")
      .replace(/^\d+[.)]\s+/, "")
      .replace(/!?\[([^\]]*)\]\([^)]*\)/g, "$1")
      .replace(/(\*\*|__|`)/g, "")
      .replace(/<[^>]*>/g, "")
      .trim();
    if (line === "") continue;
    lines.push(line.length > 160 ? `${line.slice(0, 157)}...` : line);
    if (lines.length === max) break;
  }
  return lines;
}

function githubHeaders(accept: string): HeadersInit {
  const headers: Record<string, string> = {
    Accept: accept,
    "User-Agent": "algomind-web",
    "X-GitHub-Api-Version": "2022-11-28",
  };
  const token = process.env.GITHUB_TOKEN?.trim();
  if (token) headers.Authorization = `Bearer ${token}`;
  return headers;
}

function request(url: string, accept: string): Promise<Response> {
  return fetch(url, {
    headers: githubHeaders(accept),
    next: { revalidate: REVALIDATE_SECONDS },
    signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
  });
}

async function readChecksum(url: string | null, filename: string): Promise<string | null> {
  if (!url) return null;
  try {
    // The asset URL is a public download link; the token is not sent there.
    const res = await fetch(url, {
      headers: { "User-Agent": "algomind-web" },
      next: { revalidate: REVALIDATE_SECONDS },
      signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
    });
    if (!res.ok) return null;
    const text = await res.text();
    return text.length > 4096 ? null : parseChecksum(text, filename);
  } catch {
    return null;
  }
}

/** With a token configured, refuses private repositories: anonymous visitors cannot download. */
async function isPrivateRepository(repository: string): Promise<boolean> {
  if (!process.env.GITHUB_TOKEN?.trim()) return false;
  try {
    const res = await request(
      `${githubApiBase()}/repos/${repository}`,
      "application/vnd.github+json",
    );
    if (!res.ok) return true;
    const json: unknown = await res.json();
    return !isRecord(json) || json.private !== false;
  } catch {
    return true;
  }
}

/**
 * Reads the latest GitHub release, revalidated hourly. Never throws: when there is no release,
 * the repository is private (anonymous requests get 404 or 401), or GitHub is unreachable, it
 * returns an "unavailable" state and the page renders its fallback.
 */
export async function getLatestRelease(): Promise<ReleaseState> {
  const repository = releaseRepository();
  try {
    const res = await request(
      `${githubApiBase()}/repos/${repository}/releases/latest`,
      "application/vnd.github+json",
    );
    if (res.status === 404) return { status: "unavailable", reason: "none" };
    if (res.status === 401 || res.status === 403)
      return { status: "unavailable", reason: "private" };
    if (!res.ok) return { status: "unavailable", reason: "error" };

    const parsed = parseRelease(await res.json());
    if (!parsed) return { status: "unavailable", reason: "none" };
    if (await isPrivateRepository(repository)) return { status: "unavailable", reason: "private" };

    const { checksumUrl, ...rest } = parsed;
    const sha256 = await readChecksum(checksumUrl, parsed.apkName);
    return { status: "available", release: { ...rest, sha256 } };
  } catch {
    return { status: "unavailable", reason: "error" };
  }
}
