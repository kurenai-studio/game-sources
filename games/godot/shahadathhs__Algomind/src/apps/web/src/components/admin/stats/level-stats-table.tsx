import { dropText, percentOf, type StatGroup } from "@/lib/admin/level-stats";
import { DIFFICULTY_LABEL } from "@/lib/campaign";
import { LabelTile } from "../ui";

const HEADS = [
  "Level",
  "Solvers",
  "Avg slots",
  "Par",
  "Limit",
  "At par",
  "Within two",
  "Solvers vs previous",
];

/** One table, grouped by world and chapter; the numbers come from verified results only. */
export function LevelStatsTable({ groups }: { groups: StatGroup[] }) {
  return (
    <div className="overflow-x-auto">
      <table className="w-full min-w-[860px] border-collapse text-left">
        <caption className="sr-only">Verified results per level, in campaign order</caption>
        <thead>
          <tr className="border-b-2 border-ink text-xs tracking-[2px] text-mute uppercase">
            {HEADS.map((h) => (
              <th key={h} scope="col" className="py-3 pr-4 font-bold">
                {h}
              </th>
            ))}
          </tr>
        </thead>
        {groups.map((g) => (
          <tbody key={g.key}>
            <tr>
              <th
                colSpan={HEADS.length}
                scope="colgroup"
                className="pt-6 pb-2 text-left text-sm tracking-[2px] uppercase"
              >
                {g.title}
              </th>
            </tr>
            {g.rows.map((r) => (
              <tr key={r.slug} className="border-b border-faint align-top">
                <td className="py-3 pr-4">
                  <span className="text-base tracking-[1px]">{r.title}</span>
                  <p className="mt-1 text-sm font-semibold text-mute">
                    {DIFFICULTY_LABEL[r.difficulty]}
                  </p>
                </td>
                <td className="py-3 pr-4 text-[15px] font-semibold tabular-nums">{r.solvers}</td>
                <td className="py-3 pr-4 text-[15px] font-semibold tabular-nums">
                  {r.solvers ? r.avgSlots : "-"}
                </td>
                <td className="py-3 pr-4 text-[15px] font-semibold tabular-nums">{r.par}</td>
                <td className="py-3 pr-4 text-[15px] font-semibold tabular-nums">{r.limit}</td>
                <td className="py-3 pr-4 text-[15px] font-semibold tabular-nums">
                  {r.solvers ? `${r.atPar} (${percentOf(r.atPar, r.solvers)})` : "-"}
                </td>
                <td className="py-3 pr-4 text-[15px] font-semibold tabular-nums">
                  {r.solvers ? `${r.nearPar} (${percentOf(r.nearPar, r.solvers)})` : "-"}
                </td>
                <td className="py-3 text-[15px] font-semibold">
                  <span className="mr-2">{dropText(r)}</span>
                  {r.sharp && <LabelTile solid>Sharp drop</LabelTile>}
                </td>
              </tr>
            ))}
          </tbody>
        ))}
      </table>
    </div>
  );
}
