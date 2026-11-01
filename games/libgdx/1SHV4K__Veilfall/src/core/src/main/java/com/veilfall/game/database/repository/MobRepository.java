package com.veilfall.game.database.repository;

import com.veilfall.game.data.MobData;
import com.veilfall.game.database.DatabaseManager;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

public final class MobRepository {
    private final DatabaseManager databaseManager;

    public MobRepository(DatabaseManager databaseManager) {
        this.databaseManager = Objects.requireNonNull(databaseManager);
    }

    public Optional<MobData> getById(int id) throws SQLException {
        return databaseManager.withConnection(connection -> {
            try (PreparedStatement statement = connection.prepareStatement("SELECT * FROM mobs WHERE id = ?")) {
                statement.setInt(1, id);
                try (ResultSet result = statement.executeQuery()) {
                    return result.next() ? Optional.of(map(result)) : Optional.empty();
                }
            }
        });
    }

    public List<MobData> getAll() throws SQLException {
        return databaseManager.withConnection(connection -> {
            List<MobData> mobs = new ArrayList<>();
            try (PreparedStatement statement = connection.prepareStatement("SELECT * FROM mobs ORDER BY id");
                 ResultSet result = statement.executeQuery()) {
                while (result.next()) {
                    mobs.add(map(result));
                }
            }
            return mobs;
        });
    }

    private static MobData map(ResultSet result) throws SQLException {
        return new MobData(result.getInt("id"), result.getString("name"), result.getString("type"),
                result.getInt("hp"), result.getInt("damage"), result.getDouble("speed"),
                result.getDouble("attack_range"), result.getInt("is_boss") != 0);
    }
}
