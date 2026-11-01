import type { ApiClient } from "@/lib/api/client";

/** Shapes of the admin API (see docs/README_ARCHITECTURE.md, section 7.1). */

export type LevelStatus = "DRAFT" | "PUBLISHED" | "ARCHIVED";
export type Difficulty = "easy" | "medium" | "hard";
export type PlaytestState = "NONE" | "STALE" | "FAILED" | "SOLVED";
export type VersionState = "DRAFT" | "PUBLISHED" | "SUPERSEDED";

export type Par = { commands: number; steps: number };

export type CheckIssue = { gate: string; path: string; code: string; message: string };

export type ValidationSummary = {
  ok: boolean;
  errors: CheckIssue[];
  warnings: CheckIssue[];
  par: Par | null;
  referenceSolved: boolean;
  requiredMechanics: string[];
  contentHash: string;
};

export type Placement = {
  chapterId: string | null;
  chapterTitle: string | null;
  worldId: string | null;
  worldTitle: string | null;
  orderInChapter: number;
};

export type LevelSummary = {
  id: string;
  slug: string;
  title: string;
  difficulty: Difficulty;
  status: LevelStatus;
  placement: Placement;
  publishedVersion: number | null;
  draftVersion: number | null;
  draftAhead: boolean;
  par: Par | null;
  playtestState: PlaytestState | null;
  createdAt: string;
  updatedAt: string;
};

/** A move, a turn, INC or MARK. */
export type Primitive = { op: string };
/** An IF: a sensor, a `then` branch of primitives and an `else` branch: primitives, or one IF (else-if). */
export type IfNode = { op: "IF"; when: string; then: Primitive[]; else: (Primitive | IfNode)[] };
/** An item of a loop body: a primitive, an IF, a CALL or an inner loop. */
export type BodyNode = Primitive | IfNode | Instruction;
/** One program node (primitive, IF, loop, PROC or CALL); fields are optional so one type covers all. */
export type Instruction = {
  op: string;
  /** Rounds of a REPEAT: 2 to 11, or "N" for the counter. */
  count?: number | "N";
  until?: string;
  body?: Instruction[];
  name?: string;
  when?: string;
  then?: Primitive[];
  else?: (Primitive | Instruction)[];
};

/** A target to reach, or (visit_all) every floor cell to enter; a sweep goal has no position. */
export type Goal = { type: string; position?: [number, number] };

export type LevelContent = {
  schemaVersion: number;
  levelId: string;
  levelVersion: number;
  slug: string;
  title: string;
  description: string;
  difficulty: Difficulty;
  requires: { mechanics: string[] };
  board: { width: number; height: number; walls: [number, number][] };
  initialState: { position: [number, number]; direction: "north" | "east" | "south" | "west" };
  availableCommands: string[];
  constraints: { maxCommands: number; maxSteps: number };
  goal: Goal;
  hints: string[];
  /** Test boards the same program must also solve (1 to 5). */
  extraBoards?: Pick<LevelContent, "board" | "initialState" | "goal">[];
  /** The program the tape starts with, for a level about fixing a program (a debug level). */
  startProgram?: Instruction[];
} & LevelTiles;

type Cell = [number, number];

/** The tiles of the later worlds, on the level's own board only. */
export type LevelTiles = {
  /** Guards that walk a fixed route. */
  patrols?: { pattern: "back_and_forth" | "loop"; cells: Cell[] }[];
  /** Keys and the doors they open. */
  locks?: { key: Cell; door: Cell }[];
  /** Crates and the docks they belong on. */
  deliveries?: { item: Cell; dock: Cell }[];
  /** Switches and the gates they flip; `open` is a gate that starts open. */
  switches?: { switch: Cell; gate: Cell; open?: boolean }[];
  /** Teleporter pairs. */
  teleports?: { a: Cell; b: Cell }[];
  /** Ice cells. */
  ice?: Cell[];
  /** Belts and the way each carries. */
  belts?: { cell: Cell; direction: "north" | "east" | "south" | "west" }[];
};

export type VersionView = {
  id: string;
  versionNumber: number;
  schemaVersion: number;
  state: VersionState;
  par: Par | null;
  contentHash: string;
  validationSummary: ValidationSummary | null;
  createdBy: string | null;
  createdAt: string;
  updatedAt: string;
  publishedAt: string | null;
  content: LevelContent;
  referenceSolution: Instruction[];
};

export type LevelView = LevelSummary & {
  currentPublishedVersionId: string | null;
  draft: VersionView | null;
  published: VersionView | null;
  playtests: { count: number; solvedForCurrentContent: boolean };
};

export type Page<T> = { items: T[]; total: number; page: number; pageSize: number };

