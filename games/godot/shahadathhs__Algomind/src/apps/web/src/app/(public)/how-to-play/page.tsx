import type { Metadata } from "next";
import Link from "next/link";
import { ProsePage } from "@/components/public/prose-page";
import { ProseSection } from "@/components/public/prose-section";
import { TileLegend } from "@/components/public/tile-legend";
import { BoardView } from "@/components/ui/board-view";
import { CommandTile } from "@/components/ui/command-tile";
import { TapeView } from "@/components/ui/tape-view";
import type { Command } from "@/lib/board";
import { FAILED_BOARD, READY_BOARD, RUNNING_STEP, SOLUTION } from "@/lib/sample-screens";
import { tapeFromProgram } from "@/lib/tape";
import { pageMetadata } from "@/lib/seo";

const DESCRIPTION =
  "How Algomind works: build a program from instruction tiles, run it, and read what happened when it fails.";

export const metadata: Metadata = pageMetadata({
  title: "How to play",
  shareTitle: "How to play Algomind",
  description: DESCRIPTION,
  path: "/how-to-play",
});

const COMMANDS: { command: Command; name: string; text: string }[] = [
  { command: "move", name: "Move", text: "Move one cell in the direction the automaton faces." },
  { command: "left", name: "Left", text: "Turn 90 degrees to the left without moving." },
  { command: "right", name: "Right", text: "Turn 90 degrees to the right without moving." },
  {
    command: "inc",
    name: "Count up",
    text: "Add one to the counter N. It keeps its value between rounds and stops at 11.",
  },
  {
    command: "mark",
    name: "Mark",
    text: "Drop a breadcrumb on the cell the automaton stands on: an arrow that points to the cell behind it.",
  },
  {
    command: "repeat",
    name: "Repeat",
    text: "Start a loop. Add commands to it, then end the loop.",
  },
  {
    command: "until",
    name: "Repeat until",
    text: "Start a loop that runs until a wall or the edge of the board is straight ahead, or until the goal is reached.",
  },
  {
    command: "if",
    name: "If",
    text: "Look at the cell on one side. Run the commands under then if it is open, and the commands under else if it is not.",
  },
  {
    command: "proc",
    name: "Procedure",
    text: "Define a named group of commands, A, B or C. It does not run where it stands.",
  },
  {
    command: "call",
    name: "Call",
    text: "Run a procedure you defined, then carry on with the next command. In some levels a call can look ahead, left or right, and runs only while that is clear.",
  },
];

const MESSAGES = [
  {
    message: "A guard reached the automaton",
    text: "A guard stood on the automaton's cell after a step, or they swapped places. The guard is striped yellow. Wait a step, or take another way.",
  },
  {
    message: "The automaton tried to go through a locked door, or a shut gate",
    text: "A door opens only after its key has been entered, and a gate follows its switch. The instruction that walked into it is marked with a cross.",
  },
  {
    message: "The automaton reached the target before every item was delivered",
    text: "Crates must be on their docks before the target counts. Deliver them first, then go to the target.",
  },
  {
    message: "The procedures called each other too many times",
    text: "A procedure that calls itself needs a condition on its call, so that it stops. Give the call a sensor: it then runs only while the sensor is true.",
  },
  {
    message: "The automaton tried to move into a wall",
    text: "The run stopped. The wall it hit is striped yellow and the instruction that did it is marked with a cross. A move past the edge of the board counts the same way.",
  },
  {
    message: "The program ended before the goal",
    text: "Every instruction ran and the automaton is not on the target. Add instructions or change them.",
  },
  {
    message: "The program ran too long and was stopped",
    text: "Each level has a step limit so a program can never run forever. Shorten the program or change what it does.",
  },
];

