import { LoadingBlock } from "@/components/public/loading-block";
import { Container } from "@/components/ui/container";

/** Shown at once when a page of the site is opened, until its own content arrives. */
export default function Loading() {
  return (
    <>
      <Container className="pt-6 pb-8">
        <div aria-hidden="true" className="h-12 w-2/3 max-w-[420px] border-b-2 border-faint" />
      </Container>
      <LoadingBlock label="page" tiles={5} />
    </>
  );
}
