package com.bossfight.screens;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.MathUtils;
import com.bossfight.boss.Boss;
import com.bossfight.config.Constants;
import com.bossfight.entities.Player;
import com.bossfight.entities.PlayerInput;
import com.bossfight.audio.AudioManager;
import com.bossfight.effects.CameraShake;
import com.bossfight.effects.ParticleSystem;
import com.bossfight.gameplay.ProjectileSystem;
import com.bossfight.rendering.RetroTextFactory;
import com.bossfight.rendering.TextureDraw;

final class BattleFlow {
    private static final String BATTLE_MUSIC_PATH = "audio/music/boss_fight_theme.mp3";
    private static final String PHASE_TWO_MUSIC_PATH = "audio/music/boss_fight_phase_two_theme.mp3";
    private static final String INTRO_NARRATION_PATH = "audio/voice/narrator_intro.wav";
    private static final String KNOCKOUT_NARRATION_PATH = "audio/voice/narrator_knockout.wav";
    private static final float BATTLE_MUSIC_VOLUME = 0.04f;
    private static final float PHASE_TWO_MUSIC_VOLUME = 0.05f;
    private static final float FINAL_RAGE_MUSIC_VOLUME = 0.065f;
    private static final float MUSIC_VOLUME_RESPONSE = 2.4f;
    private static final float PHASE_TWO_MUSIC_DELAY = 1.75f;
    private static final float INTRO_NARRATION_VOLUME = 1f;
    private static final float KNOCKOUT_NARRATION_VOLUME = 1.3f;
    private static final float INTRO_READY_TEXT_ONSET = 0.1f;
    private static final float KNOCKOUT_DURATION = 3.2f;
    private static final float KNOCKOUT_TEXT_ONSET = 0.1f;
    private static final float KNOCKOUT_TEXT_FADE_START = 1.2f;
    private static final float KNOCKOUT_TEXT_FADE_DURATION = 0.35f;
    private static final float KNOCKOUT_PARTICLE_DURATION = 2.35f;
    private static final float KNOCKOUT_PARTICLE_INTERVAL = 0.11f;

    private final GameContext game;
    private final Texture readyText;
    private final Texture goText;
    private final Texture knockoutText;
    private float introTimer;
    private float knockoutTimer;
    private float knockoutParticleTimer;
    private float phaseTwoMusicTimer;
    private float currentMusicVolume = BATTLE_MUSIC_VOLUME;
    private boolean introVoicePlayed;
    private boolean fightStarted;
    private boolean introPausedForTransition;
    private boolean knockoutSequenceActive;
    private boolean endTransitionRequested;
    private boolean phaseTwoMusicPending;

    BattleFlow(GameContext game, RetroTextFactory textFactory, boolean introPausedForTransition) {
        this.game = game;
        readyText = textFactory.createFightCue("READY?", false);
        goText = textFactory.createFightCue("GO!", true);
        knockoutText = textFactory.createKnockout("A KNOCKOUT!");
        this.introPausedForTransition = introPausedForTransition;
    }

    boolean isIntroPausedForTransition() {
        return introPausedForTransition;
    }

    boolean isFightStarted() {
        return fightStarted;
    }

    boolean isKnockoutSequenceActive() {
        return knockoutSequenceActive;
    }

    void startIntroAfterTransition() {
        if (!introPausedForTransition) {
            return;
        }

        introPausedForTransition = false;
    }

    void beginPhaseTwoMusicTransition() {
        game.getAudioManager().stopMusic();
        phaseTwoMusicTimer = PHASE_TWO_MUSIC_DELAY;
        phaseTwoMusicPending = true;
    }

    void updatePhaseTwoMusicTransition(float delta) {
        if (!phaseTwoMusicPending) {
            return;
        }

        phaseTwoMusicTimer = Math.max(0f, phaseTwoMusicTimer - delta);
        if (phaseTwoMusicTimer > 0f) {
            return;
        }

        phaseTwoMusicPending = false;
        currentMusicVolume = PHASE_TWO_MUSIC_VOLUME;
        game.getAudioManager().playMusic(PHASE_TWO_MUSIC_PATH, true, PHASE_TWO_MUSIC_VOLUME);
    }

    void updateDynamicMusic(float delta, Boss boss) {
        if (!fightStarted || phaseTwoMusicPending || knockoutSequenceActive) {
            return;
        }

        float targetVolume = targetMusicVolume(boss);
        currentMusicVolume = MathUtils.lerp(
                currentMusicVolume,
                targetVolume,
                Math.min(1f, delta * MUSIC_VOLUME_RESPONSE));
        game.getAudioManager().setMusicVolume(currentMusicVolume);
    }

    private float targetMusicVolume(Boss boss) {
        if (boss.isFinalRage()) {
            return FINAL_RAGE_MUSIC_VOLUME;
        }
        return boss.isPhaseTwo() ? PHASE_TWO_MUSIC_VOLUME : BATTLE_MUSIC_VOLUME;
    }

    void updateIntro(float delta, ControlsOverlay controlsOverlay, Boss boss) {
        if (fightStarted || introPausedForTransition) {
            return;
        }

        if (!introVoicePlayed) {
            introVoicePlayed = true;
            game.getAudioManager().playVoice(INTRO_NARRATION_PATH, INTRO_NARRATION_VOLUME);
        }

        introTimer = Math.min(Constants.INTRO_TOTAL_DURATION, introTimer + delta);
        if (introTimer >= Constants.INTRO_TOTAL_DURATION) {
            fightStarted = true;
            controlsOverlay.showOnce();
            currentMusicVolume = BATTLE_MUSIC_VOLUME;
            game.getAudioManager().playMusic(BATTLE_MUSIC_PATH, true, BATTLE_MUSIC_VOLUME);
            boss.showTelegraph(new Color(1f, 0.38f, 0.12f, 1f), 0.35f);
        }
    }

