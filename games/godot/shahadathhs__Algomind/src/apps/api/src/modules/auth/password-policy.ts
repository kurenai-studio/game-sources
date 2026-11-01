export const MIN_PASSWORD_LENGTH = 12;
/** Upper bound so a huge body cannot make the hash function burn CPU. */
export const MAX_PASSWORD_LENGTH = 128;

/** The first reason a password is not acceptable, or undefined when it is. */
export function passwordProblem(password: string): string | undefined {
  if (password.length < MIN_PASSWORD_LENGTH) {
    return `must be at least ${MIN_PASSWORD_LENGTH} characters`;
  }
  if (password.length > MAX_PASSWORD_LENGTH) {
    return `must be at most ${MAX_PASSWORD_LENGTH} characters`;
  }
  const lower = password.toLowerCase();
  if (new Set(lower).size < 5) return "is too repetitive";
  return undefined;
}
