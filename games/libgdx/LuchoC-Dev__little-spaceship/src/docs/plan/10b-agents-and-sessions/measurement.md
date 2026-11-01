# What phase 09 actually cost

Task 1 of [`plan.md`](plan.md), measured on 26/08/2026. The regime in
[`docs/planning/13-working-with-agents.md`](../../planning/13-working-with-agents.md) was written
after an audit and then followed for one phase without ever being checked against it. This is that
check: numbers, not impressions.

## Where the numbers come from

Every model call this project has made is recorded in
`C:/Users/lucho/.claude/projects/C--Users-lucho-desktop-programacion-fast-weekend-core-navecita-v5/`,
one JSONL file per session, with the subagents of a session under
`<session-id>/subagents/` next to a `.meta.json` naming the agent type and the model it was launched
with. Every figure below is a sum over the `usage` block of the assistant messages in those files.

Phase 09 is session `322e8734`, from its first message at **25/08 20:18 UTC** to the last call before
the phase was closed at **22:27 UTC**, plus the eight subagents it launched. It is a clean window: the
session that preceded it (`f7c2b5f0`) ended at 20:05 with the phases 06–08 polish, and phase 09's
issues — #32, #34, #36, #38 — were all opened and closed inside it.

**Cost is an equivalent, not a bill.** The work ran on a subscription. Everything here is priced at
public API list rates, the same instrument the earlier audit used, so the two are comparable:
Opus at 15 / 75 / 18.75 / 1.50 USD per million tokens (input / output / cache write / cache read),
Sonnet at 3 / 15 / 3.75 / 0.30.

## The phase in one table

| | Calls | Cache-read tokens | Output tokens | Equivalent cost |
|---|---:|---:|---:|---:|
| Coordinator (Opus, 2 h 09) | 309 | 44,597,904 | 230,977 | **$92.38** |
| 4 workers (`game-presentation`, Sonnet) | 288 | 15,544,411 | 61,321 | **$9.00** |
| 4 reviews (`reviewer`, Sonnet) | 216 | 12,203,218 | 50,028 | **$9.37** |
| **Phase 09 total** | **813** | **72,345,533** | **342,326** | **$110.76** |

Per agent, in the order they were launched:

| Agent | Task | Calls | $ | $/call |
|---|---|---:|---:|---:|
| `game-presentation` | web launcher, #32 | 103 | 3.49 | 0.034 |
| `reviewer` | PR #33 | 77 | 3.44 | 0.045 |
| `game-presentation` | CI, #34 | 45 | 1.36 | 0.030 |
| `reviewer` | PR #35 | 53 | 2.40 | 0.045 |
| `game-presentation` | README, #36 | 58 | 1.81 | 0.031 |
| `reviewer` | PR #37 | 46 | 1.83 | 0.040 |
| `game-presentation` | Pages deploy, #38 | 82 | 2.34 | 0.029 |
| `reviewer` | PR #39 | 40 | 1.70 | 0.042 |

**The coordinator is 38 % of the calls and 83 % of the cost.** That is the single most important
number in this document, and it is not because it did more: it is because it ran on Opus while
everything else ran on Sonnet. The same eight subagents, priced at Opus rates, would have cost
$91.90 instead of $18.38 — a factor of five, for identical traffic.

## Against what the regime predicted

| The regime says | Phase 09 | Verdict |
|---|---|---|
| **One coordinator per phase**, closed with the state in Git | one session, 309 calls, 2 h 09 for the phase | **Held** for the phase. The session was then reused the next day for 66 more calls — see below |
| **Sonnet coordinates; Opus decides** | 309 of 309 coordinator calls on Opus | **Not followed.** It is where 83 % of the cost went |
| **`reviewer` defaults to Sonnet**, escalation needs a written reason | 4 of 4 on Sonnet, and `model: "sonnet"` is recorded in each `.meta.json`, so it was passed deliberately | **Held.** This is the rule the previous audit found most abused, and it was the one most cleanly obeyed |
| **A worker is one issue; past 60–80 calls, split it** | 45, 58, 82, 103 | **Half held.** Two workers went past 80 |
| **Any spend-limit message stops the flow** | zero limits hit | **Held.** Fourteen in the audited period, none here |
| **Keep image inspection short and separate** | no screenshots taken in the phase | Not exercised |
| **Two thirds of cost is re-reading history** | $75.20 of $110.76 is cache-read | **Unchanged: 68 %** |

