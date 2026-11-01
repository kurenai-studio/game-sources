package com.veilfall.game.database;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;

public final class DatabaseManager implements AutoCloseable {
    private final Path databasePath;
    private Connection connection;

    public DatabaseManager() throws SQLException, IOException {
        this(Path.of("saves", "veilfall.db"));
    }

    public DatabaseManager(Path databasePath) throws SQLException, IOException {
        this.databasePath = databasePath.toAbsolutePath().normalize();
        Path parent = this.databasePath.getParent();
        if (parent != null) {
            Files.createDirectories(parent);
        }
        connection = DriverManager.getConnection("jdbc:sqlite:" + this.databasePath);
        try (Statement statement = connection.createStatement()) {
            statement.execute("PRAGMA foreign_keys = ON");
        } catch (SQLException exception) {
            connection.close();
            connection = null;
            throw exception;
        }
    }

    public Path getDatabasePath() {
        return databasePath;
    }

    public synchronized <T> T withConnection(SqlOperation<T> operation) throws SQLException {
        if (connection == null || connection.isClosed()) {
            throw new SQLException("Database connection is closed");
        }
        return operation.execute(connection);
    }

    @Override
    public synchronized void close() throws SQLException {
        if (connection != null) {
            connection.close();
            connection = null;
        }
    }

    @FunctionalInterface
    public interface SqlOperation<T> {
        T execute(Connection connection) throws SQLException;
    }
}
