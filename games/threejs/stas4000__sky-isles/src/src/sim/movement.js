// Pure player movement math — no three imports, unit-testable.

export const MOVE = {
  gravity: -22,
  jumpSpeed: 8.6,
  doubleJumpSpeed: 7.6,
  maxJumps: 2,
  glideFallSpeed: -2.5,
  glideBoost: 4.2,
  walkSpeed: 6.2,
  accel: 34,
  respawnY: -40,
  coyoteTime: 0.12
};

export function createMoveState() {
  return {
    vx: 0,
    vz: 0,
    vy: 0,
    grounded: true,
    jumpsUsed: 0,
    gliding: false,
    coyote: 0
  };
}

// Advance vertical motion one step.
// input: { jumpPressed: boolean, jumpHeld: boolean }
// mutates and returns `state`; returns via state.events what happened.
export function stepVertical(state, input, dt, cfg = MOVE) {
  const events = { jumped: 0, landed: false };

  if (state.grounded) {
    state.coyote = cfg.coyoteTime;
    state.jumpsUsed = 0;
    state.gliding = false;
  } else {
    state.coyote = Math.max(0, state.coyote - dt);
  }

  if (input.jumpPressed) {
    const canGroundJump = (state.grounded || state.coyote > 0) && state.jumpsUsed === 0;
    if (canGroundJump) {
      state.vy = cfg.jumpSpeed;
      state.jumpsUsed = 1;
      state.grounded = false;
      state.coyote = 0;
      events.jumped = 1;
    } else if (!state.grounded && state.jumpsUsed < cfg.maxJumps) {
      // mid-air jump (also the save-yourself jump after falling off a ledge)
      state.vy = cfg.doubleJumpSpeed;
      state.jumpsUsed = cfg.maxJumps;
      events.jumped = 2;
    }
  }

  // Glide: holding jump while falling caps fall speed.
  state.gliding = !state.grounded && state.vy < 0 && input.jumpHeld;

  state.vy += cfg.gravity * dt;
  if (state.gliding && state.vy < cfg.glideFallSpeed) {
    state.vy = cfg.glideFallSpeed;
  }

  state.events = events;
  return state;
}

// Horizontal velocity approaches the wish velocity with smooth acceleration.
// `wish` is a normalized-ish direction scaled by walk speed already.
export function stepHorizontal(state, wishX, wishZ, dt, cfg = MOVE) {
  const speedScale = state.gliding ? (cfg.walkSpeed + cfg.glideBoost) / cfg.walkSpeed : 1;
  const tx = wishX * speedScale;
  const tz = wishZ * speedScale;
  const t = Math.min(1, cfg.accel * dt / cfg.walkSpeed);
  state.vx += (tx - state.vx) * t;
  state.vz += (tz - state.vz) * t;
  return state;
}

export function shouldRespawn(y, cfg = MOVE) {
  return y < cfg.respawnY;
}
