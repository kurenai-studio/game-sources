export type Role = "ADMIN" | "PLAYER";

export type ApiUser = {
  id: string;
  email: string;
  role: Role;
  mustChangePassword: boolean;
};

/** What the API returns from login, refresh, and change-password. */
export type ApiTokens = {
  accessToken: string;
  refreshToken: string;
  /** Access token lifetime in seconds. */
  expiresIn: number;
  user: ApiUser;
};

/** What the web app's session routes return to the browser. The refresh token is never included. */
export type SessionPayload = {
  accessToken: string;
  expiresIn: number;
  user: ApiUser;
};

/** The API error body. */
export type ApiErrorBody = {
  statusCode: number;
  code: string;
  message: string;
  issues?: unknown;
};
