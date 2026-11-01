package ru.samsung.gamestudio;

import com.badlogic.gdx.utils.TimeUtils;
import ru.samsung.gamestudio.managers.MemoryManager;

import java.util.ArrayList;

public class GameSession {

    public GameState state;
    long nextTrashSpawnTime;
    long nextPowerUpSpawnTime;
    long sessionStartTime;
    long pauseStartTime;
    private int score;
    int destructedTrashNumber;
    private int comboScore;
    private int comboCount;
    private long lastKillTime;

    public GameSession() {
    }

    public void startGame() {
        state = GameState.PLAYING;
        score = 0;
        destructedTrashNumber = 0;
        comboScore = 0;
        comboCount = 0;
        lastKillTime = 0;
        sessionStartTime = TimeUtils.millis();
        nextTrashSpawnTime = sessionStartTime + (long) (GameSettings.STARTING_TRASH_APPEARANCE_COOL_DOWN
                * getTrashPeriodCoolDown());
        nextPowerUpSpawnTime = sessionStartTime + GameSettings.STARTING_POWERUP_COOL_DOWN;
    }

    public void pauseGame() {
        state = GameState.PAUSED;
        pauseStartTime = TimeUtils.millis();
    }

    public void resumeGame() {
        state = GameState.PLAYING;
        long pauseDuration = TimeUtils.millis() - pauseStartTime;
        sessionStartTime += pauseDuration;
        nextTrashSpawnTime += pauseDuration;
        nextPowerUpSpawnTime += pauseDuration;
        if (lastKillTime > 0) lastKillTime += pauseDuration;
    }

    public void endGame() {
        updateScore();
        state = GameState.ENDED;
        ArrayList<Integer> recordsTable = MemoryManager.loadRecordsTable();
        if (recordsTable == null) {
            recordsTable = new ArrayList<>();
        }
        int foundIdx = 0;
        for (; foundIdx < recordsTable.size(); foundIdx++) {
            if (recordsTable.get(foundIdx) < getScore()) break;
        }
        recordsTable.add(foundIdx, getScore());
        while (recordsTable.size() > 5) {
            recordsTable.remove(recordsTable.size() - 1);
        }
        MemoryManager.saveTableOfRecords(recordsTable);
    }

    public void destructionRegistration() {
        destructedTrashNumber += 1;
        long now = TimeUtils.millis();
        if (lastKillTime > 0 && now - lastKillTime <= GameSettings.COMBO_WINDOW_MS) {
            comboCount++;
            if (comboCount >= GameSettings.COMBO_THRESHOLD) {
                comboScore += comboCount * 10;
            }
        } else {
            comboCount = 1;
        }
        lastKillTime = now;
    }

    public void updateScore() {
        score = (int) (TimeUtils.millis() - sessionStartTime) / 100
                + destructedTrashNumber * 100
                + comboScore;
    }

    public int getScore() {
        return score;
    }

    public int getComboCount() {
        return comboCount;
    }

    public boolean isComboActive() {
        return comboCount >= GameSettings.COMBO_THRESHOLD
                && TimeUtils.millis() - lastKillTime <= GameSettings.COMBO_WINDOW_MS;
    }

    public int getDangerLevel() {
        long elapsed = TimeUtils.millis() - sessionStartTime;
        return Math.min(5, (int) (elapsed / 20000L) + 1);
    }

    public boolean shouldSpawnTrash() {
        if (nextTrashSpawnTime <= TimeUtils.millis()) {
            nextTrashSpawnTime = TimeUtils.millis() + (long) (GameSettings.STARTING_TRASH_APPEARANCE_COOL_DOWN
                    * getTrashPeriodCoolDown());
            return true;
        }
        return false;
    }

    public boolean shouldSpawnPowerUp() {
        if (nextPowerUpSpawnTime <= TimeUtils.millis()) {
            nextPowerUpSpawnTime = TimeUtils.millis() + GameSettings.STARTING_POWERUP_COOL_DOWN;
            return true;
        }
        return false;
    }

    private float getTrashPeriodCoolDown() {
        return (float) Math.exp(-0.001 * (TimeUtils.millis() - sessionStartTime + 1) / 1000);
    }
}
