package com.veilfall.game.database.repository;

import com.veilfall.game.data.CharacterData;
import com.veilfall.game.database.DatabaseManager;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

public final class CharacterRepository {
    private final DatabaseManager databaseManager;

    public CharacterRepository(DatabaseManager databaseManager) {
        this.databaseManager = Objects.requireNonNull(databaseManager);
    }

    public Optional<CharacterData> getById(int id) throws SQLException {
        return databaseManager.withConnection(connection -> {
            try (PreparedStatement statement = connection.prepareStatement("SELECT * FROM characters WHERE id = ?")) {
                statement.setInt(1, id);
                try (ResultSet result = statement.executeQuery()) {
                    return result.next() ? Optional.of(map(result)) : Optional.empty();
                }
            }
        });
    }

    public List<CharacterData> getAll() throws SQLException {
        return databaseManager.withConnection(connection -> {
            List<CharacterData> characters = new ArrayList<>();
            try (PreparedStatement statement = connection.prepareStatement("SELECT * FROM characters ORDER BY id");
                 ResultSet result = statement.executeQuery()) {
                while (result.next()) {
                    characters.add(map(result));
                }
            }
            return characters;
        });
    }

    private static CharacterData map(ResultSet result) throws SQLException {
        return new CharacterData(result.getInt("id"), result.getString("name"), result.getInt("hp"),
                result.getInt("attack"), result.getDouble("speed"), result.getInt("defense"),
                result.getDouble("attack_range"));
    }
}
