import { ImageResponse } from "next/og";
import { DEPTH_COLORS } from "@/lib/depth-colors.generated";
import { chamferPath } from "@/lib/geometry";
import { SITE_DESCRIPTION } from "@/lib/seo";

export const OG_SIZE = { width: 1200, height: 630 };
export const OG_CONTENT_TYPE = "image/png";

const C = DEPTH_COLORS.light;
const LETTERS = ["A", "L", "G", "O", "M", "I", "N", "D"];
const SHADOW_LAYERS = 5;

type Tone = "tile" | "signal" | "ink";
const KEY_COLORS = {
  tile: { face: C.tile, lip: C.tileLip, label: C.ink },
  signal: { face: C.signal, lip: C.signalLip, label: C.onSignal },
  ink: { face: C.ink, lip: C.inkLip, label: C.onInk },
} as const;

/**
 * A key as the game draws it: a soft shadow, a lip, and a chamfered face with its label. The
 * element takes `size` by `size` plus the lip, and the shadow spills past its box.
 */
function Key({
  size,
  tone,
  label,
  lip = Math.round(size * 0.07),
}: {
  size: number;
  tone: Tone;
  label?: string;
  lip?: number;
}) {
  const colors = KEY_COLORS[tone];
  const pad = Math.round(size * 0.3);
  const cut = size * 0.25;
  return (
    <div style={{ position: "relative", display: "flex", width: size, height: size + lip }}>
      <svg
        width={size + 2 * pad}
        height={size + lip + 2 * pad}
        viewBox={`${-pad} ${-pad} ${size + 2 * pad} ${size + lip + 2 * pad}`}
        style={{ position: "absolute", left: -pad, top: -pad }}
      >
        {Array.from({ length: SHADOW_LAYERS }, (_, i) => {
          const grow = ((SHADOW_LAYERS - i) * size * 0.16) / SHADOW_LAYERS;
          return (
            <path
              key={i}
              d={chamferPath(-grow, lip * 2 - grow, size + 2 * grow, size + 2 * grow, cut)}
              fill={C.shadow}
              fillOpacity={0.3 / SHADOW_LAYERS}
            />
          );
        })}
        <path d={chamferPath(0, lip, size, size, cut)} fill={colors.lip} />
        <path d={chamferPath(0, 0, size, size, cut)} fill={colors.face} />
      </svg>
      {label && (
        <div
          style={{
            position: "absolute",
            left: 0,
            top: 0,
            display: "flex",
            width: size,
            height: size,
            alignItems: "center",
            justifyContent: "center",
            fontSize: size * 0.62,
            color: colors.label,
            WebkitTextStroke: `${Math.max(1, size * 0.04)}px ${colors.label}`,
          }}
        >
          {label}
        </div>
      )}
    </div>
  );
}

/** The recessed tape: a strip with a soft shadow along its top edge (stacked bands), holding the keys. */
function Trough({ children }: { children: React.ReactNode }) {
  return (
    <div
      style={{
        position: "relative",
        display: "flex",
        gap: 16,
        padding: "26px 28px 30px",
        background: C.strip,
      }}
    >
      {[0, 1, 2, 3, 4].map((i) => (
        <div
          key={i}
          style={{
            position: "absolute",
            left: 0,
            top: i * 5,
            width: "100%",
            height: 5,
            background: C.shadow,
            opacity: 0.3 * (1 - i / 5),
          }}
        />
      ))}
      {children}
    </div>
  );
}

/**
 * The 1200 by 630 share image in the depth look: a soft gradient ground, the wordmark as keys,
 * the page title, and a short program on the recessed tape with one yellow key. Light theme;
 * colors are the depth tokens.
 */
export function renderShareImage({ title, subtitle }: { title: string; subtitle?: string }) {
  return new ImageResponse(
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        justifyContent: "space-between",
        width: "100%",
        height: "100%",
        padding: 72,
        backgroundImage: `linear-gradient(to bottom, ${C.groundTop}, ${C.groundBottom})`,
        color: C.ink,
      }}
    >
      <div style={{ display: "flex", gap: 10 }}>
        {LETTERS.map((letter, i) => (
          <Key key={letter + i} size={64} tone={i === 0 ? "signal" : "ink"} label={letter} />
        ))}
      </div>
      <div style={{ display: "flex", flexDirection: "column" }}>
        <div
          style={{
            display: "flex",
            fontSize: title.length > 24 ? 84 : 104,
            lineHeight: 1,
            letterSpacing: 2,
            textTransform: "uppercase",
          }}
        >
          {title}
        </div>
        <div style={{ display: "flex", marginTop: 28, fontSize: 36, color: C.mute }}>
          {subtitle ?? SITE_DESCRIPTION}
        </div>
      </div>
      <div style={{ display: "flex" }}>
        <Trough>
          <Key size={72} tone="ink" />
          <Key size={72} tone="ink" />
          <Key size={72} tone="signal" />
          <Key size={72} tone="tile" />
          <Key size={72} tone="tile" />
        </Trough>
      </div>
    </div>,
    { ...OG_SIZE },
  );
}
