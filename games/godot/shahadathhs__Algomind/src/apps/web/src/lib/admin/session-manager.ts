import { NetworkError, readApiError, SessionEndedError } from "@/lib/api/errors";
import type { ApiUser, SessionPayload } from "@/lib/api/types";

/**
 * The browser side of the admin session. Framework free so it can be tested with fakes.
 *
 * - The access token lives only in this object's memory. The refresh token is an httpOnly cookie
 *   this code cannot read; the web app's session routes use it.
 * - Refresh is single-flight (one request per tab, and a Web Lock across tabs) and scheduled
 *   before the access token expires.
 * - A 401 on an API call triggers one refresh and one retry, then sign-out.
 * - Inactivity is tracked across tabs over a BroadcastChannel that carries timestamps and sign-out
 *   notices, never tokens.
 */

export type EndReason = "signed-out" | "inactive" | "expired" | "elsewhere";

export type SessionState =
  | { status: "loading"; offline?: boolean }
  | { status: "authenticated"; user: ApiUser }
  | { status: "anonymous"; reason?: EndReason };

export type RefreshResult = "ok" | "rejected" | "transient";

export interface ChannelLike {
  postMessage(message: unknown): void;
  onmessage: ((event: { data: unknown }) => void) | null;
  close(): void;
}

export interface LocksLike {
  request<T>(name: string, callback: () => Promise<T>): Promise<T>;
}

export type SessionDeps = {
  fetch: typeof fetch;
  now: () => number;
  setTimer: (fn: () => void, ms: number) => unknown;
  clearTimer: (handle: unknown) => void;
  openChannel?: () => ChannelLike | null;
  locks?: LocksLike | null;
  inactivityMs: number;
  /** Refresh this long before the access token expires (default 60 s). */
  refreshLeadMs?: number;
  /** Wait before retrying a refresh that failed on network or 5xx (default 5 s). */
  retryMs?: number;
};

type ChannelMessage = { type: "activity"; at: number } | { type: "logout"; reason: EndReason };

const SESSION_BASE = "/admin/api/session";
const PROXY_BASE = "/admin/api/proxy";
const LOCK_NAME = "algomind-admin-refresh";
/** The longest wait between refresh retries while the API is unreachable. */
const MAX_RETRY_MS = 5 * 60_000;
const ACTIVITY_BROADCAST_MS = 5_000;

export class SessionManager {
  private state: SessionState = { status: "loading" };
  private listeners = new Set<() => void>();
  private accessToken: string | null = null;
  private expiresAt = 0;
  private lastActivity: number;
  private lastBroadcast = 0;
  private refreshTimer: unknown = null;
  private inactivityTimer: unknown = null;
  private channel: ChannelLike | null = null;
  private inflight: Promise<RefreshResult> | null = null;
  private retryAttempts = 0;

  constructor(private readonly deps: SessionDeps) {
    this.lastActivity = deps.now();
  }

  // --- external store -------------------------------------------------------------------

  subscribe = (listener: () => void): (() => void) => {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  };

  getState = (): SessionState => this.state;

  private setState(state: SessionState): void {
    this.state = state;
    for (const listener of this.listeners) listener();
  }

  /** When the session ends for inactivity, as epoch milliseconds. */
  getInactivityDeadline(): number {
    return this.lastActivity + this.deps.inactivityMs;
  }

  getInactivityMs(): number {
    return this.deps.inactivityMs;
  }

  /** When the current access token expires, as epoch milliseconds (0 when signed out). */
  getAccessExpiry(): number {
    return this.expiresAt;
  }

  getAccessToken(): string | null {
    return this.accessToken;
  }

  // --- lifecycle ------------------------------------------------------------------------

  /** Opens the cross-tab channel and restores the session from the refresh cookie. */
  async start(options: { restore?: boolean } = {}): Promise<void> {
    this.channel = this.deps.openChannel?.() ?? null;
    if (this.channel) this.channel.onmessage = (event) => this.onMessage(event.data);
    if (options.restore === false) {
      this.setState({ status: "anonymous" });
      return;
    }
    await this.refresh();
  }

  stop(): void {
    this.clearTimers();
    if (this.channel) {
      this.channel.onmessage = null;
      this.channel.close();
      this.channel = null;
    }
  }

