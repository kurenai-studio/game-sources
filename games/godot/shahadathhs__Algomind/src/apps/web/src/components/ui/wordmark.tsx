import { Key } from "@/components/ui/key";

const LETTERS = ["A", "L", "G", "O", "M", "I", "N", "D"];

/** The ALGOMIND wordmark: eight tiles, the first one signal yellow. */
export function Wordmark({ size = "md" }: { size?: "sm" | "md" }) {
  // Tiles shrink with the screen so the header fits a 280 px phone; full size from 464 px up.
  const box =
    size === "sm"
      ? "aspect-[22/30] w-[clamp(15px,5.6vw,22px)] text-[clamp(12px,4.6vw,18px)]"
      : "aspect-[26/34] w-[clamp(15px,5.6vw,26px)] text-[clamp(13px,4.7vw,22px)]";
  return (
    <span aria-label="Algomind" role="img" className="inline-flex gap-[2px] sm:gap-[3px]">
      {LETTERS.map((letter, i) => (
        <Key key={letter + i} tone={i === 0 ? "signal" : "ink"} lip={2}>
          <span
            aria-hidden="true"
            className={`tile flex items-center justify-center ${box} ${
              i === 0 ? "bg-signal text-on-signal" : "bg-ink text-on-ink"
            }`}
            style={{ ["--chamfer" as string]: "clamp(4px, 1.4vw, 6px)" }}
          >
            {letter}
          </span>
        </Key>
      ))}
    </span>
  );
}
