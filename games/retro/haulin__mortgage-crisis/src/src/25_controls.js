// MC.controls: input state machine (injected/pollable controls with repeat + hold/tap detection).
MC.controls.newState = function () {
  return {
    // Previous raw button-down state (0..7).
    prevDown: [false, false, false, false, false, false, false, false],

    // Per-button consecutive held frames.
    held: [0, 0, 0, 0, 0, 0, 0, 0],

    // A-hold grab tracking.
    aGrabActive: false,
    aGrabEnteredThisPress: false,

    // X inspect delay tracking.
    xInspectActive: false,

    // D-pad repeat counters (per direction button id 0..3).
    dpadRepeat: [0, 0, 0, 0],

    // Mouse tracking (hover/click/drag).
    mouse: {
      prevX: 0,
      prevY: 0,
      prevLeft: false,
      prevMiddle: false,
      prevRight: false,
      pressX: 0,
      pressY: 0,
      leftDragActive: false,
      leftDraggedThisPress: false,
    },
  };
};

MC.controls.pollGlobals = function () {
  var down = [false, false, false, false, false, false, false, false];
  var pressed = [false, false, false, false, false, false, false, false];

  var i;
  for (i = 0; i < 8; i++) {
    down[i] = !!btn(i);
    pressed[i] = !!btnp(i);
  }

  var m = null;
  var r = mouse();
  if (r != null) {
    var x = 0, y = 0;
    var left = false, middle = false, right = false;
    var scrollx = 0, scrolly = 0;
    if (r && typeof r.length === "number") {
      x = Number(r[0]);
      y = Number(r[1]);
      left = !!r[2];
      middle = !!r[3];
      right = !!r[4];
      scrollx = Number(r[5]);
      scrolly = Number(r[6]);
    } else if (r && typeof r === "object") {
      x = Number(r.x);
      y = Number(r.y);
      left = !!r.left;
      middle = !!r.middle;
      right = !!r.right;
      scrollx = Number(r.scrollx);
      scrolly = Number(r.scrolly);
    }
    if (!isFinite(x)) x = 0;
    if (!isFinite(y)) y = 0;
    if (!isFinite(scrollx)) scrollx = 0;
    if (!isFinite(scrolly)) scrolly = 0;
    m = { x: x, y: y, left: left, middle: middle, right: right, scrollx: scrollx, scrolly: scrolly };
  }

  return { down: down, pressed: pressed, mouse: m };
};

// Canonical "no input" actions shape (useful when suppressing player input).
MC.controls.emptyActions = function () {
  return {
    nav: { up: false, down: false, left: false, right: false },
    a: { down: false, pressed: false, released: false, tap: false, grabActive: false, grabStart: false },
    b: { pressed: false },
    x: { down: false, pressed: false, released: false, inspectActive: false },
    mouse: {
      avail: false,
      x: 0,
      y: 0,
      pressX: null,
      pressY: null,
      moved: false,
      scrollX: 0,
      scrollY: 0,
      left: { down: false, pressed: false, released: false, tap: false },
      middle: { down: false, pressed: false, released: false },
      right: { down: false, pressed: false, released: false },
      dragging: false,
      dragStart: false
    }
  };
};

