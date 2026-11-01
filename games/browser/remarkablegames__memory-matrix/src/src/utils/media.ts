const HOVER_POINTER_QUERY = '(hover: hover) and (pointer: fine)';

/**
 * Reports whether the device has a real hovering pointer. Touch devices
 * emulate :hover on tap, which would fire hover cues alongside click cues.
 *
 * @returns Whether hover cues should play.
 */
export function canHover(): boolean {
  return (
    typeof window.matchMedia === 'function' &&
    window.matchMedia(HOVER_POINTER_QUERY).matches
  );
}
