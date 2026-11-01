package dev.meowpow.boxbot.config;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.utils.JsonReader;

/**
 * Loads and owns the game's {@link BoxbotConfig}.
 */
public final class ConfigLoader {

    private static final String CONFIG_PATH = "config/boxbot.json";

    private BoxbotConfig config;

    /**
     * Loads the config from disk.
     */
    public ConfigLoader() {
        load();
    }

    /**
     * Reloads the config from disk,
     * replacing whatever was previously loaded.
     */
    public void reload() {
        load();
    }

    /**
     * Returns the loaded config.
     */
    public BoxbotConfig config() {
        return config;
    }

    private void load() {
        var file = Gdx.files.internal(CONFIG_PATH);
        if (!file.exists()) {
            throw new IllegalStateException("Config file not found: " + CONFIG_PATH);
        }
        try {
            config = ConfigParser.parse(new JsonReader().parse(file));
        }
        catch (RuntimeException e) {
            var message = "Failed to load config from " + CONFIG_PATH;
            throw new IllegalStateException(message, e);
        }
    }
}
