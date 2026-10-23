package DarkShark02.JustJump;

import java.util.ArrayList;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.files.FileHandle;
import com.badlogic.gdx.utils.JsonReader;
import com.badlogic.gdx.utils.JsonValue;

public class LevelManager {
    private int currentLevelIndex;
    private final ArrayList<LevelData> levels;
    private final JustJumpGame game;
    private final JsonReader jsonReader;

    public LevelManager(JustJumpGame game) {
        this.game = game;
        this.currentLevelIndex = 0;
        this.levels = new ArrayList<>();
        this.jsonReader = new JsonReader();
        loadAllLevelData();
    }

    private void loadAllLevelData() {
        int levelNum = 1;
        while (true) {
            String fileName = "level" + levelNum + ".json";
            FileHandle levelFile = Gdx.files.internal(fileName);

            if (!levelFile.exists()) {
                Gdx.app.log("LevelManager", "Nessun altro file di livello trovato: " + fileName);
                break;
            }

            try {
                JsonValue root = jsonReader.parse(levelFile);
                Gdx.app.log("LevelManager", "Caricato " + fileName + " con successo usando LibGDX JSON.");

                LevelData levelData = new LevelData();
                levelData.backgroundType = root.getInt("backgroundType");
                levelData.playerStartX = root.getFloat("playerStartX");
                levelData.playerStartY = root.getFloat("playerStartY");
                levelData.exitX = root.getFloat("exitX");
                // Leggi la nuova proprietà levelWidth
                levelData.levelWidth = root.getFloat("levelWidth", JustJumpGame.SCREEN_WIDTH); // Default alla SCREEN_WIDTH se non presente
                
                // ... (il resto del codice per leggere spikes, hearts, stars, bees, snowPatches, springs)
                // Questo blocco rimane invariato rispetto al tuo codice:

                JsonValue spikesArray = root.get("spikes");
                if (spikesArray != null && spikesArray.isArray()) {
                    for (JsonValue spikeJson : spikesArray) {
                        levelData.spikes.add(new LevelData.SpikeData(spikeJson.getFloat("x"), spikeJson.getFloat("y")));
                    }
                }

                JsonValue heartsArray = root.get("hearts");
                if (heartsArray != null && heartsArray.isArray()) {
                    for (JsonValue heartJson : heartsArray) {
                        levelData.hearts.add(new LevelData.HeartData(heartJson.getFloat("x"), heartJson.getFloat("y")));
                    }
                }

                JsonValue starsArray = root.get("stars");
                if (starsArray != null && starsArray.isArray()) {
                    for (JsonValue starJson : starsArray) {
                        levelData.stars.add(new LevelData.StarData(starJson.getFloat("x"), starJson.getFloat("y")));
                    }
                }

                JsonValue beesArray = root.get("bees");
                if (beesArray != null && beesArray.isArray()) {
                    for (JsonValue beeJson : beesArray) {
                        levelData.bees.add(new LevelData.BeeData(
                            beeJson.getFloat("x"),
                            beeJson.getFloat("y"),
                            beeJson.getFloat("initialVelocityX")
                        ));
                    }
                }

                JsonValue snowPatchesArray = root.get("snowPatches");
                if (snowPatchesArray != null && snowPatchesArray.isArray()) {
                    for (JsonValue snowPatchJson : snowPatchesArray) {
                        levelData.snowPatches.add(new LevelData.SnowPatchData(
                            snowPatchJson.getFloat("x"),
                            snowPatchJson.getFloat("y"),
                            snowPatchJson.getFloat("width"),
                            snowPatchJson.getFloat("height")
                        ));
                    }
                }

                JsonValue springsArray = root.get("springs");
                if (springsArray != null && springsArray.isArray()) {
                    for (JsonValue springJson : springsArray) {
                        levelData.springs.add(new LevelData.SpringData(springJson.getFloat("x"), springJson.getFloat("y")));
                    }
                }
                
                levels.add(levelData);
                Gdx.app.log("LevelManager", "Caricato " + fileName + " con successo usando LibGDX JSON.");

            } catch (Exception e) {
                Gdx.app.error("LevelManager", "Errore durante il caricamento o parsing di " + fileName + ": " + e.getMessage(), e);
            }
            levelNum++;
        }

        if (levels.isEmpty()) {
            Gdx.app.error("LevelManager", "Nessun livello caricato dai file. Caricamento livello di default.");
            levels.add(createDefaultLevelData());
        }
    }

    private LevelData createDefaultLevelData() {
        LevelData defaultLevel = new LevelData();
        defaultLevel.backgroundType = 0; // Erba
        defaultLevel.playerStartX = 100;
        defaultLevel.playerStartY = JustJumpGame.GROUND_Y;
        defaultLevel.spikes.add(new LevelData.SpikeData(700, JustJumpGame.GROUND_Y));
        defaultLevel.hearts.add(new LevelData.HeartData(400, JustJumpGame.GROUND_Y));
        defaultLevel.bees.add(new LevelData.BeeData(JustJumpGame.SCREEN_WIDTH + 60, JustJumpGame.GROUND_Y + 150, -150));
        defaultLevel.exitX = 1500;
        defaultLevel.levelWidth = JustJumpGame.SCREEN_WIDTH; // <-- Importante: imposta una larghezza anche per il livello di default
        return defaultLevel;
    }

    public void loadCurrentLevel() {
        if (currentLevelIndex >= levels.size()) {
            Gdx.app.log("LevelManager", "Tutti i livelli completati! Fine del gioco.");
            game.player.isGameOver = true;
            return;
        }

        LevelData currentLevelData = levels.get(currentLevelIndex);
        game.resetGameForLevel(currentLevelData);
        Gdx.app.log("LevelManager", "Caricato livello: " + (currentLevelIndex + 1));
    }

    public void goToNextLevel() {
        currentLevelIndex++;
        game.player.reset();
        loadCurrentLevel();
    }

    public LevelData getCurrentLevelData() {
        if (currentLevelIndex < levels.size()) {
            return levels.get(currentLevelIndex);
        }
        return null;
    }

    public void resetLevelIndex() {
        this.currentLevelIndex = 0;
    }
}