package com.veilfall.game.database.repository;

import com.veilfall.game.data.PlayerData;
import com.veilfall.game.database.DatabaseManager;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Optional;
import java.util.Objects;

public final class PlayerRepository {
    private final DatabaseManager databaseManager;

    public PlayerRepository(DatabaseManager databaseManager) {
        this.databaseManager = Objects.requireNonNull(databaseManager);
    }

    public Optional<PlayerData> getPlayerProfile() throws SQLException {
        return databaseManager.withConnection(connection -> {
            try (PreparedStatement statement = connection.prepareStatement(
                    "SELECT * FROM player_profile WHERE id = 1");
                 ResultSet result = statement.executeQuery()) {
                return result.next() ? Optional.of(map(result)) : Optional.empty();
            }
        });
    }

    public void updateProfile(PlayerData player) throws SQLException {
        Objects.requireNonNull(player);
        databaseManager.withConnection(connection -> {
            try (PreparedStatement statement = connection.prepareStatement("""
                    UPDATE player_profile
                    SET name = ?, level = ?, experience = ?, wins = ?, losses = ?, battles = ?,
                        enemies_defeated = ?, bosses_defeated = ?, best_wave = ?
                    WHERE id = ?
                    """)) {
                statement.setString(1, player.getName());
                statement.setInt(2, player.getLevel());
                statement.setInt(3, player.getExperience());
                statement.setInt(4, player.getWins());
                statement.setInt(5, player.getLosses());
                statement.setInt(6, player.getBattles());
                statement.setInt(7, player.getEnemiesDefeated());
                statement.setInt(8, player.getBossesDefeated());
                statement.setInt(9, player.getBestWave());
                statement.setInt(10, player.getId());
                if (statement.executeUpdate() != 1) {
                    throw new SQLException("Player profile does not exist: " + player.getId());
                }
            }
            return null;
        });
    }

    private static PlayerData map(ResultSet result) throws SQLException {
        return new PlayerData(result.getInt("id"), result.getString("name"), result.getInt("level"),
                result.getInt("experience"), result.getInt("wins"), result.getInt("losses"),
                result.getInt("battles"), result.getInt("enemies_defeated"),
                result.getInt("bosses_defeated"), result.getInt("best_wave"));
    }
}
