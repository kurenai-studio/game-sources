// Vocabulary for Type to Kill, sorted into pools by length at load.
const RAW = `
ash axe bat bug cut die dig fog gun hex ink jaw key lab mud nil oak pit rat rot saw tar van war zip
acid bang bite bomb bone claw dark dead dust fang fear fire gore grim hive howl husk iron jolt kill
limb maul mine moan neck nest omen pain raid rage rust scar soot tomb vein wolf wound yell zone
ankle ashes blade bleed blood brood brute chase choke claws crawl crypt decay devil feast flesh ghoul
grave gruel havoc horde hunts knife lurch magma mange nerve night panic plague prowl quake rabid raven
reload rifle rotten scalp shell shock skull slime snarl spine stalk swarm talon teeth thorn tooth venom
vomit wrath zombie
ambush armory barrel bullet burrow carbon charge cinder coffin corpse crater danger debris dragon
exhale famine fester flames frenzy fumble gibber grisly hollow hunger impact jackal kindle larvae
legion mangle marrow mortar mutant oblige plasma poison powder primal ravage ripper savage scream
shadow shrink shroud siege signal skitter sniper spider sprint stench strike tumble tyrant unholy
vermin wither
ambushed arsenal barrage blister bombard brimstone butcher cadaver carnage cartridge cavalry charnel
crimson crossfire darkness decimate demolish detonate devour disease dreadful eclipse entrails
epidemic eruption execute explosion fissure flamethrower fugitive fungus gangrene gauntlet grenade
gunpowder hellfire horrible howitzer incinerate infection insanity juggernaut lacerate lockdown
maggot massacre mayhem merciless minefield monstrous mutation nightmare obliterate onslaught
outbreak overrun parasite pestilence phantom predator pulverize quarantine rampage reckoning
relentless revenant sacrifice sanctuary scavenger screaming shrapnel slaughter sniping stampede
survivor tentacle terminal torment trenches unleashed vanguard vengeance wasteland wildfire
`;

export const WORDS = [...new Set(RAW.trim().split(/\s+/))];
export const byLength = (min, max) => WORDS.filter((w) => w.length >= min && w.length <= max);
