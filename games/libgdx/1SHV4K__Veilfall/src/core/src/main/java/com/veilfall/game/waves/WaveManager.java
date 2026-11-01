package com.veilfall.game.waves;

import com.veilfall.game.data.WaveData;
import com.veilfall.game.data.WaveEnemyData;
import com.veilfall.game.database.repository.WaveRepository;
import com.veilfall.game.enemies.EnemyManager;

import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public final class WaveManager {
    private static final float INTERMISSION_DURATION = 3f;

    private final List<WaveData> waves;
    private final List<List<WaveEnemyData>> waveEnemies;
    private int currentWaveIndex = -1;
    private float intermissionRemaining;
    private State state = State.WAITING;

    public WaveManager(int arenaId, int bossMobId, WaveRepository waveRepository) throws SQLException {
        waves = waveRepository.getWavesForArena(arenaId);
        if (waves.isEmpty()) {
            throw new SQLException("No waves are configured for arena " + arenaId);
        }
        if (!waves.getLast().isBossWave()) {
            throw new SQLException("The final wave for arena " + arenaId + " must be a boss wave");
        }
        waveEnemies = new ArrayList<>(waves.size());
        for (int index = 0; index < waves.size(); index++) {
            WaveData wave = waves.get(index);
            List<WaveEnemyData> definitions = waveRepository.getEnemiesForWave(wave.getId());
            if (definitions.isEmpty()) {
                throw new SQLException("Wave " + wave.getWaveNumber() + " has no enemy definitions");
            }
            if (index == waves.size() - 1 && definitions.stream()
                    .noneMatch(definition -> definition.getMobId() == bossMobId)) {
                throw new SQLException("Final wave " + wave.getWaveNumber()
                        + " does not contain the arena's configured boss " + bossMobId);
            }
            waveEnemies.add(definitions);
        }
    }

    public void start(EnemyManager enemyManager) throws SQLException {
        if (state != State.WAITING) {
            throw new IllegalStateException("Wave sequence has already started");
        }
        currentWaveIndex = 0;
        spawnCurrentWave(enemyManager);
    }

    public void update(float delta, EnemyManager enemyManager) throws SQLException {
        if (state == State.ACTIVE && enemyManager.isCleared()) {
            if (currentWaveIndex == waves.size() - 1) {
                state = State.COMPLETE;
            } else {
                state = State.INTERMISSION;
                intermissionRemaining = INTERMISSION_DURATION;
            }
        } else if (state == State.INTERMISSION) {
            intermissionRemaining = Math.max(0f, intermissionRemaining - delta);
            if (intermissionRemaining <= 0f) {
                currentWaveIndex++;
                spawnCurrentWave(enemyManager);
            }
        }
    }

    private void spawnCurrentWave(EnemyManager enemyManager) throws SQLException {
        state = State.SPAWNING;
        enemyManager.spawnWave(waveEnemies.get(currentWaveIndex), waves.get(currentWaveIndex));
        state = State.ACTIVE;
    }

    public WaveData getCurrentWave() {
        if (currentWaveIndex < 0) return null;
        return waves.get(currentWaveIndex);
    }

    public int getCurrentWaveNumber() {
        return currentWaveIndex < 0 ? 0 : waves.get(currentWaveIndex).getWaveNumber();
    }

    public int getTotalWaves() {
        return waves.size();
    }

    public State getState() {
        return state;
    }

    public float getIntermissionRemaining() {
        return intermissionRemaining;
    }

    public enum State {
        WAITING,
        SPAWNING,
        ACTIVE,
        INTERMISSION,
        COMPLETE
    }
}