    void beginKnockoutSequence(ProjectileSystem projectiles, ParticleSystem particles,
                               Boss boss, CameraShake cameraShake) {
        knockoutSequenceActive = true;
        phaseTwoMusicPending = false;
        knockoutTimer = 0f;
        knockoutParticleTimer = 0f;
        projectiles.clear();
        game.getAudioManager().stopMusic();
        game.getAudioManager().playVoice(KNOCKOUT_NARRATION_PATH, KNOCKOUT_NARRATION_VOLUME);
        spawnKnockoutExplosion(particles, boss);
        cameraShake.request(16f, 0.46f);
    }

    void updateKnockoutSequence(float delta, Player player, ParticleSystem particles, Boss boss) {
        knockoutTimer += delta;
        player.update(delta, PlayerInput.NONE);

        if (knockoutTimer < KNOCKOUT_PARTICLE_DURATION) {
            knockoutParticleTimer -= delta;
            while (knockoutParticleTimer <= 0f) {
                spawnKnockoutExplosion(particles, boss);
                knockoutParticleTimer += KNOCKOUT_PARTICLE_INTERVAL;
            }
        }

        if (knockoutTimer >= KNOCKOUT_DURATION) {
            requestEndTransition(true);
        }
    }

    void requestEndTransition(boolean victory) {
        if (endTransitionRequested) {
            return;
        }

        endTransitionRequested = true;
        if (!victory) {
            game.getAudioManager().playCue(AudioManager.Cue.DEFEAT);
        }
        game.showEndScreen(victory);
    }

    void renderIntroSpotlight(ShapeRenderer shapeRenderer, Boss boss, float elapsed) {
        float pulse = (MathUtils.sin(elapsed * 8f) + 1f) * 0.5f;
        shapeRenderer.setColor(1f, 0.93f, 0.54f, 0.16f + pulse * 0.08f);
        shapeRenderer.triangle(820f, Constants.WORLD_HEIGHT, 1160f, Constants.WORLD_HEIGHT,
                boss.getCenterX(), Constants.FLOOR_Y + 4f);
    }

    void renderOverlays(SpriteBatch batch, float elapsed) {
        drawIntroOverlay(batch, elapsed);
        drawKnockoutOverlay(batch, elapsed);
    }

    private void drawIntroOverlay(SpriteBatch batch, float elapsed) {
        if (fightStarted || introPausedForTransition) {
            return;
        }

        if (introTimer < Constants.INTRO_READY_DURATION) {
            float readyElapsed = introTimer - INTRO_READY_TEXT_ONSET;
            if (readyElapsed < 0f) {
                return;
            }

            float pop = MathUtils.clamp(readyElapsed / 0.18f, 0f, 1f);
            float wobble = MathUtils.sin(elapsed * 18f) * 2.2f;
            TextureDraw.centeredAnimated(batch, readyText, Constants.WORLD_WIDTH * 0.5f,
                    Constants.WORLD_HEIGHT * 0.58f, 0.9f + pop * 0.18f, wobble, 0f, 1f);
        } else {
            float goElapsed = introTimer - Constants.INTRO_READY_DURATION;
            float pop = MathUtils.clamp(goElapsed / 0.15f, 0f, 1f);
            float scale = 0.98f + pop * 0.28f + MathUtils.sin(elapsed * 24f) * 0.035f;
            TextureDraw.centeredAnimated(batch, goText, Constants.WORLD_WIDTH * 0.5f,
                    Constants.WORLD_HEIGHT * 0.58f, scale, -MathUtils.sin(elapsed * 20f) * 1.6f,
                    MathUtils.sin(elapsed * 9f) * 1.8f, 1f);
        }
    }

    private void drawKnockoutOverlay(SpriteBatch batch, float elapsed) {
        if (!knockoutSequenceActive || knockoutTimer < KNOCKOUT_TEXT_ONSET) {
            return;
        }

        float textTimer = knockoutTimer - KNOCKOUT_TEXT_ONSET;
        float alpha = 1f - MathUtils.clamp(
                (knockoutTimer - KNOCKOUT_TEXT_FADE_START) / KNOCKOUT_TEXT_FADE_DURATION,
                0f, 1f);
        float slam = MathUtils.clamp(textTimer / 0.18f, 0f, 1f);
        float pulse = MathUtils.sin(elapsed * 11f) * 0.025f;
        float scale = 0.88f + slam * 0.14f + pulse;
        float rotation = MathUtils.sin(elapsed * 6.5f) * 1.1f * alpha;
        TextureDraw.centeredAnimated(batch, knockoutText, Constants.WORLD_WIDTH * 0.5f,
                Constants.WORLD_HEIGHT * 0.6f, scale, 0f, rotation, alpha);
    }

    private void spawnKnockoutExplosion(ParticleSystem particles, Boss boss) {
        particles.spawnBossDefeatBurst(boss.getCenterX() - 20f, Constants.FLOOR_Y + 265f);
        game.getAudioManager().playCue(AudioManager.Cue.BOSS_DEFEAT_EXPLOSION);
    }
}
