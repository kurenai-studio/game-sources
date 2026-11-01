import { LoadingBlock } from "@/components/public/loading-block";
import { Container } from "@/components/ui/container";

/** The levels page reads the whole campaign, which can take a moment: show its shape first. */
export default function LevelsLoading() {
  return (
    <>
      <Container className="pt-6 pb-8">
        <h1 className="rise text-[clamp(30px,11.4vw,44px)] leading-none tracking-[1px] uppercase sm:text-[56px]">
          Levels.
        </h1>
        <p className="mt-5 max-w-[620px] text-lg leading-normal font-semibold tracking-[0.5px] text-mute">
          Levels are grouped into worlds, and each world teaches one idea.
        </p>
      </Container>
      <LoadingBlock label="levels" tiles={8} tall />
    </>
  );
}
