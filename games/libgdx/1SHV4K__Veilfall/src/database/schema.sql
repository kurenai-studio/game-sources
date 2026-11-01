PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS player_profile (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    name TEXT NOT NULL,
    level INTEGER NOT NULL DEFAULT 1 CHECK (level >= 1),
    experience INTEGER NOT NULL DEFAULT 0 CHECK (experience >= 0),
    wins INTEGER NOT NULL DEFAULT 0 CHECK (wins >= 0),
    losses INTEGER NOT NULL DEFAULT 0 CHECK (losses >= 0),
    battles INTEGER NOT NULL DEFAULT 0 CHECK (battles >= 0),
    enemies_defeated INTEGER NOT NULL DEFAULT 0 CHECK (enemies_defeated >= 0),
    bosses_defeated INTEGER NOT NULL DEFAULT 0 CHECK (bosses_defeated >= 0),
    best_wave INTEGER NOT NULL DEFAULT 0 CHECK (best_wave >= 0)
);

CREATE TABLE IF NOT EXISTS characters (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    hp INTEGER NOT NULL CHECK (hp > 0),
    attack INTEGER NOT NULL CHECK (attack >= 0),
    speed REAL NOT NULL CHECK (speed > 0),
    defense INTEGER NOT NULL CHECK (defense >= 0),
    attack_range REAL NOT NULL CHECK (attack_range > 0)
);

CREATE TABLE IF NOT EXISTS weapons (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    character_id INTEGER NOT NULL,
    damage INTEGER NOT NULL CHECK (damage >= 0),
    attack_speed REAL NOT NULL CHECK (attack_speed > 0),
    attack_range REAL NOT NULL CHECK (attack_range > 0),
    FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS skills (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    character_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    key_binding TEXT NOT NULL,
    damage INTEGER NOT NULL CHECK (damage >= 0),
    cooldown REAL NOT NULL CHECK (cooldown >= 0),
    UNIQUE (character_id, name),
    UNIQUE (character_id, key_binding),
    FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS mobs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    type TEXT NOT NULL,
    hp INTEGER NOT NULL CHECK (hp > 0),
    damage INTEGER NOT NULL CHECK (damage >= 0),
    speed REAL NOT NULL CHECK (speed > 0),
    attack_range REAL NOT NULL CHECK (attack_range > 0),
    is_boss INTEGER NOT NULL DEFAULT 0 CHECK (is_boss IN (0, 1))
);

CREATE TABLE IF NOT EXISTS arenas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL,
    difficulty INTEGER NOT NULL CHECK (difficulty > 0),
    environment TEXT NOT NULL,
    boss_mob_id INTEGER NOT NULL,
    FOREIGN KEY (boss_mob_id) REFERENCES mobs(id)
);

CREATE TABLE IF NOT EXISTS waves (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    arena_id INTEGER NOT NULL,
    wave_number INTEGER NOT NULL CHECK (wave_number > 0),
    health_multiplier REAL NOT NULL DEFAULT 1.0 CHECK (health_multiplier > 0),
    damage_multiplier REAL NOT NULL DEFAULT 1.0 CHECK (damage_multiplier > 0),
    boss_wave INTEGER NOT NULL DEFAULT 0 CHECK (boss_wave IN (0, 1)),
    UNIQUE (arena_id, wave_number),
    FOREIGN KEY (arena_id) REFERENCES arenas(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS wave_enemies (
    wave_id INTEGER NOT NULL,
    mob_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (wave_id, mob_id),
    FOREIGN KEY (wave_id) REFERENCES waves(id) ON DELETE CASCADE,
    FOREIGN KEY (mob_id) REFERENCES mobs(id)
);

CREATE TABLE IF NOT EXISTS matches (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    result TEXT NOT NULL CHECK (result IN ('WIN', 'LOSS')),
    arena_id INTEGER NOT NULL,
    character_id INTEGER NOT NULL,
    weapon_id INTEGER,
    waves_reached INTEGER NOT NULL DEFAULT 0 CHECK (waves_reached >= 0),
    enemies_defeated INTEGER NOT NULL DEFAULT 0 CHECK (enemies_defeated >= 0),
    bosses_defeated INTEGER NOT NULL DEFAULT 0 CHECK (bosses_defeated >= 0),
    duration_seconds REAL NOT NULL DEFAULT 0 CHECK (duration_seconds >= 0),
    played_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (arena_id) REFERENCES arenas(id),
    FOREIGN KEY (character_id) REFERENCES characters(id),
    FOREIGN KEY (weapon_id) REFERENCES weapons(id)
);
