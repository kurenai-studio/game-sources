import { describe, expect, it } from 'vitest'
import { CELL, GRID, HALF, TYPOLOGIES, initialBuildings, lots, makeBuilding } from '../data'

describe('city grid and building seeds', () => {
  it('creates a centered square parcel grid', () => {
    expect(lots).toHaveLength(GRID * GRID)
    expect(lots.some(lot => lot.gx === 0 && lot.gz === 0)).toBe(true)
    expect(Math.min(...lots.map(lot => lot.gx))).toBe(-HALF)
    expect(Math.max(...lots.map(lot => lot.gx))).toBe(HALF)
    expect(new Set(lots.map(lot => `${lot.x},${lot.z}`)).size).toBe(lots.length)
  })

  it('copies the selected typology into a new building', () => {
    const building = makeBuilding(CELL, -CELL, 'work', 'tower', 3)
    const tower = TYPOLOGIES.tower

    expect(building).toMatchObject({
      x: CELL,
      z: -CELL,
      program: 'work',
      typology: 'tower',
      height: tower.height,
      width: tower.width,
      depth: tower.depth,
      composition: tower.composition,
      profile: tower.profile,
      structural: tower.structural,
      facade: tower.facade,
    })
    expect(building.id).toMatch(/^b-/)
  })

  it('ships a valid and spatially unique starter district', () => {
    const buildings = initialBuildings()

    expect(buildings).toHaveLength(11)
    expect(new Set(buildings.map(building => building.id)).size).toBe(buildings.length)
    expect(new Set(buildings.map(building => `${building.x},${building.z}`)).size).toBe(buildings.length)
    expect(buildings.every(building => building.height > 0 && building.width > 0 && building.depth > 0)).toBe(true)
    expect(buildings.every(building => Number.isFinite(building.rotation))).toBe(true)
  })
})
