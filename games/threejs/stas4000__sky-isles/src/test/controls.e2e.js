import { test, expect } from '@playwright/test';

// Regression test for the inverted-controls bug: the camera-relative wish
// direction must match the camera frame, so forward on the stick / W key
// moves the character away from the camera, left goes left, etc.

async function waitForWorld(page) {
  await page.goto('/');
  await page.waitForFunction(() => window.__skyisles && window.__skyisles.getState, null, { timeout: 60_000 });
  await page.evaluate(() => window.__skyisles.start());
  await page.waitForTimeout(1500);
}

// camera forward on the ground plane for a given orbit yaw
function expectedDir(yaw, key) {
  const sin = Math.sin(yaw);
  const cos = Math.cos(yaw);
  switch (key) {
    case 'KeyW': return { x: -sin, z: -cos }; // forward
    case 'KeyS': return { x: sin, z: cos }; // back
    case 'KeyD': return { x: cos, z: -sin }; // right
    case 'KeyA': return { x: -cos, z: sin }; // left
    default: throw new Error(key);
  }
}

async function getPos(page) {
  return page.evaluate(() => window.__skyisles.getState().playerPos);
}

// Holds `startAct` input until the character has moved at least `minDist`
// horizontally (or times out), immune to first-frame shader-compile hitches.
async function measureDirection(page, startAct, stopAct, minDist = 2.5) {
  const before = await getPos(page);
  await startAct();
  let after = before;
  let len = 0;
  const deadline = Date.now() + 5000;
  while (Date.now() < deadline) {
    await page.waitForTimeout(120);
    after = await getPos(page);
    len = Math.hypot(after.x - before.x, after.z - before.z);
    if (len >= minDist) break;
  }
  await stopAct();
  const dx = after.x - before.x;
  const dz = after.z - before.z;
  return { dx: dx / len, dz: dz / len, len };
}

test.describe('controls point where the player expects', () => {
  const YAW = 0.7;

  for (const key of ['KeyW', 'KeyS', 'KeyA', 'KeyD']) {
    test(`${key} moves the character along the camera-relative ${key === 'KeyW' ? 'forward' : key === 'KeyS' ? 'back' : key === 'KeyA' ? 'left' : 'right'} direction`, async ({ page }) => {
      await waitForWorld(page);
      await page.evaluate((yaw) => {
        window.__skyisles.teleport(0, 0.5, 3.5);
        window.__skyisles.setOrbit(yaw, 0.38, 8);
      }, YAW);
      // let the character land and settle after the teleport
      await page.waitForTimeout(600);

      const result = await measureDirection(
        page,
        () => page.keyboard.down(key),
        () => page.keyboard.up(key)
      );

      const want = expectedDir(YAW, key);
      const dot = result.dx * want.x + result.dz * want.z;
      expect(result.len).toBeGreaterThan(1); // actually moved
      expect(dot).toBeGreaterThan(0.9); // and in the expected direction
    });
  }

  test('touch joystick up moves the character forward', async ({ page, isMobile }) => {
    test.skip(!isMobile, 'joystick is only visible on coarse-pointer devices');
    await waitForWorld(page);
    await page.evaluate((yaw) => {
      window.__skyisles.teleport(0, 0.5, 3.5);
      window.__skyisles.setOrbit(yaw, 0.38, 8);
    }, YAW);
    await page.waitForTimeout(600);

    const stick = page.locator('#joystick');
    await expect(stick).toBeVisible();
    const box = await stick.boundingBox();
    const cx = box.x + box.width / 2;
    const cy = box.y + box.height / 2;

    const session = await page.context().newCDPSession(page);
    const result = await measureDirection(
      page,
      async () => {
        await session.send('Input.dispatchTouchEvent', {
          type: 'touchStart',
          touchPoints: [{ x: cx, y: cy, id: 1 }]
        });
        await session.send('Input.dispatchTouchEvent', {
          type: 'touchMove',
          touchPoints: [{ x: cx, y: cy - box.height * 0.4, id: 1 }]
        });
      },
      async () => {
        await session.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
        await session.detach();
      }
    );

    const want = expectedDir(YAW, 'KeyW');
    const dot = result.dx * want.x + result.dz * want.z;
    expect(result.len).toBeGreaterThan(1);
    expect(dot).toBeGreaterThan(0.9);
  });
});
