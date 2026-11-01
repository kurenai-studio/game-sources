"use client";

import { useCallback, useEffect, useState } from "react";
import { SessionEndedError } from "@/lib/api/errors";
import type { PointsRulesInput, RuleSet } from "@/lib/admin/admin-api";
import { apiMessage } from "@/lib/admin/messages";
import { Notice, PageHeading } from "./ui";
import { PointsRulesForm } from "./points-rules-form";
import { useAdminApi } from "./use-admin-api";

/** How results are scored: every rule version, and a form for the next one. */
export function PointsRules() {
  const api = useAdminApi();
  const [items, setItems] = useState<RuleSet[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    try {
      setItems((await api.listPointsRules()).items);
    } catch (err) {
      if (!(err instanceof SessionEndedError)) setError(apiMessage(err));
    }
  }, [api]);

  useEffect(() => {
    // The state updates run after the request resolves, not synchronously in the effect.
    // oxlint-disable-next-line react-hooks/set-state-in-effect
    void load();
  }, [load]);

  async function create(rules: PointsRulesInput) {
    setError(null);
    setNotice(null);
    setBusy(true);
    try {
      const made = await api.createPointsRules(rules);
      setNotice(`Rule version ${made.version} is active.`);
      await load();
    } catch (err) {
      if (!(err instanceof SessionEndedError)) setError(apiMessage(err));
    } finally {
      setBusy(false);
    }
  }

  const active = items?.find((i) => i.active);

  return (
    <div>
      <PageHeading caption="Admin" title="Points" />
      <p className="mb-8 max-w-[640px] text-base font-semibold text-mute">
        A verified clear earns a base by difficulty, a bonus for matching par, a smaller bonus for
        par steps, and a bonus for the first clear. Points only ever go up for a level, by the
        amount a better result adds.
      </p>
      {notice && (
        <div className="mb-4">
          <Notice kind="info">{notice}</Notice>
        </div>
      )}
      {error && (
        <div className="mb-4">
          <Notice>{error}</Notice>
        </div>
      )}
      {!items && !error && (
        <p role="status" className="text-sm tracking-[2px] uppercase">
          Loading
        </p>
      )}
      {items && (
        <ul className="mb-12 grid max-w-[760px]" aria-label="Rule versions">
          {items.map((v) => (
            <li
              key={v.version}
              className="grid gap-x-5 gap-y-1 border-t-2 border-ink py-3 sm:grid-cols-[80px_1fr_auto]"
            >
              <span className="text-lg tracking-[1px] tabular-nums uppercase">v{v.version}</span>
              <span className="text-[15px] font-semibold">
                Base {v.rules.base.easy} / {v.rules.base.medium} / {v.rules.base.hard}. Par{" "}
                {v.rules.parFull}, near {v.rules.parNear} within {v.rules.nearSlots} slots. Steps{" "}
                {v.rules.stepsBonus}. First clear {v.rules.firstClear}.
              </span>
              {v.active ? (
                <span
                  className="tile inline-flex h-7 items-center bg-ink px-2.5 text-xs tracking-[2px] text-on-ink uppercase"
                  style={{ ["--chamfer" as string]: "7px" }}
                >
                  Active
                </span>
              ) : (
                <span className="text-xs tracking-[2px] text-mute uppercase">Earlier</span>
              )}
            </li>
          ))}
        </ul>
      )}
      {active && (
        <PointsRulesForm
          key={active.version}
          active={active.rules}
          busy={busy}
          onCreate={(r) => void create(r)}
        />
      )}
    </div>
  );
}
