# little-spaceship

A vertical shoot 'em up built from scratch in Java: pixel-art, level-based, single-player and local. It is a portfolio piece, so architecture, tests, CI, performance, documentation, art and deployment all count as part of the deliverable — not just a game that runs.

Built on libGDX, shipped to the browser through TeaVM, with a desktop target sharing the same core. It is not a remake, and no code or assets from earlier projects are reused.

`docs/STATUS.md` says where the project stands; `docs/plan/` holds the master plan, one folder per phase. Planning lives in `docs/planning/`. Before inventing a game rule, look there: most of it is already decided, and `08-decisions-and-open-items.md` separates what is settled from what is still open.

## Invariants

Decided and measured. These are not preferences — breaking one invalidates earlier work.

1. **`core` does not depend on libGDX**, not even on its math utilities. Needing to import `com.badlogic.gdx` inside `core` means the design is wrong.
2. **Determinism.** The core never reads the clock, never reads input directly and never calls `Math.random()`. It receives a fixed step (1/60), an immutable `InputFrame` and a seeded `Rng`. Replays depend on this and break silently when it is violated.
3. **Single-threaded.** The web target offers no real parallelism, and `ExecutorService`, `CompletableFuture` and `ReentrantLock` do not exist in TeaVM — they break the build. It is also unnecessary: logic costs fractions of a millisecond against ~10 ms of drawing.
4. **Contracts at the boundaries.** No module exposes concrete classes to another. Whatever crosses is immutable or read-only. `game` never manipulates the ECS; it reads through `WorldView`.
5. **Fixed system order.** Execution order is part of the game rules, not an implementation detail.
6. **No abstraction without a real case you can point at.** A case is a written design or a shipped need, not an expectation. It read "in the MVP" until 27/08/2026, when the project owner accepted phase 10c's rewording ([#91](https://github.com/LuchoC-Dev/little-spaceship/issues/91)): the MVP shipped, the sentence lost its subject, and the standard it set did not change.

## Web target pitfalls

Each of these cost hours during the spike.

- **`assets/startup-logo.png` is mandatory.** Without it the app crashes when preloading finishes, with an error that never mentions the logo.
- **The canvas needs an explicit size.** With `config.width = 0` it inherits a 0×0 container and the preloader ends up without a stage.
- **Headless Chrome cannot validate the web runtime.** It fails under SwiftShader even when a real browser works, so CI can only verify that the build compiles.
- **Read JSON with `JsonReader`/`JsonValue`**, never with the `Json` serialisation class: it relies on reflection, which TeaVM would require declaring class by class.
- Every new dependency must be checked for TeaVM compatibility before being added.

## Conventions

- Java 17, root package `dev.luchoc.littlespaceship`, Gradle wrapper, JUnit 5.
- **Everything written in the repository is in English**: code, comments, logs, JSON keys, content ids, agent definitions and documentation. The one exception is `docs/sources/`, a verbatim transcript kept in Spanish because translating evidence would falsify it.
- Conversation with the user is always in Spanish.
- Composition over inheritance. Components are plain data with no logic.
- **Comments carry the why, not the what.** The code already says what it does. Explain a choice only when it is genuinely counter-intuitive and breaking it would fail silently — the class javadoc, once, briefly. An inline comment is for the line that looks like a mistake and is not. A rule that belongs to the project rather than to one class lives in this file or in `docs/`, not repeated in the code. Everything else is defended by tests whose names state the rule.
- **An agent may launch the game only to confirm it starts, never to play it.** Judging the game by playing it is the project owner's, reserved on purpose; the rule and its reasoning are in `docs/plan/how-to-run-a-phase.md`, "Running the game is not playing it". Decided 01/09/2026.
- **A claim about a system cites an observation of that system.** Saying what something does, does not do, cannot do or has never done means naming the command that was run and what it printed — or the run id, the URL, the file and line. With no observation, write **"not checked"**: that is always an acceptable answer and is never treated as a failure. In phase 09 a worker reported CI as never having run on a runner while four real runs sat in the API, following the instruction "say what you verified" to the letter. See `docs/plan/10b-agents-and-sessions/evidence.md`.
- **Name the file, or say "Not built".** A passage in `docs/` that describes behaviour either names, in backticks, the file that implements it — or says "Not built". It costs a backtick and it is what lets a reader tell a rule that is enforced from one that is only written down. Decided in phase 10a; the argument is in `docs/plan/10a-honest-documentation/mechanism.md`.
- Logical resolution 480×270, playfield 208 px wide, integer scaling, nearest-neighbour.
- Drawing is the cost, not simulation. Optimise batching and atlases first, spatial structures for collision only if it ever becomes necessary, concurrency never.

## Commits

Every commit goes through the `/git-commit` skill — never a bare `git commit`. This applies to one-file and docs-only commits, and it applies to agents as well as to the main session.