export type ValidateResult = ValidationSummary & {
  publish: { ready: boolean; failedGates: CheckIssue[] };
  playtests: { count: number; solvedForCurrentContent: boolean };
  compatibility: { minimumVersion: string | null; unsupportedMechanics: string[] };
};

export type Playtest = {
  id: string;
  levelVersionId: string;
  versionNumber: number;
  contentHash: string;
  current: boolean;
  testerName: string;
  solved: boolean;
  commandsUsed: number | null;
  perceivedDifficulty: Difficulty | null;
  notes: string;
  createdAt: string;
};

export type PlaytestInput = {
  testerName: string;
  solved: boolean;
  commandsUsed?: number;
  perceivedDifficulty?: Difficulty;
  notes?: string;
};

export type World = {
  id: string;
  title: string;
  description: string;
  order: number;
  chapterCount: number;
};
export type Chapter = {
  id: string;
  worldId: string;
  title: string;
  order: number;
  levelCount: number;
};

export type AdminCampaign = {
  worlds: (Omit<World, "chapterCount"> & {
    chapters: (Omit<Chapter, "levelCount"> & { levels: LevelSummary[] })[];
  })[];
  unassigned: LevelSummary[];
};

export type VersionSummary = Omit<VersionView, "content" | "referenceSolution">;

export type ExportEnvelope = {
  format: "algomind-level";
  schemaVersion: number;
  exportedAt: string;
  meta: { title: string; slug: string };
  level: unknown;
  referenceSolution: unknown[];
};

export type ClientVersion = {
  id: string;
  version: string;
  supportedMechanics: string[];
  isMinimum: boolean;
  releasedAt: string;
  createdAt: string;
  updatedAt: string;
};

export type AuditEvent = {
  id: string;
  action: string;
  entityType: string;
  entityId: string;
  detail: Record<string, unknown> | null;
  userId: string | null;
  userEmail: string | null;
  createdAt: string;
};

export type PointsRules = {
  version: number;
  base: { easy: number; medium: number; hard: number };
  parFull: number;
  parNear: number;
  nearSlots: number;
  stepsBonus: number;
  firstClear: number;
};
export type PointsRulesInput = Omit<PointsRules, "version">;
export type RuleSet = { version: number; rules: PointsRules; active: boolean; createdAt: string };

export type PlayerStatus = "ACTIVE" | "SUSPENDED";
export type PlayerSummary = {
  id: string;
  email: string;
  displayName: string | null;
  status: PlayerStatus;
  createdAt: string;
  lastActiveAt: string | null;
  /** On a leaderboard by their own choice, and whether an admin hid them. */
  leaderboardOptIn: boolean;
  leaderboardHidden: boolean;
  levelsCleared: number;
  points: number;
};
export type PlayerQuery = {
  q?: string;
  status?: PlayerStatus;
  sort?: "lastActive" | "points" | "cleared" | "created" | "email";
  order?: "asc" | "desc";
  page?: number;
  pageSize?: number;
};
export type PlayerDetail = {
  account: Omit<PlayerSummary, "levelsCleared" | "points"> & {
    publicId: string;
    leaderboardOptIn: boolean;
    hideName: boolean;
    leaderboardHidden: boolean;
  };
  progress: {
    levelSlug: string;
    levelVersion: number;
    bestCommands: number;
    completedAt: string;
  }[];
  points: {
    total: number;
    history: {
      createdAt: string;
      reason: string;
      delta: number;
      levelSlug: string | null;
      ruleVersion: number;
    }[];
  };
  sessions: { familyId: string; startedAt: string; lastUsedAt: string; expiresAt: string }[];
  settings: { settings: unknown; updatedAt: string } | null;
  lastSyncAt: string | null;
};

export type LevelQuery = {
  q?: string;
  status?: LevelStatus;
  worldId?: string;
  unassigned?: boolean;
  sort?: "updatedAt" | "createdAt" | "title" | "slug";
  order?: "asc" | "desc";
  page?: number;
  pageSize?: number;
};

function qs(params: Record<string, string | number | boolean | undefined>): string {
  const sp = new URLSearchParams();
  for (const [k, v] of Object.entries(params)) {
    if (v !== undefined && v !== "") sp.set(k, String(v));
  }
  const s = sp.toString();
  return s ? `?${s}` : "";
}

