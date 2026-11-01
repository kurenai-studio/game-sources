package com.veilfall.game.database;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Objects;

public final class DatabaseInitializer {
    private final DatabaseManager databaseManager;

    public DatabaseInitializer(DatabaseManager databaseManager) {
        this.databaseManager = Objects.requireNonNull(databaseManager);
    }

    public void initialize() throws SQLException, IOException {
        String schema;
        try (InputStream input = DatabaseInitializer.class.getClassLoader()
                .getResourceAsStream("database/schema.sql")) {
            if (input == null) {
                throw new IOException("Missing database/schema.sql on the application classpath");
            }
            schema = new String(input.readAllBytes(), StandardCharsets.UTF_8);
        }

        databaseManager.withConnection(connection -> {
            boolean previousAutoCommit = connection.getAutoCommit();
            connection.setAutoCommit(false);
            try {
                for (String sql : schema.split(";")) {
                    if (!sql.isBlank()) {
                        try (Statement statement = connection.createStatement()) {
                            statement.execute(sql);
                        }
                    }
                }
                migrateWeaponChoices(connection);
                migrateMatchWeapon(connection);
                seedDefaults(connection);
                connection.commit();
            } catch (SQLException | RuntimeException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(previousAutoCommit);
            }
            return null;
        });
    }

    private static void seedDefaults(Connection connection) throws SQLException {
        execute(connection, """
                INSERT OR IGNORE INTO player_profile
                    (id, name, level, experience, wins, losses, battles, enemies_defeated, bosses_defeated, best_wave)
                VALUES (1, ?, 1, 0, 0, 0, 0, 0, 0, 0)
                """, "Wanderer");

        insertCharacter(connection, "Warden", 150, 18, 2.5, 15, 1.5);
        insertCharacter(connection, "Veil Archer", 90, 25, 3.2, 5, 8.0);
        insertCharacter(connection, "Ash Mage", 80, 30, 2.7, 4, 7.0);

        insertWeapon(connection, "Rusted Sword", "Warden", 18, 1.2, 1.5);
        insertWeapon(connection, "Gravebreaker Maul", "Warden", 29, 0.72, 2.1);
        insertWeapon(connection, "Veil Bow", "Veil Archer", 25, 1.0, 8.0);
        insertWeapon(connection, "Longshot Recurve", "Veil Archer", 17, 1.55, 11.5);
        insertWeapon(connection, "Ash Staff", "Ash Mage", 30, 0.8, 7.0);
        insertWeapon(connection, "Ember Rod", "Ash Mage", 19, 1.35, 8.5);

        insertSkill(connection, "Warden", "Shield Bash", "Q", 25, 4);
        insertSkill(connection, "Warden", "Ground Slam", "E", 35, 7);
        insertSkill(connection, "Warden", "Veil Guard", "R", 0, 15);
        insertSkill(connection, "Veil Archer", "Piercing Shot", "Q", 42, 4);
        insertSkill(connection, "Veil Archer", "Arrow Volley", "E", 24, 7);
        insertSkill(connection, "Veil Archer", "Veilstep", "R", 0, 12);
        insertSkill(connection, "Ash Mage", "Arcane Lance", "Q", 48, 4);
        insertSkill(connection, "Ash Mage", "Veil Nova", "E", 32, 7);
        insertSkill(connection, "Ash Mage", "Aether Ward", "R", 0, 15);

        insertMob(connection, "Veil Wretch", "UNDEAD", 60, 8, 2.0, 1.2, false);
        insertMob(connection, "Bone Stalker", "UNDEAD", 100, 14, 1.7, 1.3, false);
        insertMob(connection, "Veil Brute", "ELITE", 300, 25, 1.2, 1.5, false);
        insertMob(connection, "Hollow Knight", "BOSS", 2500, 40, 1.5, 2.0, true);
        insertMob(connection, "Cinder Abomination", "BOSS_NOVA", 1900, 32, 1.25, 2.2, true);
        insertMob(connection, "Tide Matriarch", "BOSS_SURGE", 2850, 36, 1.1, 2.5, true);

        int bossMobId = getId(connection, "mobs", "Hollow Knight");
        execute(connection, """
                INSERT OR IGNORE INTO arenas (name, description, difficulty, environment, boss_mob_id)
                VALUES (?, ?, ?, ?, ?)
                """, "Mistwood", "A forgotten forest consumed by rain and Veil corruption.",
                1, "RAIN_FOREST", bossMobId);

        int arenaId = getId(connection, "arenas", "Mistwood");
        insertWave(connection, arenaId, 1, 1.0, 1.0, false);
        insertWave(connection, arenaId, 2, 1.1, 1.05, false);
        insertWave(connection, arenaId, 3, 1.2, 1.1, false);
        insertWave(connection, arenaId, 4, 1.35, 1.2, false);
        insertWave(connection, arenaId, 5, 1.5, 1.35, true);

        insertWaveEnemy(connection, arenaId, 1, "Veil Wretch", 5);
        insertWaveEnemy(connection, arenaId, 2, "Veil Wretch", 6);
        insertWaveEnemy(connection, arenaId, 2, "Bone Stalker", 2);
        insertWaveEnemy(connection, arenaId, 3, "Veil Wretch", 8);
        insertWaveEnemy(connection, arenaId, 3, "Bone Stalker", 3);
        insertWaveEnemy(connection, arenaId, 4, "Bone Stalker", 4);
        insertWaveEnemy(connection, arenaId, 4, "Veil Brute", 2);
        insertWaveEnemy(connection, arenaId, 5, "Hollow Knight", 1);

        int ashArenaId = seedArena(connection, "Ashen Reach",
                "A scorched battlefield where the Veil leaks through the old kiln.",
                2, "ASHEN", "Cinder Abomination");
        seedArenaWaves(connection, ashArenaId, new String[][]{
                {"Veil Wretch:6"},
                {"Veil Wretch:4", "Bone Stalker:3"},
                {"Bone Stalker:4", "Veil Brute:2"},
                {"Cinder Abomination:1"}
        });

        int chapelArenaId = seedArena(connection, "Sunken Chapel",
                "A drowned sanctuary guarded by an ancient tide spirit.",
                3, "DROWNED", "Tide Matriarch");
        seedArenaWaves(connection, chapelArenaId, new String[][]{
                {"Bone Stalker:5"},
                {"Veil Wretch:4", "Bone Stalker:3"},
                {"Bone Stalker:3", "Veil Brute:3"},
                {"Tide Matriarch:1"}
        });
    }

