import { ConflictException, NotFoundException, UnprocessableEntityException } from "@nestjs/common";
import { z } from "zod";

export type ErrorIssue = { path: string; code: string; message: string; [extra: string]: unknown };

/** 404 in the standard error format. */
export function notFound(what: string, code = "NOT_FOUND"): NotFoundException {
  return new NotFoundException({ code, message: `${what} was not found.` });
}

/** 409 in the standard error format. */
export function conflict(code: string, message: string): ConflictException {
  return new ConflictException({ code, message });
}

/** 422 in the standard error format, with field-level issues. */
export function unprocessable(
  code: string,
  message: string,
  issues: ErrorIssue[] = [],
): UnprocessableEntityException {
  return new UnprocessableEntityException({ code, message, issues });
}

/** Parses a request body or query, or throws 422 `VALIDATION_FAILED` with field-level issues. */
export function parseInput<T>(schema: z.ZodType<T>, input: unknown): T {
  const parsed = schema.safeParse(input);
  if (parsed.success) return parsed.data;
  throw unprocessable(
    "VALIDATION_FAILED",
    "The request is invalid.",
    parsed.error.issues.map((issue) => ({
      path: issue.path.join("."),
      code: issue.code.toUpperCase(),
      message: issue.message,
    })),
  );
}

/** True for a Prisma unique-constraint violation (P2002). */
export function isUniqueViolation(error: unknown): boolean {
  return (error as { code?: unknown } | null)?.code === "P2002";
}
