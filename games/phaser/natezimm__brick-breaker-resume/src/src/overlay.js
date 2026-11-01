import { calculateBrickLayouts } from './brickLayout.js';
import { renderLayout } from './brickDom.js';

/**
 * Draws the résumé into every look pane on the start screen. Each pane names
 * the layout it shows with `data-mode`, and all of them share one request.
 */
export async function renderOverlayBricks() {
  const overlay = document.getElementById('startOverlay');
  if (!overlay) return;

  const panes = [...overlay.querySelectorAll('.look-resume[data-mode]')];
  if (panes.length === 0) return;

  try {
    const layouts = await calculateBrickLayouts(
      panes.map((pane) => pane.dataset.mode)
    );
    panes.forEach((pane, index) => renderLayout(pane, layouts[index]));
  } catch (e) {
    console.warn('Could not render overlay bricks:', e);
  }
}

const SEAM_MIN = 12;
const SEAM_MAX = 88;

/**
 * Lets a finger or pen drag the seam between the two looks. A mouse leans
 * the seam by hovering instead (see base.css), which touch screens cannot do.
 */
export function enableSeamDrag(
  overlay = document.getElementById('startOverlay')
) {
  if (!overlay) return;

  const follow = (event) => {
    if (event.pointerType === 'mouse') return;
    if (overlay.classList.contains('hidden')) return;
    // A tap on a button or link is a choice, not a drag.
    if (event.target?.closest?.('button, a')) return;

    const { left, width } = overlay.getBoundingClientRect();
    if (!width) return;

    const percent = ((event.clientX - left) / width) * 100;
    const split = Math.min(SEAM_MAX, Math.max(SEAM_MIN, percent));
    overlay.classList.add('is-dragging');
    overlay.style.setProperty('--split', `${split.toFixed(1)}%`);
  };

  const release = () => overlay.classList.remove('is-dragging');

  overlay.addEventListener('pointerdown', follow);
  overlay.addEventListener('pointermove', follow);
  overlay.addEventListener('pointerup', release);
  overlay.addEventListener('pointercancel', release);
}
