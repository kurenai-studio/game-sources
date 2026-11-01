import type { PlayerDetail } from "@/lib/admin/admin-api";
import { when } from "@/lib/admin/format";

/** The player's open sign-ins (one per device) and the settings they sync. */
export function PlayerSessions({
  sessions,
  settings,
}: {
  sessions: PlayerDetail["sessions"];
  settings: PlayerDetail["settings"];
}) {
  return (
    <section aria-label="Sessions and settings" className="mb-10">
      <h2 className="mb-3 text-xs font-bold tracking-[2px] text-mute uppercase">Sessions</h2>
      {sessions.length === 0 ? (
        <p className="mb-6 text-base font-semibold text-mute">Not signed in anywhere.</p>
      ) : (
        <ul className="mb-6 grid max-w-[760px]">
          {sessions.map((s) => (
            <li
              key={s.familyId}
              className="grid gap-x-5 border-t border-faint py-2 text-[15px] font-semibold sm:grid-cols-3"
            >
              <span>Started {when(s.startedAt)}</span>
              <span>Last used {when(s.lastUsedAt)}</span>
              <span className="text-mute">Expires {when(s.expiresAt)}</span>
            </li>
          ))}
        </ul>
      )}
      <h2 className="mb-3 text-xs font-bold tracking-[2px] text-mute uppercase">Synced settings</h2>
      {settings ? (
        <p className="max-w-[760px] text-[15px] font-semibold break-words">
          {JSON.stringify(settings.settings)} (changed {when(settings.updatedAt)})
        </p>
      ) : (
        <p className="text-base font-semibold text-mute">None saved.</p>
      )}
    </section>
  );
}