  private clearTimers(): void {
    if (this.refreshTimer !== null) this.deps.clearTimer(this.refreshTimer);
    if (this.inactivityTimer !== null) this.deps.clearTimer(this.inactivityTimer);
    this.refreshTimer = null;
    this.inactivityTimer = null;
  }

  // --- sign in and out ------------------------------------------------------------------

  async login(email: string, password: string): Promise<void> {
    const res = await this.send(`${SESSION_BASE}/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password }),
    });
    if (!res.ok) throw await readApiError(res);
    this.applySession((await res.json()) as SessionPayload);
  }

  async changePassword(currentPassword: string, newPassword: string): Promise<void> {
    const res = await this.authorized(`${SESSION_BASE}/change-password`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ currentPassword, newPassword }),
    });
    if (!res.ok) throw await readApiError(res);
    this.applySession((await res.json()) as SessionPayload);
  }

  /** Signs out here and in every other tab, and revokes the refresh token. */
  async logout(reason: EndReason = "signed-out"): Promise<void> {
    this.endSession(reason, { broadcast: true });
    try {
      await this.deps.fetch(`${SESSION_BASE}/logout`, {
        method: "POST",
        credentials: "same-origin",
        keepalive: true,
      });
    } catch {
      // The cookie expires on its own; the local state is already cleared.
    }
  }

  private endSession(reason: EndReason, options: { broadcast: boolean }): void {
    this.clearTimers();
    this.accessToken = null;
    this.expiresAt = 0;
    this.setState({ status: "anonymous", reason });
    if (options.broadcast) this.post({ type: "logout", reason });
  }

  // --- refresh --------------------------------------------------------------------------

  /**
   * Single-flight: concurrent callers share one request. `quiet` is for a speculative look at
   * the cookie: a rejection just means there is no session, not that one ended.
   */
  refresh(options: { quiet?: boolean } = {}): Promise<RefreshResult> {
    if (!this.inflight) {
      this.inflight = this.doRefresh(options.quiet === true).finally(() => {
        this.inflight = null;
      });
    }
    return this.inflight;
  }

  private async doRefresh(quiet: boolean): Promise<RefreshResult> {
    const run = async (): Promise<RefreshResult> => {
      let res: Response;
      try {
        res = await this.deps.fetch(`${SESSION_BASE}/refresh`, {
          method: "POST",
          credentials: "same-origin",
        });
      } catch {
        return "transient";
      }
      if (res.status === 401 || res.status === 403) return "rejected";
      if (!res.ok) return "transient";
      try {
        this.applySession((await res.json()) as SessionPayload);
      } catch {
        return "transient";
      }
      return "ok";
    };
    // The lock makes tabs take turns, so each one presents the cookie the previous tab rotated.
    const result = this.deps.locks ? await this.deps.locks.request(LOCK_NAME, run) : await run();
    if (result === "rejected" && quiet) {
      this.setState({ status: "anonymous" });
    } else if (result === "rejected") {
      this.endSession("expired", { broadcast: true });
    } else if (result === "transient") {
      // Back off while the API is down, so open tabs do not hammer it every few seconds.
      const base = this.deps.retryMs ?? 5_000;
      this.scheduleRefresh(Math.min(base * 2 ** this.retryAttempts, MAX_RETRY_MS));
      this.retryAttempts += 1;
      if (this.state.status === "loading") this.setState({ status: "loading", offline: true });
    }
    return result;
  }

  /** After arriving from the sign-in page: look for a valid cookie once, without announcing an ended session. */
  async restoreQuietly(): Promise<void> {
    if (this.state.status !== "anonymous" || this.inflight) return;
    await this.refresh({ quiet: true });
  }

  private applySession(payload: SessionPayload): void {
    this.retryAttempts = 0;
    this.accessToken = payload.accessToken;
    this.expiresAt = this.deps.now() + payload.expiresIn * 1000;
    const lead = Math.min(this.deps.refreshLeadMs ?? 60_000, (payload.expiresIn * 1000) / 2);
    this.scheduleRefresh(Math.max(payload.expiresIn * 1000 - lead, 0));
    if (this.state.status !== "authenticated") this.lastActivity = this.deps.now();
    this.scheduleInactivity();
    this.setState({ status: "authenticated", user: payload.user });
  }

  private scheduleRefresh(delayMs: number): void {
    if (this.refreshTimer !== null) this.deps.clearTimer(this.refreshTimer);
    this.refreshTimer = this.deps.setTimer(() => {
      this.refreshTimer = null;
      void this.refresh();
    }, delayMs);
  }

  // --- inactivity -----------------------------------------------------------------------

  /** Call on user input. Resets the inactivity timer here and, throttled, in other tabs. */
  noteActivity(): void {
    if (this.state.status !== "authenticated") return;
    const now = this.deps.now();
    this.lastActivity = now;
    if (now - this.lastBroadcast >= ACTIVITY_BROADCAST_MS) {
      this.lastBroadcast = now;
      this.post({ type: "activity", at: now });
    }
  }

  private scheduleInactivity(): void {
    if (this.inactivityTimer !== null) this.deps.clearTimer(this.inactivityTimer);
    const remaining = this.getInactivityDeadline() - this.deps.now();
    this.inactivityTimer = this.deps.setTimer(
      () => {
        this.inactivityTimer = null;
        this.checkInactivity();
      },
      Math.max(remaining, 0),
    );
  }

  private checkInactivity(): void {
    if (this.state.status !== "authenticated") return;
    if (this.deps.now() >= this.getInactivityDeadline()) {
      void this.logout("inactive");
    } else {
      this.scheduleInactivity();
    }
  }

  /** Call when the tab becomes visible: background timers can run late. */
  checkNow(): void {
    if (this.state.status !== "authenticated") return;
    this.checkInactivity();
    if (this.state.status !== "authenticated") return;
    const lead = this.deps.refreshLeadMs ?? 60_000;
    if (this.deps.now() >= this.expiresAt - lead) void this.refresh();
  }

  // --- cross-tab ------------------------------------------------------------------------

  private post(message: ChannelMessage): void {
    try {
      this.channel?.postMessage(message);
    } catch {
      // A closed channel is not an error for the session.
    }
  }

  private onMessage(data: unknown): void {
    const message = data as Partial<ChannelMessage> | null;
    if (!message || typeof message !== "object") return;
    if (message.type === "activity" && typeof message.at === "number") {
      if (message.at > this.lastActivity) this.lastActivity = message.at;
    } else if (message.type === "logout" && this.state.status === "authenticated") {
      const reason = message.reason === "inactive" ? "inactive" : "elsewhere";
      this.endSession(reason, { broadcast: false });
    }
  }

  // --- authorized requests --------------------------------------------------------------

  /** Calls the API through the proxy route with the bearer token (see lib/api/client.ts). */
  request = (path: string, init: RequestInit = {}): Promise<Response> =>
    this.authorized(`${PROXY_BASE}/${path.replace(/^\/+/, "")}`, init);

  private async send(url: string, init: RequestInit): Promise<Response> {
    try {
      return await this.deps.fetch(url, { credentials: "same-origin", ...init });
    } catch {
      throw new NetworkError();
    }
  }

  private async authorized(url: string, init: RequestInit): Promise<Response> {
    const attempt = (token: string) => {
      const headers = new Headers(init.headers);
      headers.set("Authorization", `Bearer ${token}`);
      return this.send(url, { ...init, headers });
    };

    if (!this.accessToken || this.deps.now() >= this.expiresAt - 5_000) {
      await this.refreshOrThrow();
    }
    const used = this.accessToken;
    if (!used) throw new SessionEndedError();

    let res = await attempt(used);
    if (res.status !== 401) return res;

    // One refresh and one retry. If another call already refreshed, only retry.
    if (this.accessToken === used) await this.refreshOrThrow();
    if (!this.accessToken) throw new SessionEndedError();
    res = await attempt(this.accessToken);
    if (res.status === 401) {
      await this.logout("expired");
      throw new SessionEndedError();
    }
    return res;
  }

  private async refreshOrThrow(): Promise<void> {
    const result = await this.refresh();
    if (result === "rejected") throw new SessionEndedError();
    if (result === "transient") throw new NetworkError();
  }
}
