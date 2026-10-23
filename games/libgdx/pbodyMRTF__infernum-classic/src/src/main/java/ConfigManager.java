

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.files.FileHandle;
import com.badlogic.gdx.utils.Json;


public class ConfigManager {
    public static void saveConfig(GameConfig config) {
        Json json = new Json();
        String jsonText = json.prettyPrint(config);
        FileHandle file = Gdx.files.local("config.json");
        file.writeString(jsonText, false);
    }

    public static GameConfig loadConfig() {
        Json json = new Json();
        FileHandle file = Gdx.files.local("config.json");
        if (file.exists()) {
            return (GameConfig) json.fromJson(GameConfig.class, file);
        }
        return (GameConfig) json.fromJson(GameConfig.class, Gdx.files.internal("config.json"));
    }
}
