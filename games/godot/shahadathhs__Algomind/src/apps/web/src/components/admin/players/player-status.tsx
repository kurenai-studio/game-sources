import type { PlayerStatus } from "@/lib/admin/admin-api";

/** Active is an outlined tile, suspended a solid one; both carry a word. */
export function PlayerStatusTile({ status }: { status: PlayerStatus }) {
  const solid = status === "SUSPENDED";
  return (
    <span
      className={`tile inline-flex h-7 items-center px-2.5 text-xs tracking-[2px] uppercase ${
        solid ? "bg-ink text-on-ink" : "bg-floor text-ink"
      }`}
      style={{
        ["--chamfer" as string]: "7px",
        outline: solid ? undefined : "2px solid currentColor",
        outlineOffset: "-2px",
      }}
    >
      {solid ? "Suspended" : "Active"}
    </span>
  );
}