The last row is the one worth sitting with. The regime cut the *total* — nine phases had produced
~3,300 calls and 665 M cached tokens, phase 09 produced 813 calls and 72 M — but it did not change
the *shape*. Re-reading conversation history is still two thirds of what a phase costs, because that
is what a coordinator is: a context that grows.

## The coordinator's cost per call, inside one session

Averaged over blocks of 75 calls, all on 25/08:

| Calls | Window | Avg cache-read | Avg $/call |
|---|---|---:|---:|
| 1–75 | 20:18–20:44 | 72,004 | 0.210 |
| 76–150 | 20:44–21:00 | 124,459 | 0.252 |
| 151–225 | 21:02–21:34 | 164,320 | 0.312 |
| 226–300 | 21:34–22:26 | 205,965 | 0.398 |
| 301–309 | 22:26–22:27 | 232,416 | 0.489 |

**A call at the end of the phase cost 2.3× a call at the start of the same phase**, two hours apart.
The next day the same session was reopened for the post-MVP planning: 66 calls at **$0.726 each**,
3.5× its own opening rate, and $47.89 for one hour of work that produced documents.

The regime's claim that "a late call in a days-old session cost four times what an identical early
one did" reproduces at a much smaller scale than it was written for. It is not a property of days-old
sessions; it is visible inside a single evening, and it is the argument for closing a coordinator at
the end of a phase rather than at the end of a day.

## Agents, reviews and correction rounds

- **8 agents for 4 issues**: one worker and one review each. No task was split across two workers,
  and no worker was given two issues.
- **4 reviews, 2 rejections.** PR #35 (CI) and PR #37 (README) were rejected; PR #33 and PR #39 were
  accepted. Both rejections were for a **false claim in a document**, not for defective code.
- **Both rejections were fixed by the coordinator**, not sent back. That is task 6's subject and it is
  measured rather than assumed here.
- **One worker was resumed after its review.** The web-launcher worker spans 20:20–21:23 while its
  reviewer ran 20:30–20:36 inside that window: the agent was still open and received follow-up work.
  It is also the worker that reached 103 calls. The two facts are the same fact, and they are exactly
  the mechanism the regime blames for phase 05's 312-call agent.
- **4 `SendMessage` follow-ups to live agents**, three of them to reviewers about where to write
  memory — including one that corrected the previous message a minute later ("do not create the
  branch in the main working copy"). That is the memory-path trap costing coordinator turns in real
  time, and it is task 3's evidence.

**The reviews cost $9.37 and caught two false statements**, one of which — CI reported as never
having run while four runs sat in the API — is the failure task 4 exists to prevent. At 8 % of the
phase's cost, the review pass is the cheapest thing in this table and the only one that found
anything.

## What this measurement changes

1. **Sonnet coordinates** is now backed by a number rather than a principle: it was the difference
   between $92 and roughly $18 for the same 309 calls. It is also the rule this project has broken in
   every phase measured so far, which suggests writing it down again is not the fix.
2. **The 60–80 call ceiling is the wrong instrument.** Two workers passed it and neither produced bad
   work; what actually correlates with the expensive agent is *being resumed after a review*, not the
   call count. The ceiling should be stated as "a worker is closed when its pull request is opened".
3. **The review pass earns its cost.** Two rejections out of four reviews, both catching a
   documentation lie the coordinator had already half-noticed and let through.
4. **Nothing here justifies fewer agents.** The delegated half of the phase was 16 % of the cost.
