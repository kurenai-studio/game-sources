// Scripted arenas. Each wave: [seconds, creature, count, pattern]. Patterns are resolved in director.js.
const m = (id, name, biome, weapon, brief, waves) => ({ id, name, biome, weapon, brief, waves });

export const MISSIONS = [
  m('1-1', 'First Contact', 'dust', 'pistol', 'They came up out of the salt. Hold the basin.', [
    [0, 'shambler', 6, 'edge'], [7, 'shambler', 8, 'edge'], [14, 'shambler', 10, 'sides'], [24, 'shambler', 14, 'ring'],
  ]),
  m('1-2', 'Skitter Season', 'dust', 'pistol', 'Fast, stupid, and there are a lot of them.', [
    [0, 'skitter', 10, 'edge'], [6, 'skitter', 14, 'sides'], [13, 'shambler', 10, 'ring'], [20, 'skitter', 24, 'corners'], [30, 'skitter', 30, 'ring'],
  ]),
  m('1-3', 'Pincer', 'dust', 'smg', 'Two columns. Keep moving between them.', [
    [0, 'shambler', 16, 'sides'], [9, 'shambler', 18, 'sides'], [18, 'ripper', 4, 'edge'], [24, 'skitter', 22, 'sides'], [33, 'ripper', 8, 'ring'],
  ]),
  m('1-4', 'Rippers', 'dust', 'shotgun', 'The pack hunts in the open. So do you.', [
    [0, 'ripper', 5, 'edge'], [8, 'ripper', 7, 'sides'], [16, 'shambler', 24, 'ring'], [24, 'ripper', 12, 'corners'], [36, 'ripper', 16, 'ring'],
  ]),
  m('1-5', 'The Big One', 'dust', 'rifle', 'Something heavy is walking this way.', [
    [0, 'shambler', 14, 'ring'], [6, 'brute', 1, 'edge'], [14, 'skitter', 20, 'corners'], [22, 'brute', 2, 'sides'], [32, 'shambler', 30, 'ring'], [38, 'brute', 3, 'ring'],
  ]),
  m('2-1', 'Fen Crawl', 'moss', 'rifle', 'The peat is moving.', [
    [0, 'skitter', 20, 'ring'], [7, 'spitter', 3, 'edge'], [14, 'shambler', 20, 'sides'], [22, 'spitter', 5, 'ring'], [32, 'skitter', 40, 'corners'],
  ]),
  m('2-2', 'Hive Mind', 'moss', 'shotgun', 'Burn out the hives before they fill the fen.', [
    [0, 'nest', 3, 'nests'], [6, 'shambler', 12, 'edge'], [16, 'ripper', 6, 'ring'], [28, 'skitter', 24, 'corners'],
  ]),
  m('2-3', 'Live Rounds', 'moss', 'plasma', 'Bursters. Do not let them reach you.', [
    [0, 'burster', 8, 'edge'], [7, 'burster', 12, 'sides'], [14, 'shambler', 24, 'ring'], [22, 'burster', 22, 'corners'], [34, 'burster', 34, 'ring'],
  ]),
  m('2-4', 'Mother of Many', 'moss', 'rifle', 'She is carrying thousands.', [
    [0, 'skitter', 14, 'ring'], [4, 'brood', 1, 'edge'], [20, 'spitter', 3, 'sides'], [32, 'brood', 1, 'sides'], [44, 'ripper', 10, 'ring'],
  ]),
  m('2-5', 'Drowned Choir', 'moss', 'plasma', 'Every voice in the fen, all at once.', [
    [0, 'shambler', 18, 'ring'], [9, 'spitter', 4, 'ring'], [18, 'burster', 10, 'corners'], [28, 'nest', 2, 'nests'], [38, 'brute', 2, 'ring'], [50, 'skitter', 36, 'ring'],
  ]),
  m('3-1', 'Cinder Walk', 'ash', 'rifle', 'The ground burns and they do not care.', [
    [0, 'ripper', 8, 'ring'], [9, 'burster', 12, 'sides'], [18, 'brute', 2, 'edge'], [28, 'ripper', 12, 'corners'], [40, 'brute', 3, 'ring'],
  ]),
  m('3-2', 'Scorched Earth', 'ash', 'rocket', 'Make the craters bigger than the horde.', [
    [0, 'shambler', 40, 'ring'], [8, 'shambler', 40, 'sides'], [18, 'brute', 3, 'ring'], [28, 'shambler', 60, 'ring'], [40, 'brute', 5, 'corners'],
  ]),
  m('3-3', 'Vent Nests', 'ash', 'plasma', 'They seeded the fissures. Clear all of them.', [
    [0, 'nest', 5, 'nests'], [10, 'spitter', 6, 'ring'], [20, 'burster', 20, 'ring'], [34, 'ripper', 16, 'corners'],
  ]),
  m('3-4', 'No Quarter', 'ash', 'minigun', 'Stand and spend every round you have.', [
    [0, 'ripper', 10, 'ring'], [7, 'skitter', 28, 'ring'], [16, 'brute', 3, 'ring'], [25, 'spitter', 5, 'corners'], [33, 'burster', 18, 'ring'], [44, 'brood', 1, 'sides'],
  ]),
  m('3-5', 'Tyrant', 'ash', 'plasma', 'It has been following you since the basin.', [
    [0, 'shambler', 16, 'ring'], [8, 'tyrant', 1, 'edge'], [30, 'ripper', 8, 'ring'], [52, 'burster', 12, 'ring'], [74, 'brute', 2, 'ring'],
  ]),
  m('4-1', 'Whiteout', 'frost', 'ion', 'Everything shows up on snow. So do you.', [
    [0, 'skitter', 22, 'ring'], [9, 'ripper', 8, 'corners'], [20, 'spitter', 4, 'ring'], [32, 'skitter', 36, 'ring'],
  ]),
  m('4-2', 'Cold Storage', 'frost', 'saw', 'The dead keep well out here.', [
    [0, 'shambler', 60, 'ring'], [10, 'brute', 4, 'sides'], [20, 'shambler', 70, 'ring'], [32, 'brute', 6, 'ring'],
  ]),
  m('4-3', 'Thaw', 'frost', 'triplasma', 'Hives under the ice. Break them.', [
    [0, 'nest', 6, 'nests'], [6, 'brood', 1, 'edge'], [18, 'ripper', 20, 'ring'], [32, 'burster', 36, 'ring'], [46, 'brood', 2, 'corners'],
  ]),
  m('4-4', 'Everything', 'frost', 'swarm', 'It stopped being a fight a while ago.', [
    [0, 'ripper', 14, 'ring'], [8, 'spitter', 6, 'ring'], [16, 'brute', 4, 'ring'], [26, 'burster', 24, 'ring'], [36, 'skitter', 60, 'ring'], [48, 'brood', 2, 'ring'],
  ]),
  m('4-5', 'Last Light', 'frost', 'minigun', 'Finish it.', [
    [0, 'shambler', 30, 'ring'], [10, 'tyrant', 1, 'edge'], [34, 'ripper', 18, 'ring'], [54, 'brood', 1, 'sides'], [72, 'tyrant', 1, 'edge'], [92, 'skitter', 70, 'ring'],
  ]),
];