MC.controls.actions = function (st, raw, cfg) {
  if (!st) st = MC.controls.newState();
  // Contract: caller provides {down[8], pressed[8]} and cfg from MC.config.controls.
  var down = raw.down;
  var pressed = raw.pressed;
  var mouseCfg = MC.config.mouse;
  var m = raw ? raw.mouse : null;
  var mouseEnabled = !!(mouseCfg && mouseCfg.enabled && m);
  var mouseSt = st.mouse || null;

  var repeatDelay = cfg.dpadRepeatDelayFrames;
  var repeatPeriod = cfg.dpadRepeatPeriodFrames;

  var grabFallback = cfg.aHoldFallbackFrames;

  var inspectDelay = cfg.xInspectDelayFrames;

  var mx = mouseEnabled && m.x != null ? m.x : 0;
  var my = mouseEnabled && m.y != null ? m.y : 0;
  var mLeftDown = mouseEnabled ? !!m.left : false;
  var mMiddleDown = mouseEnabled ? !!m.middle : false;
  var mRightDown = mouseEnabled ? !!m.right : false;
  var mScrollX = mouseEnabled && m.scrollx != null ? m.scrollx : 0;
  var mScrollY = mouseEnabled && m.scrolly != null ? m.scrolly : 0;
  if (!isFinite(mx)) mx = 0;
  if (!isFinite(my)) my = 0;
  if (!isFinite(mScrollX)) mScrollX = 0;
  if (!isFinite(mScrollY)) mScrollY = 0;

  var mPrevX = mouseSt ? mouseSt.prevX : 0;
  var mPrevY = mouseSt ? mouseSt.prevY : 0;
  var mPrevLeft = mouseSt ? !!mouseSt.prevLeft : false;
  var mPrevMiddle = mouseSt ? !!mouseSt.prevMiddle : false;
  var mPrevRight = mouseSt ? !!mouseSt.prevRight : false;

  var mMoved = mouseEnabled ? (mx !== mPrevX || my !== mPrevY) : false;
  var mLeftPressed = mouseEnabled ? (mLeftDown && !mPrevLeft) : false;
  var mLeftReleased = mouseEnabled ? (!mLeftDown && mPrevLeft) : false;
  var mMiddlePressed = mouseEnabled ? (mMiddleDown && !mPrevMiddle) : false;
  var mMiddleReleased = mouseEnabled ? (!mMiddleDown && mPrevMiddle) : false;
  var mRightPressed = mouseEnabled ? (mRightDown && !mPrevRight) : false;
  var mRightReleased = mouseEnabled ? (!mRightDown && mPrevRight) : false;

  // Mouse drag detection (left button).
  var dragStartPx = mouseCfg ? mouseCfg.dragStartPx : 0;
  if (!isFinite(dragStartPx)) dragStartPx = 0;
  var dragStartNow = false;
  var mouseDragging = false;
  if (mouseSt) {
    if (mLeftPressed) {
      mouseSt.pressX = mx;
      mouseSt.pressY = my;
      mouseSt.leftDragActive = false;
      mouseSt.leftDraggedThisPress = false;
    }

    if (mLeftDown) {
      if (!mouseSt.leftDragActive && dragStartPx > 0) {
        var dx = mx - mouseSt.pressX;
        var dy = my - mouseSt.pressY;
        if (dx * dx + dy * dy >= dragStartPx * dragStartPx) {
          mouseSt.leftDragActive = true;
          mouseSt.leftDraggedThisPress = true;
          dragStartNow = true;
        }
      }
    }

    if (mLeftReleased) {
      mouseSt.leftDragActive = false;
    }

    mouseDragging = !!(mLeftDown && mouseSt.leftDragActive);
  }

  var i;
  for (i = 0; i < 8; i++) {
    var isDown = !!down[i];
    // Mouse middle-click is treated as X (Inspect) hold.
    if (i === 6 && mMiddleDown) isDown = true;
    st.held[i] = isDown ? (st.held[i] + 1) : 0;
  }

  // Edge detection from down states (used in case caller doesn't provide pressed[]).
  function fell(iBtn) { return !!st.prevDown[iBtn] && !down[iBtn]; }
  function rose(iBtn) { return !st.prevDown[iBtn] && !!down[iBtn]; }

  // D-pad repeat: synthesize nav pulses.
  function navPulse(btnId) {
    if (!down[btnId]) { st.dpadRepeat[btnId] = 0; return false; }

    // Prefer provided pressed[] as the initial pulse.
    if (pressed[btnId] || rose(btnId)) { st.dpadRepeat[btnId] = 0; return true; }

    st.dpadRepeat[btnId] += 1;
    if (st.dpadRepeat[btnId] < repeatDelay) return false;

    var t = st.dpadRepeat[btnId] - repeatDelay;
    return (t % repeatPeriod) === 0;
  }

  var up = navPulse(0);
  var downNav = navPulse(1);
  var left = navPulse(2);
  var right = navPulse(3);

  if (mouseEnabled && mouseCfg && mouseCfg.wheelNav) {
    var dy = mScrollY;
    if (mouseCfg.wheelInvertY) dy = -dy;
    if (dy < 0) up = true;
    else if (dy > 0) downNav = true;
  }

  var aDownBtn = !!down[4];
  var aPressedBtn = !!pressed[4] || rose(4);
  var aReleasedBtn = fell(4);
  var aDown = !!(aDownBtn || mLeftDown);
  var aPressed = !!(aPressedBtn || mLeftPressed);
  var aReleased = !!(aReleasedBtn || mLeftReleased);

  var bPressed = !!(!!pressed[5] || rose(5) || mRightPressed);

  var xDown = !!(down[6] || mMiddleDown);
  var xPressed = !!(!!pressed[6] || rose(6) || mMiddlePressed);
  var xReleased = !!(fell(6) || mMiddleReleased);

  // A grab mode: enter on hold+move (any nav pulse while A held),
  // or on fallback hold threshold.
  if (aPressed) {
    st.aGrabActive = false;
    st.aGrabEnteredThisPress = false;
  }

  var navAny = !!(up || downNav || left || right);
  var aHeldFrames = st.held[4];
  var aGrabStartNow = false;

  if (aDown && !st.aGrabActive) {
    var shouldEnter = false;
    if (navAny && aHeldFrames > 0) shouldEnter = true;
    else if (aHeldFrames >= grabFallback && grabFallback > 0) shouldEnter = true;
    else if (dragStartNow) shouldEnter = true;
    if (shouldEnter) {
      st.aGrabActive = true;
      st.aGrabEnteredThisPress = true;
      aGrabStartNow = true;
    }
  }

  if (aReleased) {
    st.aGrabActive = false;
  }

  // Tap A is only when it was a press->release without entering grab.
  var aTap = false;
  if (aReleased) {
    aTap = !st.aGrabEnteredThisPress;
    st.aGrabEnteredThisPress = false;
  }

  // Inspect: active only after delay while X held.
  if (xPressed) st.xInspectActive = false;
  if (!xDown) st.xInspectActive = false;
  if (xDown && !st.xInspectActive) {
    if (st.held[6] >= inspectDelay && inspectDelay > 0) st.xInspectActive = true;
    if (inspectDelay === 0) st.xInspectActive = true;
  }
  if (xReleased) st.xInspectActive = false;

  // Persist prevDown.
  for (i = 0; i < 8; i++) st.prevDown[i] = !!down[i];

  // Persist mouse state.
  if (mouseSt) {
    mouseSt.prevX = mx;
    mouseSt.prevY = my;
    mouseSt.prevLeft = !!mLeftDown;
    mouseSt.prevMiddle = !!mMiddleDown;
    mouseSt.prevRight = !!mRightDown;
  }

  var leftTap = false;
  if (mouseSt) leftTap = !!(mLeftReleased && !mouseSt.leftDraggedThisPress);

  return {
    nav: { up: up, down: downNav, left: left, right: right },

    a: {
      down: aDown,
      pressed: aPressed,
      released: aReleased,
      tap: aTap,
      grabActive: !!st.aGrabActive,
      grabStart: !!aGrabStartNow,
    },

    b: { pressed: !!bPressed },

    x: {
      down: xDown,
      pressed: xPressed,
      released: xReleased,
      inspectActive: !!st.xInspectActive,
    },

    mouse: {
      avail: !!mouseEnabled,
      x: mx,
      y: my,
      pressX: mouseSt ? mouseSt.pressX : mx,
      pressY: mouseSt ? mouseSt.pressY : my,
      moved: !!mMoved,
      scrollX: mScrollX,
      scrollY: mScrollY,
      left: { down: !!mLeftDown, pressed: !!mLeftPressed, released: !!mLeftReleased, tap: !!leftTap },
      middle: { down: !!mMiddleDown, pressed: !!mMiddlePressed, released: !!mMiddleReleased },
      right: { down: !!mRightDown, pressed: !!mRightPressed, released: !!mRightReleased },
      dragging: !!mouseDragging,
      dragStart: !!dragStartNow,
    },
  };
};

