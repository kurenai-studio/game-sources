package com.veilfall.game.database.repository;

import com.veilfall.game.data.SkillData;
import com.veilfall.game.database.DatabaseManager;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public final class SkillRepository {
    private final DatabaseManager databaseManager;

    public SkillRepository(DatabaseManager databaseManager) {
        this.databaseManager = Objects.requireNonNull(databaseManager);
    }

    public List<SkillData> getSkillsForCharacter(int characterId) throws SQLException {
        return databaseManager.withConnection(connection -> {
            List<SkillData> skills = new ArrayList<>();
            try (PreparedStatement statement = connection.prepareStatement(
                    "SELECT * FROM skills WHERE character_id = ? ORDER BY id")) {
                statement.setInt(1, characterId);
                try (ResultSet result = statement.executeQuery()) {
                    while (result.next()) {
                        skills.add(new SkillData(result.getInt("id"), result.getInt("character_id"),
                                result.getString("name"), result.getString("key_binding"),
                                result.getInt("damage"), result.getDouble("cooldown")));
                    }
                }
            }
            return skills;
        });
    }
}
