import { describe, expect, it } from 'vitest'
import { makeBuilding } from '../data'
import { controlContextNote, controlDisabledReason, isVillageCluster } from '../controlApplicability'
import type { Building } from '../types'

const buildingWith = (patch: Partial<Building> = {}): Building => ({
  ...makeBuilding(0, 0, 'housing', 'slab', 0),
  ...patch,
})

describe('architectural control applicability', () => {
  it('keeps capsule taper available while explaining analytical-only controls', () => {
    const capsule = buildingWith({ composition: 'capsule', branches: 2, podiumHeight: 0 })

    expect(controlDisabledReason(capsule, 'taper')).toBeUndefined()
    expect(controlContextNote(capsule, 'baySpacing')).toContain('service spine')
    expect(controlContextNote(capsule, 'porosity')).toContain('daylight')
  })

  it('locks controls that have no ring geometry', () => {
    const ring = buildingWith({ composition: 'ring', profile: 'straight' })

    expect(controlDisabledReason(ring, 'articulation')).toContain('continuous ring')
    expect(controlDisabledReason(ring, 'branches')).toContain('cannot grow lateral branches')
    expect(controlDisabledReason(ring, 'crown')).toContain('fixed roof rim')
    expect(controlDisabledReason(ring, 'taper')).toContain('Choose Stepped')
    expect(controlDisabledReason(ring, 'rhythm')).toBeUndefined()
  })

  it('recognizes low-rise village clusters and their distinct growth grammar', () => {
    const village = buildingWith({
      composition: 'cluster',
      height: 30,
      articulation: 68,
      moduleDensity: 4,
      podiumHeight: 0,
    })

    expect(isVillageCluster(village)).toBe(true)
    expect(controlDisabledReason(village, 'branches')).toContain('aggregation')
    expect(controlDisabledReason(village, 'terraces')).toContain('individual roofs')
    expect(controlDisabledReason(village, 'cantilever')).toContain('separate pieces')
  })

  it('keeps performance controls usable even when their effect is analytical', () => {
    const briseSoleil = buildingWith({ facade: 'brise-soleil', composition: 'bar' })

    expect(controlDisabledReason(briseSoleil, 'porosity')).toBeUndefined()
    expect(controlContextNote(briseSoleil, 'porosity')).toContain('Performance value')
  })
})
