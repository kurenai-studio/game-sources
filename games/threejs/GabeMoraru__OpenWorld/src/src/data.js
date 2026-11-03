export const NODES = [
  { id: 'works', name: 'Halcyon Works', district: 'Industrial', pos: [0, 300], cost: 0, radius: 95, perk: null,
    perkText: 'The last plant still breathing.' },
  { id: 'midtown', name: 'Midtown Exchange', district: 'City', pos: [0, 0], cost: 15, radius: 135, perk: 'carry',
    perkText: 'Ember tank +15' },
  { id: 'uptown', name: 'Uptown Spire', district: 'City', pos: [-80, -160], cost: 30, radius: 120, perk: 'radar',
    perkText: 'Radar reveals every ember' },
  { id: 'docks', name: 'Saltline Docks', district: 'Waterfront', pos: [240, 80], cost: 34, radius: 120, perk: 'boost',
    perkText: 'Boost recharges 2x faster' },
  { id: 'maple', name: 'Maple Court', district: 'Suburbs', pos: [-360, 40], cost: 36, radius: 135, perk: 'magnet',
    perkText: 'Ember pull radius 2x' },
  { id: 'linden', name: 'Linden Heights', district: 'Suburbs', pos: [-320, -220], cost: 46, radius: 130, perk: 'ward',
    perkText: 'Hollows move 35% slower' },
  { id: 'orchard', name: 'Coldwater Orchard', district: 'Farmland', pos: [-200, 360], cost: 40, radius: 140, perk: 'yield',
    perkText: 'Substations yield +50%' },
  { id: 'barley', name: 'Barley Flats', district: 'Farmland', pos: [300, 290], cost: 50, radius: 150, perk: 'stock',
    perkText: 'Stockpiles hold 2x' },
  { id: 'ridge', name: 'Windmill Ridge', district: 'Highlands', pos: [370, -140], cost: 56, radius: 150, perk: 'speed',
    perkText: 'Top speed +15%' },
  { id: 'beacon', name: 'Summit Beacon', district: 'Mountains', pos: [20, -430], cost: 90, radius: 260, perk: 'dawn',
    perkText: 'Draws on the whole grid. Ends the long night.' },
];

export const LINKS = [
  ['works', 'midtown'], ['works', 'orchard'], ['works', 'barley'],
  ['midtown', 'uptown'], ['midtown', 'docks'], ['midtown', 'maple'],
  ['maple', 'linden'], ['maple', 'orchard'], ['uptown', 'linden'],
  ['docks', 'barley'], ['docks', 'ridge'], ['ridge', 'beacon'], ['uptown', 'beacon'],
];

const city = [];
for (let i = -3; i <= 3; i++) {
  city.push({ kind: 'city', pts: [[i * 80, -240], [i * 80, 240]] });
  city.push({ kind: 'city', pts: [[-240, i * 80], [240, i * 80]] });
}

export const ROADS = [
  ...city,
  { kind: 'rural', pts: [[0, 240], [0, 300]] },
  { kind: 'rural', pts: [[0, 300], [-80, 335], [-150, 345], [-200, 360]] },
  { kind: 'rural', pts: [[0, 300], [90, 322], [200, 305], [300, 290]] },
  { kind: 'rural', pts: [[240, 160], [262, 210], [290, 250], [300, 290]] },
  { kind: 'rural', pts: [[240, -80], [300, -105], [370, -140]] },
  { kind: 'mountain', pts: [[370, -140], [345, -240], [300, -330], [220, -385], [120, -420], [20, -430]] },
  { kind: 'mountain', pts: [[-80, -240], [-70, -300], [10, -330], [-40, -380], [20, -430]] },
  { kind: 'suburb', pts: [[-240, 0], [-300, 15], [-360, 40], [-440, 50], [-500, 30]] },
  { kind: 'suburb', pts: [[-300, -80], [-310, 40], [-300, 150], [-320, 220]] },
  { kind: 'suburb', pts: [[-420, -60], [-410, 60], [-430, 170]] },
  { kind: 'suburb', pts: [[-300, 150], [-370, 140], [-440, 120], [-500, 105]] },
  { kind: 'suburb', pts: [[-240, -160], [-280, -190], [-320, -220]] },
  { kind: 'suburb', pts: [[-320, -220], [-400, -230], [-470, -200]] },
  { kind: 'suburb', pts: [[-300, -80], [-320, -160], [-320, -220], [-330, -300], [-300, -360]] },
  { kind: 'suburb', pts: [[-400, -130], [-405, -300]] },
  { kind: 'rural', pts: [[-200, 360], [-260, 300], [-320, 220]] },
  { kind: 'rural', pts: [[-200, 360], [-120, 420], [-40, 440]] },
  { kind: 'rural', pts: [[300, 290], [370, 250], [420, 190]] },
  { kind: 'rural', pts: [[200, 305], [220, 380], [160, 440]] },
  { kind: 'rural', pts: [[370, -140], [430, -70], [440, -10]] },
];

export const LANTERNS = [
  [60, -500], [-120, -470], [330, -400], [480, -230], [470, 330],
  [-60, 480], [-500, 260], [-520, -300], [140, -300], [-180, -320],
];
