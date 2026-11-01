import { Caption } from "@/components/ui/caption";
import { Section } from "@/components/ui/section";
import { TextLink } from "@/components/ui/text-link";
import { APK_ARCHITECTURE, formatFileSize, formatReleaseDate, type Release } from "@/lib/releases";

/**
 * Facts about the APK being offered: file, version, date, size, what it runs on, and how to check
 * it. Shown only when a release is available, so every value here was read from that release.
 */
export function ApkInfo({ release }: { release: Release }) {
  const facts: [string, string][] = [
    ["File", release.apkName],
    ["Version", release.version],
    ["Released", formatReleaseDate(release.publishedAt)],
    ["Size", formatFileSize(release.apkBytes)],
    ["Works on", `Android phones with a ${APK_ARCHITECTURE} processor`],
    ["Build", "Debug build, signed with one fixed key"],
  ];
  const shown = facts.filter(([, value]) => value !== "");
  const verifyName = release.apkName;
  return (
    <Section>
      <Caption as="h2">About this APK</Caption>
      <dl className="mt-4 grid gap-x-12 sm:grid-cols-2">
        {shown.map(([label, value]) => (
          <div key={label} className="border-t-2 border-ink py-3">
            <dt className="text-xs font-bold tracking-[2px] text-mute uppercase">{label}</dt>
            <dd className="mt-1 text-lg leading-tight tracking-[0.5px] break-words">{value}</dd>
          </div>
        ))}
      </dl>
      {release.sha256 && (
        <div className="border-t-2 border-ink py-3">
          <p className="text-xs font-bold tracking-[2px] text-mute uppercase">SHA-256</p>
          <p className="mt-1 font-mono text-base leading-snug tracking-normal break-all select-all">
            {release.sha256}
          </p>
        </div>
      )}
      <div className="border-t-2 border-ink pt-4">
        <p className="text-xs font-bold tracking-[2px] text-mute uppercase">Check the file</p>
        <p className="mt-2 max-w-[620px] text-base leading-normal font-semibold text-mute">
          After downloading on a computer, compare the result of one of these with the SHA-256
          above.
        </p>
        <pre className="mt-3 font-mono text-sm leading-relaxed font-normal tracking-normal break-all whitespace-pre-wrap select-all">
          {`shasum -a 256 ${verifyName}\nGet-FileHash ${verifyName}`}
        </pre>
        <p className="mt-1 text-xs font-bold tracking-[2px] text-mute uppercase">
          First line: macOS and Linux (or sha256sum). Second line: Windows PowerShell.
        </p>
      </div>
      <ul className="mt-6 flex flex-wrap gap-x-8">
        <li>
          <TextLink href={release.apkUrl} external>
            Direct download link
          </TextLink>
        </li>
        <li>
          <TextLink href={release.pageUrl} external>
            Release page on GitHub
          </TextLink>
        </li>
      </ul>
    </Section>
  );
}
