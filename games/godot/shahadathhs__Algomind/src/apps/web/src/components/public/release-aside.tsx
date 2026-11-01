import { Caption } from "@/components/ui/caption";
import { TextLink } from "@/components/ui/text-link";
import { developmentBuildUrl, releasesPageUrl, type ReleaseState } from "@/lib/releases";

/** Release notes, other builds, and what to know before installing. */
export function ReleaseAside({ state }: { state: ReleaseState }) {
  const release = state.status === "available" ? state.release : null;
  return (
    <div className="flex min-w-0 flex-col gap-8">
      {release && release.notes.length > 0 && (
        <div>
          <Caption as="h2">{`What is new in ${release.version}`}</Caption>
          <ul className="mt-3 space-y-1.5 text-base leading-normal font-semibold text-mute [overflow-wrap:anywhere]">
            {release.notes.map((line, i) => (
              <li key={i}>{`– ${line}`}</li>
            ))}
          </ul>
        </div>
      )}
      <div>
        <Caption as="h2">Other builds</Caption>
        <ul className="mt-2">
          {release && (
            <li>
              <TextLink href={developmentBuildUrl()} external>
                Latest development build
              </TextLink>
            </li>
          )}
          <li>
            <TextLink href={releasesPageUrl()} external>
              All releases
            </TextLink>
          </li>
        </ul>
      </div>
      <div>
        <Caption as="h2">Good to know</Caption>
        <p className="mt-3 text-base leading-normal font-semibold text-mute">
          Every build is signed with the same key, so updates install over older versions. Check the
          SHA-256 above if you want to verify the file. Algomind is not on Google Play and is not
          available for iPhone.
        </p>
      </div>
    </div>
  );
}
