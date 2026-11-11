// MC.seed: seed policy for dev + release-ish runs.
// - Dev tools ON: deterministic per seedBase (reproducible debugging).
// - Dev tools OFF: time-based per-second seed so New Game isn't identical.
MC.seed.computeSeedU32 = function () {
  var seedBase = MC.config.seedBase;
  var toolsOn = !!(MC.debug && MC.debug.toolsOn);
  if (toolsOn) return MC.rng.u32NonZero(seedBase);

  var t = Math.floor(tstamp());
  return MC.rng.u32NonZero(seedBase + t);
};

