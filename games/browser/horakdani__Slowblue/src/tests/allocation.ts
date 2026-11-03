import { Session } from 'node:inspector/promises';

/**
 * The allocation probe, in-process.
 *
 * `e2e/measure.spec.ts` runs the same instrument over the real bundle in a real
 * browser, which is the honest measurement and also a build, a preview server and
 * half a minute. This one is the same V8 sampling profiler reached through
 * `node:inspector` instead of CDP, so the simulation half of the per-frame path is
 * guarded by `npm test` on every commit rather than only by the e2e run.
 *
 * What it cannot see is the renderer: there is no canvas here, so a `.map()` added
 * to a draw call is the e2e probe's job and not this one's. What it does see is
 * every allocation in `World.step`, which is where the pooling this criterion is
 * about actually lives.
 */

interface HeapNode {
  callFrame: { functionName: string; url: string; lineNumber: number };
  selfSize: number;
  children: HeapNode[];
}

export interface AllocationResult {
  perFrame: number;
  totalBytes: number;
  /** Deepest sampled frames, largest first - the list to go and fix. */
  sites: [string, number][];
}

function walk(node: HeapNode, out: Map<string, number>): number {
  let total = 0;
  if (node.selfSize > 0) {
    const f = node.callFrame;
    const file = f.url.split('/').pop() ?? '(builtin)';
    const key = `${f.functionName === '' ? '(top level)' : f.functionName} @ ${file}:${f.lineNumber + 1}`;
    out.set(key, (out.get(key) ?? 0) + node.selfSize);
    total += node.selfSize;
  }
  for (const child of node.children) total += walk(child, out);
  return total;
}

/**
 * Bytes allocated per call of `frame`, with the harness subtracted.
 *
 * Two things here are load-bearing and both were learned the hard way.
 *
 * The warm-up is not politeness. A cold V8 allocates feedback vectors, inline
 * caches and optimised code for everything the loop touches on its first few
 * hundred passes, and sampling through that measures the compiler rather than the
 * game - it read roughly twenty times the steady-state number. The measured loop
 * must be the *optimised* one, so the same work is run first and thrown away.
 *
 * The empty loop is measured and subtracted for the same reason as in the e2e
 * probe: the driver is not the subject.
 */
export async function sampleAllocations(
  frame: () => void,
  frames: number,
  warmup = frames,
): Promise<AllocationResult> {
  for (let i = 0; i < warmup; i++) frame();

  const session = new Session();
  session.connect();
  await session.post('HeapProfiler.enable');

  await session.post('HeapProfiler.startSampling', { samplingInterval: 128 });
  for (let i = 0; i < frames; i++) void i;
  const idle = await session.post('HeapProfiler.stopSampling');

  await session.post('HeapProfiler.startSampling', { samplingInterval: 128 });
  for (let i = 0; i < frames; i++) frame();
  const busy = await session.post('HeapProfiler.stopSampling');

  session.disconnect();

  const idleBytes = walk(idle.profile.head as unknown as HeapNode, new Map());
  const sites = new Map<string, number>();
  const busyBytes = walk(busy.profile.head as unknown as HeapNode, sites);
  const bytes = Math.max(0, busyBytes - idleBytes);

  return {
    perFrame: Math.round(bytes / frames),
    totalBytes: bytes,
    sites: [...sites.entries()].sort((a, b) => b[1] - a[1]).slice(0, 8),
  };
}
