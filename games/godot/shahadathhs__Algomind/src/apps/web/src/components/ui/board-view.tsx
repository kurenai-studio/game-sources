import { BoardGraphic } from "@/components/ui/board-graphic";
import { depthBoardBounds } from "@/components/ui/depth-board-graphic";
import { type BoardData, describeBoard } from "@/lib/board";
import type { Look } from "@/lib/look";

const SIZE = 350;

/**
 * A standalone board as an inline SVG that scales to its container's width. Reused by the public
 * pages and the dashboard. The depth board is wider than it is tall, so the view box is cropped to
 * the drawing and the page does not keep empty space above and below it.
 */
export function BoardView({
  board,
  label,
  className = "block h-auto w-full",
  look = "flat",
}: {
  board: BoardData;
  /** Accessible name; defaults to a description of the board. */
  label?: string;
  className?: string;
  look?: Look;
}) {
  let viewBox = `0 0 ${SIZE} ${SIZE}`;
  if (look === "depth") {
    // The drawing is fitted and centered in the SIZE square; crop the square to it.
    const box = depthBoardBounds(board);
    const scale = SIZE / Math.max(box.width, box.height);
    const [w, h] = [box.width * scale, box.height * scale];
    viewBox = `${((SIZE - w) / 2).toFixed(1)} ${((SIZE - h) / 2).toFixed(1)} ${w.toFixed(1)} ${h.toFixed(1)}`;
  }
  return (
    <svg
      viewBox={viewBox}
      role="img"
      aria-label={label ?? describeBoard(board)}
      className={className}
    >
      <BoardGraphic board={board} size={SIZE} look={look} />
    </svg>
  );
}
