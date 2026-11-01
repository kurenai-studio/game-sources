import type { PlayerDetail } from "@/lib/admin/admin-api";
import { when } from "@/lib/admin/format";

export function PlayerProgress({ progress }: { progress: PlayerDetail["progress"] }) {
  return (
    <section aria-label="Progress" className="mb-10">
      <h2 className="mb-3 text-xs font-bold tracking-[2px] text-mute uppercase">Progress</h2>
      {progress.length === 0 ? (
        <p className="text-base font-semibold text-mute">No level cleared on the server.</p>
      ) : (
        <ul className="grid max-w-[760px]">
          {progress.map((p) => (
            <li
              key={p.levelSlug}
              className="grid gap-x-5 border-t border-faint py-2 text-[15px] font-semibold sm:grid-cols-[1fr_120px_160px]"
            >
              <span>{p.levelSlug}</span>
              <span className="tabular-nums">
                {p.bestCommands} commands, v{p.levelVersion}
              </span>
              <span className="text-mute">{when(p.completedAt)}</span>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
