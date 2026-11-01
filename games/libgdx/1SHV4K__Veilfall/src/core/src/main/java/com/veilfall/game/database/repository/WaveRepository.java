package com.veilfall.game.database.repository;

import com.veilfall.game.data.WaveData;
import com.veilfall.game.data.WaveEnemyData;
import com.veilfall.game.database.DatabaseManager;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public final class WaveRepository {
    private final DatabaseManager databaseManager;

    public WaveRepository(DatabaseManager databaseManager) {
        this.databaseManager = Objects.requireNonNull(databaseManager);
    }

    public List<WaveData> getWavesForArena(int arenaId) throws SQLException {
        return databaseManager.withConnection(connection -> {
            List<WaveData> waves = new ArrayList<>();
            try (PreparedStatement statement = connection.prepareStatement(
                    "SELECT * FROM waves WHERE arena_id = ? ORDER BY wave_number")) {
                statement.setInt(1, arenaId);
                try (ResultSet result = statement.executeQuery()) {
                    while (result.next()) {
                        waves.add(new WaveData(result.getInt("id"), result.getInt("arena_id"),
                                result.getInt("wave_number"), result.getDouble("health_multiplier"),
                                result.getDouble("damage_multiplier"), result.getInt("boss_wave") != 0));
                    }
                }
            }
            return waves;
        });
    }

    public List<WaveEnemyData> getEnemiesForWave(int waveId) throws SQLException {
        return databaseManager.withConnection(connection -> {
            List<WaveEnemyData> enemies = new ArrayList<>();
            try (PreparedStatement statement = connection.prepareStatement("""
                    SELECT we.wave_id, we.mob_id, m.name AS mob_name, we.quantity
                    FROM wave_enemies we
                    JOIN mobs m ON m.id = we.mob_id
                    WHERE we.wave_id = ?
                    ORDER BY m.id
                    """)) {
                statement.setInt(1, waveId);
                try (ResultSet result = statement.executeQuery()) {
                    while (result.next()) {
                        enemies.add(new WaveEnemyData(result.getInt("wave_id"), result.getInt("mob_id"),
                                result.getString("mob_name"), result.getInt("quantity")));
                    }
                }
            }
            return enemies;
        });
    }
}
