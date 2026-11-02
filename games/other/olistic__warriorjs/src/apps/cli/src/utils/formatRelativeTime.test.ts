import { afterEach, beforeEach, describe, expect, test, vi } from 'vitest';

import { formatRelativeTime } from './formatRelativeTime.js';

describe('formatRelativeTime', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-03-20T12:00:00.000Z'));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  test('returns "just now" for less than 60 seconds ago', () => {
    expect(formatRelativeTime('2026-03-20T11:59:30.000Z')).toBe('just now');
  });

  test('returns minutes ago', () => {
    expect(formatRelativeTime('2026-03-20T11:55:00.000Z')).toBe('5 minutes ago');
  });

  test('returns "1 minute ago" for singular', () => {
    expect(formatRelativeTime('2026-03-20T11:59:00.000Z')).toBe('1 minute ago');
  });

  test('returns hours ago', () => {
    expect(formatRelativeTime('2026-03-20T09:00:00.000Z')).toBe('3 hours ago');
  });

  test('returns "1 hour ago" for singular', () => {
    expect(formatRelativeTime('2026-03-20T11:00:00.000Z')).toBe('1 hour ago');
  });

  test('returns days ago', () => {
    expect(formatRelativeTime('2026-03-17T12:00:00.000Z')).toBe('3 days ago');
  });

  test('returns "1 day ago" for singular', () => {
    expect(formatRelativeTime('2026-03-19T12:00:00.000Z')).toBe('1 day ago');
  });

  test('returns weeks ago', () => {
    expect(formatRelativeTime('2026-03-06T12:00:00.000Z')).toBe('2 weeks ago');
  });

  test('returns "1 week ago" for singular', () => {
    expect(formatRelativeTime('2026-03-13T12:00:00.000Z')).toBe('1 week ago');
  });

  test('returns months ago', () => {
    expect(formatRelativeTime('2026-01-19T12:00:00.000Z')).toBe('2 months ago');
  });

  test('returns "1 month ago" for singular', () => {
    expect(formatRelativeTime('2026-02-17T12:00:00.000Z')).toBe('1 month ago');
  });

  test('returns years ago', () => {
    expect(formatRelativeTime('2024-03-20T12:00:00.000Z')).toBe('2 years ago');
  });

  test('returns "1 year ago" for singular', () => {
    expect(formatRelativeTime('2025-03-20T12:00:00.000Z')).toBe('1 year ago');
  });
});
