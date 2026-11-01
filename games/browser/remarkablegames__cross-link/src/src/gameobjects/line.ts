import type { GameObj, OpacityComp, PosComp } from 'kaplay'

import { TAG } from '../constants'
import type { Dot, DotColor } from './dot'
import { animateDotClear } from './dot'

interface LineState {
  lineColor: DotColor
  dotA: Dot
  dotB: Dot
}

export type Line = GameObj<PosComp & OpacityComp & LineState & string>

function segmentsIntersect(
  ax: number,
  ay: number,
  bx: number,
  by: number,
  cx: number,
  cy: number,
  dx: number,
  dy: number,
): boolean {
  const dxAB = bx - ax
  const dyAB = by - ay
  const dxCD = dx - cx
  const dyCD = dy - cy

  const denom = dxAB * dyCD - dyAB * dxCD
  if (Math.abs(denom) < 1e-10) return false

  const t = ((cx - ax) * dyCD - (cy - ay) * dxCD) / denom
  const u = ((cx - ax) * dyAB - (cy - ay) * dxAB) / denom

  return t > 0.01 && t < 0.99 && u > 0.01 && u < 0.99
}

export function addLine(dotA: Dot, dotB: Dot, lineColor: DotColor): Line {
  const line = add([
    pos(0, 0),
    TAG.LINE,
    opacity(0),
    { lineColor, dotA, dotB } satisfies LineState,
  ]) as Line

  line.onDraw(() => {
    const colorMap: Record<DotColor, [number, number, number]> = {
      gold: [245, 197, 66],
      cyan: [79, 195, 247],
      rose: [244, 143, 177],
      green: [168, 224, 99],
      white: [232, 232, 240],
    }
    const [r, g, b] = colorMap[lineColor]
    drawLine({
      p1: line.dotA.pos,
      p2: line.dotB.pos,
      width: 8,
      color: rgb(r, g, b),
      opacity: line.opacity * 0.12,
    })
    drawLine({
      p1: line.dotA.pos,
      p2: line.dotB.pos,
      width: 2.5,
      color: rgb(r, g, b),
      opacity: line.opacity * 0.9,
    })
  })

  tween(
    0,
    1,
    0.15,
    (v) => {
      line.opacity = v
    },
    easings.easeOutQuad,
  )

  return line
}

export function findIntersectingLines(newLine: Line, allLines: Line[]): Line[] {
  const ax = newLine.dotA.pos.x
  const ay = newLine.dotA.pos.y
  const bx = newLine.dotB.pos.x
  const by = newLine.dotB.pos.y

  return allLines.filter((other) => {
    if (other === newLine) return false
    if (other.lineColor === newLine.lineColor) return false
    return segmentsIntersect(
      ax,
      ay,
      bx,
      by,
      other.dotA.pos.x,
      other.dotA.pos.y,
      other.dotB.pos.x,
      other.dotB.pos.y,
    )
  })
}

export function clearLines(linesToClear: Line[], onAllDone: () => void) {
  const dots: Dot[] = []
  for (const line of linesToClear) {
    dots.push(line.dotA, line.dotB)
    line.destroy()
  }

  let remaining = dots.length
  if (remaining === 0) {
    onAllDone()
    return
  }

  for (const dot of dots) {
    animateDotClear(dot, () => {
      dot.destroy()
      remaining--
      if (remaining === 0) onAllDone()
    })
  }
}
