import { Key } from "@/components/ui/key";
import { Container } from "@/components/ui/container";
import { DownloadIcon } from "@/components/ui/download-icon";
import { PrimaryButton } from "@/components/ui/primary-button";

/** The closing band: a solid ink tile with the primary button repeated. */
export function DownloadBand() {
  return (
    <section aria-labelledby="band-title" className="pb-14 sm:pb-[72px]">
      <Container>
        <Key tone="ink" lip={6} className="flex w-full">
          <div
            className="tile flex flex-col gap-8 bg-ink px-6 py-10 text-on-ink sm:flex-row sm:items-center sm:justify-between sm:px-12 sm:py-12"
            style={{ ["--chamfer" as string]: "24px" }}
          >
            <h2
              id="band-title"
              className="text-[34px] leading-none tracking-[1px] uppercase sm:text-[38px]"
            >
              Free for Android.
            </h2>
            <PrimaryButton
              href="/download"
              icon={<DownloadIcon />}
              size="md"
              className="w-full sm:w-auto"
            >
              Download for Android
            </PrimaryButton>
          </div>
        </Key>
      </Container>
    </section>
  );
}