Conventional Commits: `type(scope): description`, present tense, imperative mood, under 72 characters. Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`. **The scope is lowercase and takes only `a-z 0-9 . _ -`** — the same characters a branch name takes, and **no spaces**. An agent-memory commit is `docs(memory): <what was learned>`; three agents in phase 11b each invented a different scope with a space in it, and correcting three subjects afterwards cost a history rewrite. The `commit-msg` hook in `tools/hooks/` now refuses a malformed subject as it is written.

**Every pull request against a phase branch closes exactly one issue** — a task from the plan, or a defect found while the phase runs. The coordinator's documentation pull requests are the one exception: they close no issue and carry no status fragment.

**A branch that does work records it** in `docs/plan/<phase>/status/<issue>-<slug>.md`, its own file, written before review. Never in the phase's shared `status.md` — that one is the coordinator's. `tools/pre-pr-check` fails a branch that changes anything outside `docs/` and writes no fragment.

Nothing is ever committed on `main` or on `dev`. Four levels of branch, each receiving a pull request from the one below:

| Branch | Who commits on it | How work leaves it |
|---|---|---|
| `main` | nobody | a pull request from `dev`, **merged by the project owner and by nobody else — an authorisation does not transfer this** |
| `dev` | nobody | a pull request from a phase branch, merged by a coordinator **only with the project owner's direct approval** |
| `phase/<phase>-<description>` | the coordinator, by merging sub-branches | a pull request against `dev` |
| `type/description` | the agent doing one task | a pull request against the phase branch |

A phase branch is merged into `dev` by the coordinator **only after the project owner approves it directly**, per pull request — an approval given once is not a standing one. **`dev` into `main` is the project owner's own merge, always.** If the owner says to do it anyway, stop and confirm rather than acting: it happened once, on 26/08/2026, and the coordinator merged instead of asking. GitHub now requires an approving review on `main`, which turns that mistake from an accident into a deliberate override. Branch from `dev` only to open a phase. Every agent branches from the **phase branch**, never from `dev`, and names its branch `type/description`, lowercase, only `a-z 0-9 . _ -`. **An agent opens a pull request and stops there — it merges nothing**, not its own branch and not anyone else's. The coordinator merges sub-branches into the phase branch. The full regime is in `docs/plan/how-to-run-a-phase.md`.

**Run `tools/pre-pr-check --base <the phase branch>` before opening a pull request**, and paste its output into it. It is a script and costs no tokens. A red check means no pull request.

When several Claude sessions work in parallel — separate sessions, not subagents — each one gets its own git worktree so they cannot touch each other's files.

Before committing: one logical change per commit, diff matches the stated scope, no secrets, no binaries or local artifacts, no `Co-Authored-By` trailers, relevant tests passing.

Never update git config, never force-push, never skip hooks with `--no-verify`, and never use destructive commands unless explicitly asked. If a hook rejects a commit, fix the problem and make a new commit rather than amending.

## Where state lives

Two stores, and the boundary between them matters more than either.

| Where | Holds |
|---|---|
| `docs/STATUS.md`, each phase's `status.md`, GitHub issues and PRs | what happened and where the work stands |
| `.claude/agent-memory/<agent>/` | what that agent learned while working |

**The repository is the state.** Every phase moves through an issue, a branch, a status fragment written before review, and a merged PR, so the state is always versioned and readable by anyone.

**Agent memory is not a second copy of it.** It holds what a repository has no reason to record: a tool limitation that cost an hour, an operation that behaves differently under TeaVM, where a piece of code turned out to live. Never phase progress — that already exists in `status.md`, and when both hold it, one of them silently rots. That has already happened once here.

If something matters to the project rather than only to the agent, it belongs in `status.md`, not in a memory file.

**Agent memory lives in the main checkout, never in a worktree.** `.claude/agent-memory/` is tracked, so an agent standing in a worktree writes its memory into that checkout, on that branch, where the next agent will not find it. Run `tools/agent-memory-path <agent>` — it prints the one correct directory from anywhere — and write there. The `pre-commit` hook in `tools/hooks/` refuses the commit if you forget; install it once per clone with `tools/install-hooks`.

Those commits land on the phase branch, so they appear in **no sub-branch's diff** and no sub-branch's `pre-pr-check` can see them. That is why the `commit-msg` hook exists: for an agent-memory commit it is the only check that ever runs before the phase closes.

## Agents

Defined in `.claude/agents/`. Boundaries come from the module architecture, so two agents cannot collide. An agent that declares `memory: project` keeps persistent memory under `.claude/agent-memory/<agent>/`, and the directory appears the first time it writes there — five of the six have one, `test-engineer` has never written.

| Agent | Owns |
|---|---|
| `core-domain` | `core/` — ECS, systems, game rules |
| `game-presentation` | `game/`, `desktop/`, `web/` — rendering, HUD, audio, input |
| `visual-designer` | visual direction; produces documents, not code |
| `level-designer` | all level content under `assets/data/` — levels, waves, formations, movement shapes, pacing and the intensity curve. Widened from `level-*.json` on 27/08/2026 |
| `test-engineer` | unit tests and deterministic replays |
| `reviewer` | reads and reports only |

An agent never writes outside its module. Agent memory records only what that agent learned and is not already written in `docs/`.
