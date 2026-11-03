import { afterEach, describe, expect, it } from 'vitest';
import { needsSilentLoop, silentWavDataUri } from '../src/audio/SilentLoop';

/**
 * The loop is only worth anything if it is built on exactly the phones that need
 * it, and plays a file a browser will accept. Whether WebKit then lets Web Audio
 * through the silent switch is not something a test can hear; these hold the two
 * halves that can be checked from here.
 */
describe('SilentLoop', () => {
  const navigatorBefore = Object.getOwnPropertyDescriptor(globalThis, 'navigator');
  const documentBefore = Object.getOwnPropertyDescriptor(globalThis, 'document');

  function fake(nav: Record<string, unknown>): void {
    Object.defineProperty(globalThis, 'navigator', {
      configurable: true,
      value: nav,
    });
    Object.defineProperty(globalThis, 'document', {
      configurable: true,
      value: {},
    });
  }

  afterEach(() => {
    if (navigatorBefore) Object.defineProperty(globalThis, 'navigator', navigatorBefore);
    if (documentBefore) Object.defineProperty(globalThis, 'document', documentBefore);
    else delete (globalThis as { document?: unknown }).document;
  });

  const IPHONE =
    'Mozilla/5.0 (iPhone; CPU iPhone OS 16_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/120.0 Mobile/15E148 Safari/604.1';
  const IPAD_AS_MAC =
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Safari/605.1.15';
  const ANDROID =
    'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36';

  it('is built on an iPhone and an iPad that cannot declare a session', () => {
    fake({ userAgent: IPHONE, maxTouchPoints: 5 });
    expect(needsSilentLoop()).toBe(true);
    fake({ userAgent: IPAD_AS_MAC, maxTouchPoints: 5 });
    expect(needsSilentLoop()).toBe(true);
  });

  it('is not built where the Audio Session API does the job, nor off iOS', () => {
    fake({
      userAgent: IPHONE,
      maxTouchPoints: 5,
      audioSession: { type: 'auto' },
    });
    expect(needsSilentLoop()).toBe(false);
    // A real Mac: same user agent as the iPad, and no touch screen.
    fake({ userAgent: IPAD_AS_MAC, maxTouchPoints: 0 });
    expect(needsSilentLoop()).toBe(false);
    fake({ userAgent: ANDROID, maxTouchPoints: 5 });
    expect(needsSilentLoop()).toBe(false);
  });

  it('plays a well-formed half second of 8-bit silence', () => {
    const uri = silentWavDataUri();
    expect(uri.startsWith('data:audio/wav;base64,')).toBe(true);
    const bytes = Buffer.from(uri.slice(uri.indexOf(',') + 1), 'base64');
    expect(bytes.toString('ascii', 0, 4)).toBe('RIFF');
    expect(bytes.toString('ascii', 8, 12)).toBe('WAVE');
    expect(bytes.readUInt32LE(4)).toBe(bytes.length - 8);
    expect(bytes.readUInt32LE(24)).toBe(8000);
    expect(bytes.readUInt16LE(34)).toBe(8);
    expect(bytes.readUInt32LE(40)).toBe(4000);
    // Silence for unsigned 8-bit PCM is the midpoint, every sample of it.
    expect(bytes.subarray(44).every((b) => b === 128)).toBe(true);
  });
});
