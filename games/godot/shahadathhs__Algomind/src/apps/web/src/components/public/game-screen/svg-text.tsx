export const TEXT = { strokeWidth: 0 } as const;

export function SvgCaption({ x, y, children }: { x: number; y: number; children: string }) {
  return (
    <text x={x} y={y} fontSize={10} letterSpacing={2} className="fill-mute" {...TEXT}>
      {children}
    </text>
  );
}
