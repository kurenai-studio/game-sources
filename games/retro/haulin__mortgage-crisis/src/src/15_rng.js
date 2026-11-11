// MC.rng: deterministic PRNG helpers (bitwise coercion stays localized here).
MC.rng.u32NonZero = function (n) {
  var x = (n >>> 0);
  return x ? x : 1;
};

MC.rng.xorshift32Step = function (sU32) {
  var x = sU32 >>> 0;
  if (!x) x = 1;
  x ^= x << 13;
  x >>>= 0;
  x ^= x >>> 17;
  x ^= x << 5;
  x >>>= 0;
  return x >>> 0;
};

MC.rng.RNG = function (seedU32) {
  this.s = MC.rng.u32NonZero(seedU32);
};

// Standalone RNG instances (handy for tests/utilities; separate from RNG-in-state).
MC.rng.RNG.prototype.nextU32 = function () {
  this.s = MC.rng.xorshift32Step(this.s >>> 0);
  return this.s >>> 0;
};

MC.rng.RNG.prototype.nextInt = function (n) {
  n = n | 0;
  if (n <= 0) return 0;
  return (this.nextU32() % n) | 0;
};

// RNG-in-state helpers (store evolving state in `state.rngS`).
MC.rng.nextIntInState = function (state, n) {
  n = n | 0;
  if (n <= 0) return 0;
  state.rngS = MC.rng.xorshift32Step(state.rngS >>> 0);
  return ((state.rngS >>> 0) % n) | 0;
};

