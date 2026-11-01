package com.veilfall.game.database.repository;

import com.veilfall.game.data.ArenaData;
import com.veilfall.game.database.DatabaseManager;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

public final class ArenaRepository {
    private final DatabaseManager databaseManager;

    public ArenaRepository(DatabaseManager databaseManager) {
        this.databaseManager = Objects.requireNonNull(databaseManager);
    }

    public Optional<ArenaData> getById(int id) throws SQLException {
        return databaseManager.withConnection(connection -> {
            try (PreparedStatement statement = connection.prepareStatement("SELECT * FROM arenas WHERE id = ?")) {
                statement.setInt(1, id);
                try (ResultSet result = statement.executeQuery()) {
                    return result.next() ? Optional.of(map(result)) : Optional.empty();
                }
            }
        });
    }

    public List<ArenaData> getAll() throws SQLException {
        return databaseManager.withConnection(connection -> {
            List<ArenaData> arenas = new ArrayList<>();
            try (PreparedStatement statement = connection.prepareStatement("SELECT * FROM arenas ORDER BY id");
                 ResultSet result = statement.executeQuery()) {
                while (result.next()) {
                    arenas.add(map(result));
                }
            }
            return arenas;
        });
    }

    private static ArenaData map(ResultSet result) throws SQLException {
        return new ArenaData(result.getInt("id"), result.getString("name"), result.getString("description"),
                result.getInt("difficulty"), result.getString("environment"), result.getInt("boss_mob_id"));
    }
}