export default function HowToPlayPage() {
  return (
    <ProsePage
      wide
      title="How to play"
      lead="Build a program from instruction tiles, run it, and guide the automaton to the target. There are no lives and no timers."
    >
      <ProseSection
        title="The board"
        figure={
          <BoardView
            look="depth"
            board={READY_BOARD}
            label="A board with a wall of three cells, the automaton at the bottom right facing up, and the yellow target just above the wall."
          />
        }
      >
        <p>
          The automaton is the dark block with a yellow wedge; the wedge shows which way it faces.
          The target is the yellow cell with a ring and a dot. Hatched cells are walls. Reach the
          target to solve the level.
        </p>
      </ProseSection>

      <ProseSection title="Commands" spread>
        <ul className="!list-none !pl-0 lg:grid lg:grid-cols-2 lg:gap-x-12">
          {COMMANDS.map((item) => (
            <li key={item.command} className="view-rise flex items-center gap-4 !pl-0 pb-3">
              <CommandTile command={item.command} />
              <span>
                <strong className="block text-lg tracking-[1px] text-ink uppercase">
                  {item.name}
                </strong>
                {item.text}
              </span>
            </li>
          ))}
        </ul>
        <p>
          Each level lists the commands you can use and the most instructions a program may hold.
          The counter above the board shows how many you have used.
        </p>
      </ProseSection>

      <ProseSection title="On the board" spread>
        <TileLegend />
        <p>
          When a level has more than one pair of a tile, the two cells of a pair carry the same
          number of small squares, so you can tell which belongs to which without colour.
        </p>
      </ProseSection>

      <ProseSection title="Loops">
        <p>
          A loop carries out the commands inside it again and again. Select its count tile to change
          how many rounds it runs. A loop uses one slot for its count and one for each command
          inside it, and the counter above the board counts slots. While a loop runs, the count tile
          shows the current round.
        </p>
        <p>
          A repeat until loop has no count. Before each round it looks at the cell straight ahead.
          If that cell is a wall or off the board, the loop ends. Otherwise the commands inside run
          once more. A loop that starts facing a wall runs none of them. It uses the same slots as
          any other loop, and it works for a corridor of any length.
        </p>
      </ProseSection>

      <ProseSection title="If and sensors">
        <p>
          An if block makes a decision. It has a sensor: clear ahead, clear left or clear right. The
          sensor is true when the cell on that side is on the board and is not a wall. Reading it
          costs no step. If it is true, the commands under then run. If it is not, the commands
          under else run, and else may be empty.
        </p>
        <p>
          An if block uses one slot, plus one for each command in then and in else. It can stand on
          its own or inside a loop, but not inside the then of another if block. A repeat until loop
          can also wait for the goal, which keeps a program with decisions going until it arrives.
        </p>
      </ProseSection>

      <ProseSection title="The counter">
        <p>
          Some levels give you a counter named N. It starts at 1 each run. The count up command adds
          one to it and takes one slot and one step. A repeat loop can take N as its count instead
          of a number: it reads N when it starts and runs that many rounds, whatever happens to N
          inside it.
        </p>
        <p>
          Use it for shapes that grow: a loop that walks N cells, turns, and counts up, repeated
          again and again, draws a spiral.
        </p>
      </ProseSection>

      <ProseSection title="Loops inside loops">
        <p>
          A few levels let a loop hold one more loop. The inner loop runs all its rounds each time
          the outer loop runs a round. That is two levels at most. Slots add up: a loop uses one
          slot plus the slots of everything inside it, inner loop included.
        </p>
      </ProseSection>

      <ProseSection title="Breadcrumbs and else if">
        <p>
          The mark command leaves a breadcrumb on the cell the automaton stands on. It is a small
          arrow pointing to the cell behind the automaton, which is the cell it came from when it
          has just stepped forward. A cell keeps the first breadcrumb it gets. Marking a cell again
          changes nothing.
        </p>
        <p>
          With marks on the board, an if block gains six sensors. Fresh ahead, left and right are
          true for an open cell with no breadcrumb. Back ahead, left and right are true for the cell
          that the breadcrumb under the automaton points to: the way back. Reading a sensor costs no
          step.
        </p>
        <p>
          The else of an if block can hold one more if block, called else if, instead of commands. A
          chain of up to six ifs chooses between many cases, and the first sensor that is true wins.
          Each if in the chain uses one slot plus its own then commands. Together they let a program
          explore a maze that has loops: mark the cell, step onto a fresh cell, and follow the
          breadcrumbs back when none is left.
        </p>
      </ProseSection>

      <ProseSection title="Visit every cell">
        <p>
          Some boards have no target. The level is solved the moment the automaton has entered or
          started on every floor cell, that is, every cell that is not a wall. The board shows the
          cells visited so far and the game counts them, for example 12 of 30 cells. A step limit
          still applies, so wandering fails. A common answer is to run to the wall, step over, and
          run back, row by row.
        </p>
      </ProseSection>

      <ProseSection title="Procedures">
        <p>
          A procedure is a named group of commands, A, B or C. You define it once and call it from
          several places, so a shape that comes back along the route is written only once. A
          definition does not run where it stands. Each call runs the commands of that procedure and
          then the program goes on.
        </p>
        <p>
          A call uses one slot. A definition uses one slot plus one for each command in it. A
          procedure can hold moves, turns, if blocks and loops, but a call to another procedure only
          in the levels that teach recursion (below). A call can stand on its own or inside a loop.
        </p>
      </ProseSection>

      <ProseSection title="A procedure that calls itself">
        <p>
          In the last worlds a procedure may call procedures, itself included, and a call may carry
          a sensor. The call runs only while the sensor is true. That is how a recursion stops: when
          the sensor is false the call is skipped and the procedure carries on with what follows it.
          What follows a call runs when the call is over, once for each level, the deepest first.
        </p>
        <p>
          A procedure that calls itself with no sensor never stops. The run ends once it has called
          itself too many times, and the message says so.
        </p>
      </ProseSection>

      <ProseSection title="Several boards">
        <p>
          Some levels have more than one board. One program must solve every board, so a program
          that counts the steps of the first board fails on the next. The board area shows one board
          at a time with a tab for each. Run tries the program on the selected board, and a board it
          has solved is marked with a check and the word. Editing the program clears the checks.
        </p>
      </ProseSection>

      <ProseSection
        title="The tape"
        figure={
          <TapeView
            look="depth"
            tiles={tapeFromProgram(SOLUTION, { current: RUNNING_STEP })}
            head={RUNNING_STEP}
            label="A tape mid-run. Instructions already run are solid, the current one is yellow under the read-head, and the rest are outlined."
          />
        }
      >
        <p>
          Your program is a strip of tiles. Tap a command to add it to the end; tap a tile to remove
          or move it. While a program runs, the strip slides under a fixed read-head.
        </p>
        <ul>
          <li>Solid tile: already run.</li>
          <li>Yellow tile: the instruction running now.</li>
          <li>Outlined tile: still to run.</li>
          <li>Dashed slot: empty, ready for a new instruction.</li>
        </ul>
        <p>The number under each tile is its step.</p>
      </ProseSection>

      <ProseSection title="Run, step, reset">
        <ul>
          <li>Run executes the program at a readable speed.</li>
          <li>Step runs one instruction at a time.</li>
          <li>Reset puts the automaton back at the start and keeps your program.</li>
        </ul>
        <p>You can edit the program again after any run.</p>
      </ProseSection>

      <ProseSection
        title="When a run fails"
        figure={
          <BoardView
            look="depth"
            board={FAILED_BOARD}
            label="A failed run: the automaton faces a wall that is striped yellow."
          />
        }
      >
        <p>A failed run always says what happened.</p>
        <ul className="!list-none !pl-0">
          {MESSAGES.map((item) => (
            <li key={item.message} className="!pl-0 pb-3">
              <strong className="block tracking-[1px] text-ink uppercase">{item.message}</strong>
              {item.text}
            </li>
          ))}
        </ul>
        <p>
          <Link href="/download">Download Algomind for Android</Link> to play.
        </p>
      </ProseSection>
    </ProsePage>
  );
}
