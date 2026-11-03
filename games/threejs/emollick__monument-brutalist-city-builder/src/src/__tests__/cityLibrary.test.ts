import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import {
  CITY_LIBRARY_KEY,
  CITY_TEMPLATES,
  LEGACY_CITY_KEY,
  readCityLibrary,
  snapshotSummary,
  writeCityLibrary,
} from '../cityLibrary'
import type { CitySaveRecord } from '../cityLibrary'

const memoryStorage = (): Storage => {
  const values = new Map<string, string>()
  return {
    get length() { return values.size },
    clear: () => values.clear(),
    getItem: key => values.get(key) ?? null,
    key: index => [...values.keys()][index] ?? null,
    removeItem: key => { values.delete(key) },
    setItem: (key, value) => { values.set(key, String(value)) },
  }
}

describe('city templates and local library', () => {
  let storage: Storage

  beforeEach(() => {
    storage = memoryStorage()
    vi.stubGlobal('localStorage', storage)
  })

  afterEach(() => vi.unstubAllGlobals())

  it('provides four unique starting cities with stable instance-prefixed ids', () => {
    expect(CITY_TEMPLATES.map(template => template.id)).toEqual([
      'blank',
      'civic-basin',
      'garden-terraces',
      'campus-forum',
    ])

    for (const template of CITY_TEMPLATES) {
      const snapshot = template.create(`test-${template.id}`)
      expect(new Set(snapshot.buildings.map(building => building.id)).size).toBe(snapshot.buildings.length)
      expect(new Set(snapshot.plazas.map(plaza => plaza.id)).size).toBe(snapshot.plazas.length)
      expect(snapshot.buildings.every(building => building.id.startsWith(`test-${template.id}-b-`))).toBe(true)
      expect(snapshot.plazas.every(plaza => plaza.id.startsWith(`test-${template.id}-p-`))).toBe(true)
    }
  })

  it('creates fresh template snapshots rather than sharing mutable buildings', () => {
    const template = CITY_TEMPLATES.find(candidate => candidate.id === 'garden-terraces')!
    const first = template.create('fresh')
    const originalHeight = first.buildings[0].height
    first.buildings[0].height = 999

    expect(template.create('fresh').buildings[0].height).toBe(originalHeight)
  })

  it('writes at most thirty saves and reads valid records back', () => {
    const blank = CITY_TEMPLATES[0].create('blank')
    const records: CitySaveRecord[] = Array.from({ length: 35 }, (_, index) => ({
      id: `city-${index}`,
      name: `City ${index}`,
      createdAt: index,
      updatedAt: index,
      snapshot: { ...structuredClone(blank), day: index + 1 },
    }))

    expect(writeCityLibrary(records)).toBe(true)
    expect(JSON.parse(storage.getItem(CITY_LIBRARY_KEY) ?? '[]')).toHaveLength(30)
    expect(readCityLibrary()).toHaveLength(30)
  })

  it('filters malformed library entries', () => {
    const valid: CitySaveRecord = {
      id: 'valid',
      name: 'Valid city',
      createdAt: 1,
      updatedAt: 1,
      snapshot: CITY_TEMPLATES[0].create('valid'),
    }
    storage.setItem(CITY_LIBRARY_KEY, JSON.stringify([{ id: 'broken', snapshot: {} }, valid, null]))

    expect(readCityLibrary()).toEqual([valid])
  })

  it('migrates the legacy single-city save and normalizes its mood summary', () => {
    const legacy = { ...CITY_TEMPLATES[1].create('legacy'), day: 8, mood: 'brutalist' as const }
    storage.setItem(LEGACY_CITY_KEY, JSON.stringify(legacy))

    const recovered = readCityLibrary()
    expect(recovered).toHaveLength(1)
    expect(recovered[0].name).toContain('Day 8')
    expect(storage.getItem(CITY_LIBRARY_KEY)).not.toBeNull()
    expect(snapshotSummary(legacy)).toMatchObject({ day: 8, mood: 'default' })
  })
})
