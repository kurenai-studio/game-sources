import { useEffect, useState } from 'react';
import { loadSettings, saveSettings } from 'src/utils/storage';
import { configure } from 'websfx';

import { Button } from '../Button';

interface SoundIconProps {
  muted: boolean;
}

function SoundIcon({ muted }: SoundIconProps) {
  return (
    <svg
      aria-hidden="true"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={2}
      strokeLinecap="round"
      strokeLinejoin="round"
      className="size-5"
    >
      <path d="M11 5 6 9H3v6h3l5 4V5Z" />
      {muted ? (
        <>
          <path d="m16 9 5 6" />
          <path d="m21 9-5 6" />
        </>
      ) : (
        <>
          <path d="M15.5 8.5a5 5 0 0 1 0 7" />
          <path d="M18.5 5.5a9 9 0 0 1 0 13" />
        </>
      )}
    </svg>
  );
}

/**
 * Global sound switch, rendered by the app so it stays in the same corner
 * on every screen. The stored volume is applied to websfx on mount, so the
 * preference survives reloads.
 *
 * @returns The corner sound toggle.
 */
export function SoundToggle() {
  const [volume, setVolume] = useState(loadSettings);
  const soundOn = volume.volume > 0;

  useEffect(() => {
    configure({ volume: volume.volume });
  }, [volume]);

  function toggle(): void {
    const next = soundOn ? 0 : 1;
    saveSettings({ volume: next });
    setVolume({ ...volume, volume: next });
  }

  return (
    <Button
      variant="icon"
      role="switch"
      aria-checked={soundOn}
      aria-label="Sound"
      onClick={toggle}
    >
      <SoundIcon muted={!soundOn} />
    </Button>
  );
}