/** Typed calls for the levels and campaign screens. */
export function adminApi(client: ApiClient) {
  return {
    listLevels: (query: LevelQuery = {}) =>
      client.get<Page<LevelSummary>>(`admin/levels${qs({ ...query })}`),
    getLevel: (id: string) => client.get<LevelView>(`admin/levels/${id}`),
    createLevel: (body: { slug: string; title: string; difficulty?: Difficulty }) =>
      client.post<LevelView>("admin/levels", body),
    saveDraft: (
      id: string,
      body: { expectedUpdatedAt: string; content?: unknown; referenceSolution?: Instruction[] },
    ) => client.patch<LevelView>(`admin/levels/${id}`, body),
    deleteLevel: (id: string) => client.delete<void>(`admin/levels/${id}`),
    startDraft: (id: string) => client.post<LevelView>(`admin/levels/${id}/draft`),
    discardDraft: (id: string) => client.delete<LevelView>(`admin/levels/${id}/draft`),
    duplicateLevel: (id: string, body: { slug?: string; title?: string } = {}) =>
      client.post<LevelView>(`admin/levels/${id}/duplicate`, body),
    validateLevel: (id: string) => client.post<ValidateResult>(`admin/levels/${id}/validate`),
    publishLevel: (id: string) =>
      client.post<{ level: LevelView; publishedVersionId: string }>(`admin/levels/${id}/publish`),
    unpublishLevel: (id: string, archive = false) =>
      client.post<LevelView>(`admin/levels/${id}/unpublish`, { archive }),
    listPlaytests: (id: string) =>
      client.get<{ items: Playtest[] }>(`admin/levels/${id}/playtests`),
    addPlaytest: (id: string, body: PlaytestInput) =>
      client.post<Playtest>(`admin/levels/${id}/playtests`, body),

    listVersions: (id: string) =>
      client.get<{ items: VersionSummary[] }>(`admin/levels/${id}/versions`),
    restoreVersion: (id: string, versionId: string) =>
      client.post<LevelView>(`admin/levels/${id}/restore/${versionId}`),
    exportLevel: (id: string, versionId?: string) =>
      client.get<ExportEnvelope>(`admin/levels/${id}/export${qs({ version: versionId })}`),
    importLevel: (envelope: unknown, slug?: string) =>
      client.post<LevelView>(`admin/levels/import${qs({ slug })}`, envelope),

    listClientVersions: () => client.get<{ items: ClientVersion[] }>("admin/client-versions"),
    createClientVersion: (body: {
      version: string;
      supportedMechanics: string[];
      isMinimum?: boolean;
    }) => client.post<ClientVersion>("admin/client-versions", body),
    setMinimumClientVersion: (id: string) =>
      client.patch<ClientVersion>(`admin/client-versions/${id}`, { isMinimum: true }),
    listAudit: (query: { action?: string; page?: number; pageSize?: number } = {}) =>
      client.get<Page<AuditEvent>>(`admin/audit${qs({ ...query })}`),

    listPointsRules: () => client.get<{ items: RuleSet[] }>("admin/points-rules"),
    createPointsRules: (body: PointsRulesInput) => client.post<RuleSet>("admin/points-rules", body),

    listPlayers: (query: PlayerQuery = {}) =>
      client.get<Page<PlayerSummary>>(`admin/players${qs({ ...query })}`),
    getPlayer: (id: string) => client.get<PlayerDetail>(`admin/players/${id}`),
    exportPlayer: (id: string) => client.get<unknown>(`admin/players/${id}/export`),
    revokePlayerSessions: (id: string) =>
      client.post<{ revoked: number }>(`admin/players/${id}/revoke-sessions`),
    resetPlayerProgress: (id: string) =>
      client.post<{ levels: number; points: number }>(`admin/players/${id}/reset-progress`),
    setPlayerName: (id: string, displayName: string | null) =>
      client.patch<{ displayName: string | null }>(`admin/players/${id}/display-name`, {
        displayName,
      }),
    suspendPlayer: (id: string) => client.post<void>(`admin/players/${id}/suspend`),
    unsuspendPlayer: (id: string) => client.post<void>(`admin/players/${id}/unsuspend`),
    deletePlayer: (id: string, confirmEmail: string) =>
      client.delete<void>(`admin/players/${id}`, { confirmEmail }),

    getCampaign: () => client.get<AdminCampaign>("admin/campaign"),
    createWorld: (body: { title: string; description?: string }) =>
      client.post<World>("admin/worlds", body),
    updateWorld: (id: string, body: { title?: string; description?: string }) =>
      client.patch<World>(`admin/worlds/${id}`, body),
    deleteWorld: (id: string) => client.delete<void>(`admin/worlds/${id}`),
    createChapter: (body: { worldId: string; title: string }) =>
      client.post<Chapter>("admin/chapters", body),
    updateChapter: (id: string, body: { title: string }) =>
      client.patch<Chapter>(`admin/chapters/${id}`, body),
    deleteChapter: (id: string) => client.delete<void>(`admin/chapters/${id}`),
    saveOrder: (body: { worlds: { id: string; chapters: { id: string; levels: string[] }[] }[] }) =>
      client.put<unknown>("admin/campaign/order", body),
  };
}

export type AdminApi = ReturnType<typeof adminApi>;