    private static int seedArena(Connection connection, String name, String description, int difficulty,
                                 String environment, String bossName) throws SQLException {
        execute(connection, """
                INSERT OR IGNORE INTO arenas (name, description, difficulty, environment, boss_mob_id)
                VALUES (?, ?, ?, ?, ?)
                """, name, description, difficulty, environment, getId(connection, "mobs", bossName));
        return getId(connection, "arenas", name);
    }

    private static void seedArenaWaves(Connection connection, int arenaId, String[][] waves) throws SQLException {
        for (int index = 0; index < waves.length; index++) {
            int waveNumber = index + 1;
            boolean bossWave = waveNumber == waves.length;
            insertWave(connection, arenaId, waveNumber, 1.0 + index * 0.12,
                    1.0 + index * 0.08, bossWave);
            for (String entry : waves[index]) {
                String[] parts = entry.split(":");
                insertWaveEnemy(connection, arenaId, waveNumber, parts[0], Integer.parseInt(parts[1]));
            }
        }
    }

    private static void migrateWeaponChoices(Connection connection) throws SQLException {
        String createSql;
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = 'weapons'");
             ResultSet result = statement.executeQuery()) {
            if (!result.next()) return;
            createSql = result.getString(1);
        }
        if (createSql == null || !createSql.toLowerCase().matches("(?s).*character_id\\s+integer\\s+not\\s+null\\s+unique.*")) {
            return;
        }
        try (Statement statement = connection.createStatement()) {
            statement.execute("""
                    CREATE TABLE weapons_replacement (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        name TEXT NOT NULL UNIQUE,
                        character_id INTEGER NOT NULL,
                        damage INTEGER NOT NULL CHECK (damage >= 0),
                        attack_speed REAL NOT NULL CHECK (attack_speed > 0),
                        attack_range REAL NOT NULL CHECK (attack_range > 0),
                        FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE
                    )
                    """);
            statement.execute("INSERT INTO weapons_replacement SELECT * FROM weapons");
            statement.execute("DROP TABLE weapons");
            statement.execute("ALTER TABLE weapons_replacement RENAME TO weapons");
        }
    }

    private static void migrateMatchWeapon(Connection connection) throws SQLException {
        boolean hasWeaponId = false;
        try (Statement statement = connection.createStatement();
             ResultSet columns = statement.executeQuery("PRAGMA table_info(matches)")) {
            while (columns.next()) {
                if ("weapon_id".equalsIgnoreCase(columns.getString("name"))) {
                    hasWeaponId = true;
                    break;
                }
            }
        }
        if (!hasWeaponId) {
            try (Statement statement = connection.createStatement()) {
                statement.execute("ALTER TABLE matches ADD COLUMN weapon_id INTEGER REFERENCES weapons(id)");
            }
        }
    }

    private static void insertCharacter(Connection connection, String name, int hp, int attack,
                                        double speed, int defense, double range) throws SQLException {
        execute(connection, """
                INSERT OR IGNORE INTO characters (name, hp, attack, speed, defense, attack_range)
                VALUES (?, ?, ?, ?, ?, ?)
                """, name, hp, attack, speed, defense, range);
    }

    private static void insertWeapon(Connection connection, String name, String characterName, int damage,
                                     double attackSpeed, double range) throws SQLException {
        execute(connection, """
                INSERT OR IGNORE INTO weapons (name, character_id, damage, attack_speed, attack_range)
                VALUES (?, ?, ?, ?, ?)
                """, name, getId(connection, "characters", characterName), damage, attackSpeed, range);
    }

    private static void insertSkill(Connection connection, String characterName, String name, String key,
                                    int damage, double cooldown) throws SQLException {
        execute(connection, """
                INSERT OR IGNORE INTO skills (character_id, name, key_binding, damage, cooldown)
                VALUES (?, ?, ?, ?, ?)
                """, getId(connection, "characters", characterName), name, key, damage, cooldown);
    }

    private static void insertMob(Connection connection, String name, String type, int hp, int damage,
                                  double speed, double range, boolean boss) throws SQLException {
        execute(connection, """
                INSERT OR IGNORE INTO mobs (name, type, hp, damage, speed, attack_range, is_boss)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """, name, type, hp, damage, speed, range, boss);
    }

    private static void insertWave(Connection connection, int arenaId, int number, double healthMultiplier,
                                   double damageMultiplier, boolean bossWave) throws SQLException {
        execute(connection, """
                INSERT OR IGNORE INTO waves
                    (arena_id, wave_number, health_multiplier, damage_multiplier, boss_wave)
                VALUES (?, ?, ?, ?, ?)
                """, arenaId, number, healthMultiplier, damageMultiplier, bossWave);
    }

    private static void insertWaveEnemy(Connection connection, int arenaId, int waveNumber,
                                        String mobName, int quantity) throws SQLException {
        int waveId;
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT id FROM waves WHERE arena_id = ? AND wave_number = ?")) {
            statement.setInt(1, arenaId);
            statement.setInt(2, waveNumber);
            try (ResultSet result = statement.executeQuery()) {
                if (!result.next()) {
                    throw new SQLException("Missing seeded wave " + waveNumber);
                }
                waveId = result.getInt("id");
            }
        }
        execute(connection, """
                INSERT OR IGNORE INTO wave_enemies (wave_id, mob_id, quantity)
                VALUES (?, ?, ?)
                """, waveId, getId(connection, "mobs", mobName), quantity);
    }

    private static int getId(Connection connection, String table, String name) throws SQLException {
        if (!table.equals("mobs") && !table.equals("arenas") && !table.equals("characters")) {
            throw new SQLException("Unsupported seed lookup table: " + table);
        }
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT id FROM " + table + " WHERE name = ?")) {
            statement.setString(1, name);
            try (ResultSet result = statement.executeQuery()) {
                if (!result.next()) {
                    throw new SQLException("Missing seeded " + table + " record: " + name);
                }
                return result.getInt("id");
            }
        }
    }

    private static void execute(Connection connection, String sql, Object... values) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            for (int index = 0; index < values.length; index++) {
                statement.setObject(index + 1, values[index]);
            }
            statement.executeUpdate();
        }
    }
}
