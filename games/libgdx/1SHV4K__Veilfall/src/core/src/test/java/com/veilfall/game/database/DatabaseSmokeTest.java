package com.veilfall.game.database;

import com.veilfall.game.data.PlayerData;
import com.veilfall.game.data.WaveEnemyData;
import com.veilfall.game.database.repository.ArenaRepository;
import com.veilfall.game.database.repository.CharacterRepository;
import com.veilfall.game.database.repository.MobRepository;
import com.veilfall.game.database.repository.PlayerRepository;
import com.veilfall.game.database.repository.SkillRepository;
import com.veilfall.game.database.repository.WaveRepository;
import com.veilfall.game.database.repository.WeaponRepository;
import com.veilfall.game.database.repository.MatchRepository;
import com.veilfall.game.data.MatchData;
import com.veilfall.game.player.CharacterKit;

import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;
import java.util.Comparator;
import java.util.stream.Collectors;

public final class DatabaseSmokeTest {
    private DatabaseSmokeTest() {
    }

    public static void main(String[] args) throws Exception {
        Path temporaryDirectory = Files.createTempDirectory("veilfall-database-smoke");
        Path databasePath = temporaryDirectory.resolve("saves/veilfall.db");
        try {
            verifyDatabase(databasePath);
            verifyLegacyMatchMigration(temporaryDirectory.resolve("legacy/veilfall.db"));
            System.out.println("Database smoke test passed: " + databasePath);
        } finally {
            try (var paths = Files.walk(temporaryDirectory)) {
                for (Path path : paths.sorted(Comparator.reverseOrder()).toList()) Files.deleteIfExists(path);
            }
        }
    }

    private static void verifyLegacyMatchMigration(Path databasePath) throws Exception {
        try (DatabaseManager manager = new DatabaseManager(databasePath)) {
            manager.withConnection(connection -> {
                try (var statement = connection.createStatement()) {
                    statement.execute("""
                            CREATE TABLE matches (
                                id INTEGER PRIMARY KEY AUTOINCREMENT,
                                result TEXT NOT NULL,
                                arena_id INTEGER NOT NULL,
                                character_id INTEGER NOT NULL,
                                waves_reached INTEGER NOT NULL DEFAULT 0,
                                enemies_defeated INTEGER NOT NULL DEFAULT 0,
                                bosses_defeated INTEGER NOT NULL DEFAULT 0,
                                duration_seconds REAL NOT NULL DEFAULT 0,
                                played_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
                            )
                            """);
                }
                return null;
            });
            new DatabaseInitializer(manager).initialize();
            boolean hasWeapon = manager.withConnection(connection -> {
                try (var statement = connection.createStatement();
                     var result = statement.executeQuery("PRAGMA table_info(matches)")) {
                    while (result.next()) {
                        if ("weapon_id".equalsIgnoreCase(result.getString("name"))) return true;
                    }
                    return false;
                }
            });
            require(hasWeapon, "legacy match history should migrate with an optional weapon column");
        }
    }

