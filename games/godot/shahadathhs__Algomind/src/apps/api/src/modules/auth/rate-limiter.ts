import { HttpException, HttpStatus, Injectable } from "@nestjs/common";

export type RateLimitResult = { allowed: boolean; retryAfterSeconds: number };

type Bucket = { count: number; resetAt: number };

/**
 * Fixed-window counters held in process memory. They are per instance and reset on restart, so
 * this is correct for a single instance only (docs/DEPLOY.md). Move to a shared store before
 * running more than one.
 */
@Injectable()
export class RateLimiter {
  private readonly buckets = new Map<string, Bucket>();

  /** Replaced in tests to move time without waiting. */
  clock: () => number = Date.now;

  /** Counts one attempt against `key`; `allowed` is false once `limit` is exceeded in the window. */
  hit(key: string, limit: number, windowMs: number): RateLimitResult {
    const now = this.clock();
    if (this.buckets.size > 5_000) this.prune(now);
    let bucket = this.buckets.get(key);
    if (!bucket || bucket.resetAt <= now) {
      bucket = { count: 0, resetAt: now + windowMs };
      this.buckets.set(key, bucket);
    }
    bucket.count += 1;
    return {
      allowed: bucket.count <= limit,
      retryAfterSeconds: Math.max(1, Math.ceil((bucket.resetAt - now) / 1000)),
    };
  }

  reset(key: string): void {
    this.buckets.delete(key);
  }

  private prune(now: number): void {
    for (const [key, bucket] of this.buckets) {
      if (bucket.resetAt <= now) this.buckets.delete(key);
    }
  }
}

/** 429 with a Retry-After hint (the error filter turns `retryAfter` into the header). */
export function tooManyRequests(retryAfterSeconds: number): HttpException {
  return new HttpException(
    {
      code: "TOO_MANY_REQUESTS",
      message: "Too many attempts. Try again later.",
      retryAfter: retryAfterSeconds,
    },
    HttpStatus.TOO_MANY_REQUESTS,
  );
}
