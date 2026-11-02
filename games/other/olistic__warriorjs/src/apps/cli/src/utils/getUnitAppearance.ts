export interface UnitAppearance {
  character: string;
  color: string;
}

const warriorAppearance: UnitAppearance = { character: '@', color: 'cyan' };

const registry: Record<string, UnitAppearance> = {
  Archer: { character: 'a', color: 'yellow' },
  Captive: { character: 'C', color: 'green' },
  Sludge: { character: 's', color: 'red' },
  'Thick Sludge': { character: 'S', color: 'redBright' },
  Wizard: { character: 'w', color: 'magenta' },
};

function getUnitAppearanceFallback(name: string): UnitAppearance {
  return {
    character: name[0]?.toLowerCase() ?? '?',
    color: 'white',
  };
}

function getUnitAppearance(name: string, warrior?: boolean): UnitAppearance {
  if (warrior) return warriorAppearance;
  return registry[name] ?? getUnitAppearanceFallback(name);
}

export default getUnitAppearance;
