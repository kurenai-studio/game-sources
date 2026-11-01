enum Breakpoint {
  sm = 576,
  md = 768,
  lg = 992,
  xl = 1200,
  xxl = 1400,
}

/**
 * Gets device scale.
 *
 * @returns - Scale between 0 and 1.
 */
export function getDeviceScale() {
  const scale = window.innerWidth / Breakpoint.xxl

  if (scale > 1) {
    return 1
  }

  return scale
}