    private static void verifyDatabase(Path databasePath) throws Exception {
        try (DatabaseManager manager = new DatabaseManager(databasePath)) {
            DatabaseInitializer initializer = new DatabaseInitializer(manager);
            initializer.initialize();
            initializer.initialize();

            require(Files.isRegularFile(databasePath), "database file was not created");
            require(tableCount(manager, "player_profile") == 1, "player profile table/data missing");
            require(new PlayerRepository(manager).getPlayerProfile()
                    .map(PlayerData::getName).filter("Wanderer"::equals).isPresent(), "Wanderer profile missing");
            var characters = new CharacterRepository(manager).getAll();
            var weapons = new WeaponRepository(manager).getAll();
            require(characters.size() == 3, "expected 3 characters");
            require(weapons.size() == 6, "expected 6 weapons");
            for (var character : characters) {
                require(CharacterKit.forCharacter(character) != null, "character combat kit missing");
                require(weapons.stream().filter(weapon -> weapon.getCharacterId() == character.getId()).count() >= 2,
                        "each character should have at least two related weapons");
                require(new SkillRepository(manager).getSkillsForCharacter(character.getId()).size() == 3,
                        "each playable character should have three abilities");
            }
            require(new SkillRepository(manager).getSkillsForCharacter(
                    new CharacterRepository(manager).getAll().stream()
                            .filter(character -> character.getName().equals("Warden"))
                            .findFirst().orElseThrow().getId()).size() == 3, "expected 3 Warden skills");
            require(new MobRepository(manager).getAll().size() == 6, "expected 6 mobs");
            var arenas = new ArenaRepository(manager).getAll();
            require(arenas.size() == 3, "expected 3 arenas");
            var waves = new WaveRepository(manager);
            var arenaWaves = waves.getWavesForArena(arenas.getFirst().getId());
            require(arenaWaves.size() == 5, "expected 5 waves");
            require(arenaWaves.get(4).isBossWave(), "wave 5 should be the boss wave");
            require(arenaWaves.get(0).getHealthMultiplier() > 0
                    && arenaWaves.get(0).getDamageMultiplier() > 0, "wave multipliers should be positive");
            require(enemyComposition(waves.getEnemiesForWave(arenaWaves.get(0).getId()))
                    .equals(Map.of("Veil Wretch", 5)), "wave 1 composition mismatch");
            require(enemyComposition(waves.getEnemiesForWave(arenaWaves.get(1).getId()))
                    .equals(Map.of("Veil Wretch", 6, "Bone Stalker", 2)), "wave 2 composition mismatch");
            require(enemyComposition(waves.getEnemiesForWave(arenaWaves.get(2).getId()))
                    .equals(Map.of("Veil Wretch", 8, "Bone Stalker", 3)), "wave 3 composition mismatch");
            require(enemyComposition(waves.getEnemiesForWave(arenaWaves.get(3).getId()))
                    .equals(Map.of("Bone Stalker", 4, "Veil Brute", 2)), "wave 4 composition mismatch");
            require(enemyComposition(waves.getEnemiesForWave(arenaWaves.get(4).getId()))
                    .equals(Map.of("Hollow Knight", 1)), "wave 5 composition mismatch");
            int waveEnemyDefinitions = manager.withConnection(connection -> {
                try (var statement = connection.prepareStatement("SELECT COUNT(*) FROM wave_enemies");
                     var result = statement.executeQuery()) {
                    if (!result.next()) {
                        throw new SQLException("Could not count wave enemy definitions");
                    }
                    return result.getInt(1);
                }
            });
            require(waveEnemyDefinitions == 20, "expected 20 wave enemy definitions");
            require(tableCount(manager, "matches") == 0, "match history should initially be empty");
            for (var arena : arenas) {
                var configuredWaves = waves.getWavesForArena(arena.getId());
                require(!configuredWaves.isEmpty(), arena.getName() + " needs waves");
                var finalWave = configuredWaves.getLast();
                require(finalWave.isBossWave(), arena.getName() + " final wave must be marked as a boss wave");
                require(waves.getEnemiesForWave(finalWave.getId()).stream()
                                .anyMatch(enemy -> enemy.getMobId() == arena.getBossMobId()),
                        arena.getName() + " final wave must spawn its configured boss");
            }

            var character = characters.getFirst();
            var weapon = weapons.stream().filter(candidate -> candidate.getCharacterId() == character.getId())
                    .findFirst().orElseThrow();
            var arena = arenas.getFirst();
            var matches = new MatchRepository(manager);
            var reward = matches.completeMatch(new MatchData(0, "WIN", arena.getId(), character.getId(),
                    weapon.getId(), 1, 3, 1, 62.5, null, arena.getName(), character.getName(), weapon.getName()));
            require(reward.experienceEarned() == 135, "reward XP calculation mismatch");
            require(reward.totalExperience() == 135 && reward.level() > 1 && reward.bestWave() == 1,
                    "profile progression was not persisted");
            var saved = matches.getMatchHistory().getFirst();
            require(saved.getArenaName().equals(arena.getName()) && saved.getCharacterName().equals(character.getName())
                            && saved.getWeaponName().equals(weapon.getName()),
                    "saved run should retain selected arena, character, and weapon");
            require(new PlayerRepository(manager).getPlayerProfile().orElseThrow().getBattles() == 1,
                    "profile battle count did not persist");
        }
    }

    private static int tableCount(DatabaseManager manager, String tableName) throws SQLException {
        if (!tableName.matches("[a-z_]+")) {
            throw new IllegalArgumentException("Invalid table name");
        }
        return manager.withConnection(connection -> {
            try (var statement = connection.createStatement();
                 var result = statement.executeQuery("SELECT COUNT(*) FROM " + tableName)) {
                if (!result.next()) {
                    throw new SQLException("Could not count rows in " + tableName);
                }
                return result.getInt(1);
            }
        });
    }

    private static Map<String, Integer> enemyComposition(List<WaveEnemyData> enemies) {
        return enemies.stream().collect(Collectors.toMap(
                WaveEnemyData::getMobName,
                WaveEnemyData::getQuantity));
    }

    private static void require(boolean condition, String message) {
        if (!condition) {
            throw new IllegalStateException(message);
        }
    }
}
