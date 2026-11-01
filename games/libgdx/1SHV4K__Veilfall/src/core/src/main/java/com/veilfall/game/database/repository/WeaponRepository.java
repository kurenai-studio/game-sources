package com.veilfall.game.database.repository;

import com.veilfall.game.data.WeaponData;
import com.veilfall.game.database.DatabaseManager;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

public final class WeaponRepository {
    private final DatabaseManager databaseManager;

    public WeaponRepository(DatabaseManager databaseManager) {
        this.databaseManager = Objects.requireNonNull(databaseManager);
    }

    public Optional<WeaponData> getById(int id) throws SQLException {
        return databaseManager.withConnection(connection -> {
            try (PreparedStatement statement = connection.prepareStatement("SELECT * FROM weapons WHERE id = ?")) {
                statement.setInt(1, id);
                try (ResultSet result = statement.executeQuery()) {
                    return result.next() ? Optional.of(map(result)) : Optional.empty();
                }
            }
        });
    }

    public List<WeaponData> getAll() throws SQLException {
        return databaseManager.withConnection(connection -> {
            List<WeaponData> weapons = new ArrayList<>();
            try (PreparedStatement statement = connection.prepareStatement("SELECT * FROM weapons ORDER BY id");
                 ResultSet result = statement.executeQuery()) {
                while (result.next()) {
                    weapons.add(map(result));
                }
            }
            return weapons;
        });
    }

    private static WeaponData map(ResultSet result) throws SQLException {
        return new WeaponData(result.getInt("id"), result.getString("name"), result.getInt("character_id"),
                result.getInt("damage"), result.getDouble("attack_speed"), result.getDouble("attack_range"));
    }
}
