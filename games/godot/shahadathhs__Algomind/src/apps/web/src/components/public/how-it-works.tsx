import { Caption } from "@/components/ui/caption";
import { Section } from "@/components/ui/section";
import { TapeView } from "@/components/ui/tape-view";
import { FAILED_PROGRAM, READY_COUNT, RUNNING_STEP, SOLUTION } from "@/lib/sample-screens";
import { tapeFromProgram } from "@/lib/tape";

const STEPS = [
  {
    title: "Build",
    text: "Pick instructions and arrange them on the tape. Move, turn left, turn right, and repeat a group a set number of times or until a wall, use an if block to choose by what is beside the automaton, and name a group of commands as a procedure to run it from several places.",
    label: `A tape with ${READY_COUNT} instructions and an empty slot to add more.`,
    tiles: tapeFromProgram(SOLUTION.slice(0, READY_COUNT), { emptySlot: "plus" }),
    head: undefined,
  },
  {
    title: "Run",
    text: "Run it at a readable speed or step through one instruction at a time.",
    label: `A tape mid-run: ${RUNNING_STEP} instructions done, the next under the read-head.`,
    tiles: tapeFromProgram(SOLUTION, { current: RUNNING_STEP }),
    head: RUNNING_STEP,
  },
  {
    title: "Debug",
    text: "A failed run says what happened. Edit the program and try again.",
    label: "A tape after a failed run: the failing instruction is marked with a cross.",
    tiles: tapeFromProgram(FAILED_PROGRAM, { current: FAILED_PROGRAM.length - 1, failed: true }),
    head: FAILED_PROGRAM.length - 1,
  },
];

export function HowItWorks() {
  return (
    <Section id="how-it-works" reveal>
      <Caption as="h2">How it works</Caption>
      <ol className="mt-8 grid gap-12 lg:grid-cols-3 lg:gap-8">
        {STEPS.map((step, i) => (
          <li key={step.title}>
            <TapeView look="depth" tiles={step.tiles} head={step.head} label={step.label} />
            <p className="mt-5 text-[11px] tracking-[2px] text-mute">{`0${i + 1}`}</p>
            <h3 className="mt-1 mb-2 text-[26px] tracking-[1px] uppercase">{step.title}</h3>
            <p className="max-w-[340px] text-[15px] leading-normal font-semibold tracking-[0.3px] text-mute">
              {step.text}
            </p>
          </li>
        ))}
      </ol>
    </Section>
  );
}
