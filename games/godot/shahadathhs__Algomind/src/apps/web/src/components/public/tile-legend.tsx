import { TileMarks } from "@/components/ui/tile-marks";
import type { BoardTiles } from "@/lib/board";
import { tileShapes } from "@/lib/board-tiles";

type Item = { name: string; text: string; cells: number; tiles: BoardTiles };
const P = (x: number, y: number) => ({ x, y });

const ITEMS: Item[] = [
  {
    name: "Guard",
    text: "It walks a fixed route, one cell for each of your steps. If it reaches the automaton, or swaps places with it, the run fails. Count its steps, then wait or go round.",
    cells: 3,
    tiles: { patrols: [{ pattern: "back_and_forth", cells: [P(0, 0), P(1, 0), P(2, 0)] }] },
  },
  {
    name: "Key and door",
    text: "A door stays shut until the automaton has entered the cell of its key. A shut door stops the automaton like a wall.",
    cells: 2,
    tiles: { locks: [{ key: P(0, 0), door: P(1, 0) }] },
  },
  {
    name: "Crate and dock",
    text: "Enter a crate to pick it up. You carry one at a time. Enter its dock to put it down. The target counts only when every crate is delivered.",
    cells: 2,
    tiles: { deliveries: [{ item: P(0, 0), dock: P(1, 0) }] },
  },
  {
    name: "Switch and gate",
    text: "Entering a switch flips its gate, every time: shut to open, open to shut. A shut gate stops the automaton like a wall. Count your passes.",
    cells: 2,
    tiles: { switches: [{ switch: P(0, 0), gate: P(1, 0) }] },
  },
  {
    name: "Ice",
    text: "A move onto ice slides on while the way is free. It stops on the first cell that is not ice, or in front of a wall.",
    cells: 2,
    tiles: { ice: [P(0, 0), P(1, 0)] },
  },
  {
    name: "Belt",
    text: "After an action that leaves the automaton on a belt, it is carried one cell the way the chevrons point. A turn on a belt is carried too.",
    cells: 2,
    tiles: {
      belts: [
        { ...P(0, 0), dir: "E" },
        { ...P(1, 0), dir: "E" },
      ],
    },
  },
  {
    name: "Teleporter",
    text: "Entering one end puts the automaton on the other, in the same step and facing the same way. Arriving does not send it back.",
    cells: 3,
    tiles: { teleports: [{ a: P(0, 0), b: P(2, 0) }] },
  },
];

/** One sample of each tile of the later worlds, with what it does. */
export function TileLegend() {
  return (
    <ul className="!list-none !pl-0 lg:grid lg:grid-cols-2 lg:gap-x-12">
      {ITEMS.map((item) => (
        <li key={item.name} className="view-rise flex items-start gap-4 !pl-0 pb-4">
          <svg
            viewBox={`-0.1 -0.1 ${item.cells + 0.2} 1.2`}
            role="img"
            aria-label={`${item.name}, drawn on the board.`}
            className="mt-1 h-14 flex-none"
            style={{ width: `${item.cells * 3.5}rem` }}
          >
            {Array.from({ length: item.cells }, (_, i) => (
              <rect
                key={i}
                x={i + 0.02}
                y={0.02}
                width={0.96}
                height={0.96}
                className="fill-floor"
              />
            ))}
            <TileMarks shapes={tileShapes(item.tiles)} place={(x, y) => [x, y]} unit={1} />
          </svg>
          <span>
            <strong className="block text-lg tracking-[1px] text-ink uppercase">{item.name}</strong>
            {item.text}
          </span>
        </li>
      ))}
    </ul>
  );
}
