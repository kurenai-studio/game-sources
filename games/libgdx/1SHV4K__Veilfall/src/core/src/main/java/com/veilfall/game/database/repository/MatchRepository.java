package com.veilfall.game.database.repository;

import com.veilfall.game.data.MatchData;
import com.veilfall.game.data.ProgressionReward;
import com.veilfall.game.database.DatabaseManager;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public final class MatchRepository {
    private final DatabaseManager databaseManager;

    public MatchRepository(DatabaseManager databaseManager) {
        this.databaseManager = Objects.requireNonNull(databaseManager);
    }

    /** Stores a finished run and its profile reward in one transaction. */
    public ProgressionReward completeMatch(MatchData match) throws SQLException {
        Objects.requireNonNull(match);
        return databaseManager.withConnection(connection -> {
            boolean autoCommit = connection.getAutoCommit();
            connection.setAutoCommit(false);
            try {
                try (PreparedStatement statement = connection.prepareStatement("""
                        INSERT INTO matches
                            (result, arena_id, character_id, weapon_id, waves_reached, enemies_defeated,
                             bosses_defeated, duration_seconds)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                        """)) {
                    statement.setString(1, match.getResult());
                    statement.setInt(2, match.getArenaId());
                    statement.setInt(3, match.getCharacterId());
                    setWeaponId(statement, 4, match.getWeaponId());
                    statement.setInt(5, match.getWavesReached());
                    statement.setInt(6, match.getEnemiesDefeated());
                    statement.setInt(7, match.getBossesDefeated());
                    statement.setDouble(8, match.getDurationSeconds());
                    statement.executeUpdate();
                }
                int reward = (match.getResult().equals("WIN") ? 50 : 15)
                        + match.getWavesReached() * 20 + match.getEnemiesDefeated() * 5
                        + match.getBossesDefeated() * 50;
                try (PreparedStatement statement = connection.prepareStatement("""
                        UPDATE player_profile SET
                            experience = experience + ?,
                            wins = wins + CASE WHEN ? = 'WIN' THEN 1 ELSE 0 END,
                            losses = losses + CASE WHEN ? = 'LOSS' THEN 1 ELSE 0 END,
                            battles = battles + 1,
                            enemies_defeated = enemies_defeated + ?,
                            bosses_defeated = bosses_defeated + ?,
                            best_wave = MAX(best_wave, ?)
                        WHERE id = 1
                        """)) {
                    statement.setInt(1, reward);
                    statement.setString(2, match.getResult());
                    statement.setString(3, match.getResult());
                    statement.setInt(4, match.getEnemiesDefeated());
                    statement.setInt(5, match.getBossesDefeated());
                    statement.setInt(6, match.getWavesReached());
                    if (statement.executeUpdate() != 1) throw new SQLException("Player profile is missing");
                }
                int totalExperience;
                try (PreparedStatement statement = connection.prepareStatement(
                        "SELECT experience FROM player_profile WHERE id = 1");
                     ResultSet result = statement.executeQuery()) {
                    if (!result.next()) throw new SQLException("Player profile is missing");
                    totalExperience = result.getInt(1);
                }
                int level = 1 + (int) Math.floor(Math.sqrt(totalExperience / 50.0));
                try (PreparedStatement statement = connection.prepareStatement(
                        "UPDATE player_profile SET level = ? WHERE id = 1")) {
                    statement.setInt(1, level);
                    statement.executeUpdate();
                }
                ProgressionReward progression;
                try (PreparedStatement statement = connection.prepareStatement(
                        "SELECT experience, level, best_wave FROM player_profile WHERE id = 1");
                     ResultSet result = statement.executeQuery()) {
                    if (!result.next()) throw new SQLException("Player profile is missing");
                    progression = new ProgressionReward(reward, result.getInt("experience"),
                            result.getInt("level"), result.getInt("best_wave"));
                }
                connection.commit();
                return progression;
            } catch (SQLException | RuntimeException exception) {
                connection.rollback();
                throw exception;
            } finally {
                connection.setAutoCommit(autoCommit);
            }
        });
    }

    /** Kept for migration tools and tests that need a raw history row without awarding progression. */
    public int insertMatch(MatchData match) throws SQLException {
        Objects.requireNonNull(match);
        return databaseManager.withConnection(connection -> {
            try (PreparedStatement statement = connection.prepareStatement("""
                    INSERT INTO matches
                        (result, arena_id, character_id, weapon_id, waves_reached, enemies_defeated,
                         bosses_defeated, duration_seconds)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """, Statement.RETURN_GENERATED_KEYS)) {
                statement.setString(1, match.getResult());
                statement.setInt(2, match.getArenaId());
                statement.setInt(3, match.getCharacterId());
                setWeaponId(statement, 4, match.getWeaponId());
                statement.setInt(5, match.getWavesReached());
                statement.setInt(6, match.getEnemiesDefeated());
                statement.setInt(7, match.getBossesDefeated());
                statement.setDouble(8, match.getDurationSeconds());
                statement.executeUpdate();
            }
            try (PreparedStatement statement = connection.prepareStatement("SELECT last_insert_rowid()");
                 ResultSet result = statement.executeQuery()) {
                if (!result.next()) throw new SQLException("SQLite did not return the inserted match ID");
                return result.getInt(1);
            }
        });
    }

    public List<MatchData> getMatchHistory() throws SQLException {
        return databaseManager.withConnection(connection -> {
            List<MatchData> matches = new ArrayList<>();
            try (PreparedStatement statement = connection.prepareStatement("""
                    SELECT m.*, a.name AS arena_name, c.name AS character_name, w.name AS weapon_name
                    FROM matches m
                    JOIN arenas a ON a.id = m.arena_id
                    JOIN characters c ON c.id = m.character_id
                    LEFT JOIN weapons w ON w.id = m.weapon_id
                    ORDER BY m.id DESC LIMIT 30
                    """); ResultSet result = statement.executeQuery()) {
                while (result.next()) matches.add(map(result));
            }
            return matches;
        });
    }

    public int countWins() throws SQLException { return countByResult("WIN"); }
    public int countLosses() throws SQLException { return countByResult("LOSS"); }

    private int countByResult(String resultValue) throws SQLException {
        return databaseManager.withConnection(connection -> {
            try (PreparedStatement statement = connection.prepareStatement("SELECT COUNT(*) FROM matches WHERE result = ?")) {
                statement.setString(1, resultValue);
                try (ResultSet result = statement.executeQuery()) {
                    if (!result.next()) throw new SQLException("Could not count matches");
                    return result.getInt(1);
                }
            }
        });
    }

    private static MatchData map(ResultSet result) throws SQLException {
        return new MatchData(result.getInt("id"), result.getString("result"), result.getInt("arena_id"),
                result.getInt("character_id"), result.getInt("weapon_id"), result.getInt("waves_reached"),
                result.getInt("enemies_defeated"), result.getInt("bosses_defeated"),
                result.getDouble("duration_seconds"), result.getString("played_at"),
                result.getString("arena_name"), result.getString("character_name"),
                Objects.requireNonNullElse(result.getString("weapon_name"), "Legacy loadout"));
    }

    private static void setWeaponId(PreparedStatement statement, int index, int weaponId) throws SQLException {
        if (weaponId > 0) statement.setInt(index, weaponId);
        else statement.setNull(index, java.sql.Types.INTEGER);
    }
}
