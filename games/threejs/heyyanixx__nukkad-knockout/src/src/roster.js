// 9 original fighters + 1 secret boss. CARRY MINTU is a clearly-labelled parody archetype. All fictional archetypes (no real people,
// no game/brand names or outfits) except HEYY ANISH, who is the owner of this game.
// speed/back = walk speed forward/back (px per frame), jump = jump velocity,
// dmgMul / reachMul / meterMul tune each fighter. superType picks the super move.
export const ROSTER = [
  {
    id: 'chaiwala', name: 'CHAIWALA CHHOTU', group: 'DESI', tag: 'Garam chai, garam haath',
    color: '#ff8a1f', speed: 4.1, back: 3.2, jump: -17.5, dmgMul: 1.09, reachMul: 1.02, meterMul: 1.05, scale: 0.92,
    look: { skin: '#c98b5e', shirt: '#f4efe4', pants: '#6b4a2b', shoes: '#2a2a2a', hair: '#1b1210', extra: 'towel', acc: '#d9382c' },
    moves: { rush: 'CUTTING CHAI PUNCH', fly: 'KULHAD KICK', sweep: 'GILA FARSH', upper: 'UBAAL UPPERCUT', grab: 'CHAI PE CHARCHA' },
    superName: 'KETLI TSUNAMI', superColor: '#c8853f', superType: 'chai',
  },
  {
    id: 'auto', name: 'AUTO ANNA', group: 'DESI', tag: 'Meter se nahi, mood se chalta hai',
    color: '#f2d43c', speed: 3.4, back: 2.7, jump: -16, dmgMul: 1.08, reachMul: 1.05, meterMul: 1.0, scale: 1.02,
    look: { skin: '#9a6440', shirt: '#c9b98a', pants: '#3a3a3a', shoes: '#111111', hair: '#141414', extra: 'mustache', acc: '#e3b65a' },
    moves: { rush: 'METER DOWN', fly: 'SIDE MIRROR KICK', sweep: 'SPEED BREAKER', upper: 'HORN OK PLEASE', grab: 'SAWARI PAKAD' },
    superName: 'AUTO RAM', superColor: '#f2d43c', superType: 'auto',
  },
  {
    id: 'dadi', name: 'DADI NO. 1', group: 'DESI', tag: 'Chappal ka nishana kabhi nahi chookta',
    color: '#d85bb5', speed: 3.1, back: 2.6, jump: -15, dmgMul: 1.06, reachMul: 1.0, meterMul: 1.15, scale: 0.9,
    look: { skin: '#c79a74', shirt: '#d85bb5', pants: '#b8469a', shoes: '#7a4b2a', hair: '#e9e6e0', extra: 'bun', glasses: true, saree: true },
    moves: { rush: 'BELAN BASH', fly: 'SANSKAARI KICK', sweep: 'JHADU SWEEP', upper: 'AASHIRWAAD UPPER', grab: 'KAAN PAKAD' },
    superName: 'CHAPPAL BOOMERANG', superColor: '#7a4b2a', superType: 'chappal',
  },
  {
    id: 'headshot', name: 'HEADSHOT HERO', group: 'BATTLE ROYALE', tag: 'One tap. Bas.',
    color: '#e3b65a', speed: 3.9, back: 3.0, jump: -16.5, dmgMul: 1.16, reachMul: 1.06, meterMul: 1.05, scale: 1.0,
    look: { skin: '#a8714a', shirt: '#2b2f3a', pants: '#4b5a3a', shoes: '#1a1a1a', hair: '#151010', extra: 'hood', acc: '#e3b65a' },
    moves: { rush: 'RUSH B', fly: 'DROP ZONE KICK', sweep: 'PRONE SWEEP', upper: 'HEADSHOT UPPER', grab: 'KNOCK DOWN' },
    superName: 'ONE TAP HEADSHOT', superColor: '#e3b65a', superType: 'headshot',
  },
  {
    id: 'jelly', name: 'JELLY WALL JOJO', group: 'BATTLE ROYALE', tag: 'Deewar hu main, gir nahi sakta',
    color: '#5fd3ff', speed: 3.0, back: 2.5, jump: -15.5, dmgMul: 1.12, reachMul: 1.05, meterMul: 1.0, scale: 1.08,
    look: { skin: '#8d5a3b', shirt: '#2f6f8f', pants: '#1f2a33', shoes: '#5fd3ff', hair: '#0f0f0f', extra: 'helmet', acc: '#5fd3ff', wide: 1.2 },
    moves: { rush: 'SHIELD BASH', fly: 'WALL HOP KICK', sweep: 'SLIDE CANCEL', upper: 'JELLY POP', grab: 'BOX ME IN' },
    superName: 'JELLY WALL', superColor: '#7fe6ff', superType: 'jelly',
  },
  {
    id: 'goblin', name: 'LOOT GOBLIN', group: 'BATTLE ROYALE', tag: 'Tera loot, mera loot',
    color: '#7bd23c', speed: 4.0, back: 3.3, jump: -17.5, dmgMul: 0.86, reachMul: 1.1, meterMul: 1.1, scale: 0.86,
    look: { skin: '#9fbf5a', shirt: '#6b4a2b', pants: '#3b3b2b', shoes: '#2b2b2b', hair: '#2b2b10', extra: 'pan', acc: '#3a3a3a', bigEars: true },
    moves: { rush: 'PAN SLAP', fly: 'AIRDROP KICK', sweep: 'BUSH CAMP', upper: 'LOOT UPPER', grab: 'POCKET CHECK' },
    superName: 'PAN-DEMIC', superColor: '#bfbfbf', superType: 'pans',
  },
  {
    id: 'sid', name: 'STREAMER SID', group: 'CREATOR', tag: 'Like, share, subscribe... aur maar',
    color: '#ff3b6b', speed: 3.6, back: 2.9, jump: -16.5, dmgMul: 1.12, reachMul: 1.0, meterMul: 1.15, scale: 0.98,
    look: { skin: '#b5835c', shirt: '#1d1d28', pants: '#2c2c44', shoes: '#ff3b6b', hair: '#1a1010', extra: 'headset', acc: '#ff3b6b', rgb: true },
    moves: { rush: 'DONATION DASH', fly: 'CLIP IT KICK', sweep: 'BUFFERING SWEEP', upper: 'SUPER CHAT UPPER', grab: 'BAN HAMMER' },
    superName: 'SMASH THAT LIKE', superColor: '#ff3b6b', superType: 'likes',
  },
  {
    id: 'vicky', name: 'VLOGGER VICKY', group: 'CREATOR', tag: 'Guys aaj hum... maarenge',
    color: '#ffd23f', speed: 3.6, back: 2.9, jump: -16.5, dmgMul: 0.91, reachMul: 1.15, meterMul: 1.1, scale: 0.96,
    look: { skin: '#c48a60', shirt: '#ffd23f', pants: '#2a2a3a', shoes: '#f0f0f0', hair: '#2a1a10', extra: 'selfie', shades: true },
    moves: { rush: 'SELFIE STICK JAB', fly: 'THUMBNAIL KICK', sweep: 'B-ROLL SWEEP', upper: 'SUBSCRIBE UPPER', grab: 'COLLAB PAKAD' },
    superName: 'RING LIGHT FLASH', superColor: '#ffffff', superType: 'flash',
  },
  {
    id: 'mintu', name: 'CARRY MINTU', group: 'CREATOR (PARODY)', tag: 'Roast karega, toast karega', parody: true,
    color: '#ff5a1f', speed: 3.6, back: 2.9, jump: -16.5, dmgMul: 0.88, reachMul: 1.0, meterMul: 1.1, scale: 1.0,
    look: { skin: '#b98258', shirt: '#2a2a2a', pants: '#1c1c22', shoes: '#ff5a1f', hair: '#120c0a', extra: 'mintu', beard: true, acc: '#ff5a1f' },
    moves: { rush: 'ROAST MIC', fly: 'BEEP BLAST', sweep: 'CRINGE SWEEP', upper: 'TRIGGERED UPPER', grab: 'CHAL NIKAL' },
    specials: { rush: 'roast', fly: 'beep' },
    superName: 'YALGAAR SCREAM', superColor: '#ff5a1f', superType: 'scream',
  },
  {
    id: 'anish', name: 'HEYY ANISH', group: 'SECRET BOSS', tag: 'Owner of the game. Badla pakka.', secret: true,
    color: '#e3b65a', speed: 3.9, back: 3.1, jump: -17, dmgMul: 0.87, reachMul: 1.05, meterMul: 1.2, scale: 1.0,
    look: { skin: '#b07a52', shirt: '#0b0b0f', pants: '#14141a', shoes: '#e3b65a', hair: '#d8dde6', extra: 'anish', redEyes: true, acc: '#e3b65a' },
    moves: { rush: 'LOL EMOTE', fly: 'BAWAAL KICK', sweep: 'CAMPER SWEEP', upper: 'HEYY UPPER', grab: 'GOLD GRIP' },
    specials: { rush: 'emote' },
    superName: '8-3 BADLA', superColor: '#e3b65a', superType: 'badla',
  },
];

export const STAGES = [
  { id: 'tapri', name: 'CHAI TAPRI NIGHT' },
  { id: 'terrace', name: 'PATANG TERRACE' },
  { id: 'platform', name: 'NUKKAD JUNCTION' },
];

export const byId = (id) => ROSTER.find((c) => c.id === id) || ROSTER[0];
