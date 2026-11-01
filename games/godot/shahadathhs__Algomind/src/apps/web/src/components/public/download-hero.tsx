import { Key } from "@/components/ui/key";
import { Container } from "@/components/ui/container";
import { DownloadIcon } from "@/components/ui/download-icon";
import { PrimaryButton } from "@/components/ui/primary-button";
import { QrCode } from "@/components/ui/qr-code";
import { TextLink } from "@/components/ui/text-link";
import { qrPayload } from "@/lib/qr";
import { releaseMeta, releasesPageUrl, shortHash, type ReleaseState } from "@/lib/releases";

/**
 * The top of the download page. With a release it shows the Download APK button (a direct link to
 * the release asset) and its facts. Without one it says so plainly and links to the releases
 * page; no button ever points at a URL that is not known to exist.
 */
export function DownloadHero({ state }: { state: ReleaseState }) {
  return (
    <section>
      <Container className="grid items-start gap-10 pt-6 pb-14 lg:grid-cols-[1fr_300px] lg:gap-16 lg:pb-16">
        <div className="lg:pt-8">
          <h1 className="text-[clamp(30px,11.4vw,44px)] leading-none tracking-[1px] uppercase sm:text-[56px]">
            Download Algomind.
          </h1>
          <p className="mt-5 mb-8 max-w-[520px] text-lg leading-normal font-semibold tracking-[0.5px] text-mute">
            Algomind is not on Google Play. Install it directly from this page.
          </p>
          {state.status === "available" ? <Available state={state} /> : <Unavailable />}
        </div>
        <Key className="hidden lg:flex">
          <div className="tile qr-tile p-5" style={{ ["--chamfer" as string]: "18px" }}>
            <QrCode
              text={qrPayload()}
              label="QR code that opens the Algomind download page on a phone."
            />
            <p className="mt-2 text-center text-xs tracking-[2px] uppercase">Scan on your phone</p>
          </div>
        </Key>
      </Container>
    </section>
  );
}

function Available({ state }: { state: Extract<ReleaseState, { status: "available" }> }) {
  const { release } = state;
  return (
    <>
      <PrimaryButton
        href={release.apkUrl}
        external
        icon={<DownloadIcon />}
        className="w-full sm:w-auto"
      >
        Download APK
      </PrimaryButton>
      <p className="mt-5 text-[13px] font-bold tracking-[2px] uppercase">
        {releaseMeta(release).join(" · ")}
      </p>
      {release.sha256 && (
        <p className="mt-2 text-xs font-bold tracking-[2px] text-mute uppercase">
          <span>SHA-256</span>{" "}
          <span className="tabular-nums" title={release.sha256}>
            {shortHash(release.sha256)}
          </span>{" "}
          <span className="normal-case">(full hash below)</span>
        </p>
      )}
    </>
  );
}

function Unavailable() {
  return (
    <div className="max-w-[520px]">
      <h2 className="text-[26px] leading-tight tracking-[1px] uppercase">
        No release available yet
      </h2>
      <p className="mt-2 text-base leading-normal font-semibold text-mute">
        The first Android build has not been published, or it cannot be reached right now. This page
        shows the download button as soon as a release is available.
      </p>
      <div className="mt-3">
        <TextLink href={releasesPageUrl()} external>
          Open the releases page
        </TextLink>
      </div>
    </div>
  );
}
