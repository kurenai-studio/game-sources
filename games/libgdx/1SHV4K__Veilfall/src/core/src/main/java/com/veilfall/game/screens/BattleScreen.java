package com.veilfall.game.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.InputMultiplexer;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.graphics.g3d.ModelInstance;
import com.badlogic.gdx.scenes.scene2d.Actor;
import com.badlogic.gdx.scenes.scene2d.ui.Cell;
import com.badlogic.gdx.scenes.scene2d.ui.Image;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.Table;
import com.badlogic.gdx.scenes.scene2d.ui.TextButton;
import com.badlogic.gdx.scenes.scene2d.utils.ChangeListener;
import com.badlogic.gdx.scenes.scene2d.utils.TextureRegionDrawable;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.GdxRuntimeException;
import com.veilfall.game.VeilfallGame;
import com.veilfall.game.data.ArenaData;
import com.veilfall.game.data.CharacterData;
import com.veilfall.game.data.WeaponData;
import com.veilfall.game.enemies.EnemyManager;
import com.veilfall.game.enemies.Enemy;
import com.veilfall.game.player.Player;
import com.veilfall.game.player.PlayerCombat;
import com.veilfall.game.player.PlayerController;
import com.veilfall.game.player.CharacterKit;
import com.veilfall.game.player.ControlBindings;
import com.veilfall.game.waves.WaveManager;

import java.sql.SQLException;

public final class BattleScreen extends AbstractGameScreen {
    private final ArenaData arena;
    private final CharacterData character;
    private final WeaponData weapon;
    private final Player player;
    private final PlayerCombat playerCombat;
    private final PlayerController playerController;
    private final EnemyManager enemyManager;
    private final WaveManager waveManager;
    private final Label healthLabel;
    private final Label enemiesLabel;
    private final Label bossLabel;
    private final Cell<Image> bossHealthFillCell;
    private final Table bossHealthBar;
    private final Label waveLabel;
    private final Label shieldBashLabel;
    private final Label groundSlamLabel;
    private final Label veilGuardLabel;
    private final Label dodgeLabel;
    private final Cell<Image> healthFillCell;
    private final Array<ModelInstance> renderInstances = new Array<>();
    private final float healthBarWidth = 200f;
    private float elapsedSeconds;
    private boolean resultShown;

    public BattleScreen(VeilfallGame game, ArenaData arena, CharacterData character, WeaponData weapon) {
        super(game);
        this.arena = arena;
        this.character = character;
        this.weapon = weapon;
        try {
            if (weapon.getCharacterId() != character.getId()) {
                throw new SQLException("Selected weapon does not belong to " + character.getName());
            }
            var skills = game.getSkillRepository().getSkillsForCharacter(character.getId());
            player = new Player(character, weapon, game.getModelAssets());
            playerCombat = new PlayerCombat(player, skills, game.getAudioDirector());
            enemyManager = new EnemyManager(game.getMobRepository(), game.getModelAssets());
            waveManager = new WaveManager(arena.getId(), arena.getBossMobId(), game.getWaveRepository());
            waveManager.start(enemyManager);
        } catch (SQLException | IllegalArgumentException exception) {
            throw new GdxRuntimeException("Failed to load battle definitions from SQLite", exception);
        }
        playerController = new PlayerController(player, playerCombat, enemyManager,
                game.getRenderer().getCameraController());

        Table hud = new Table();
        hud.setFillParent(true);
        hud.top().left().pad(14f);
        stage.addActor(hud);
        Label title = game.getUiTheme().label(arena.getName());
        title.setFontScale(1.25f);
        hud.add(title).left().padBottom(7f).row();
        waveLabel = game.getUiTheme().label("");
        hud.add(waveLabel).left().padBottom(7f).row();
        healthLabel = game.getUiTheme().label("");
        hud.add(healthLabel).left().padBottom(4f).row();

        TextureRegion white = new TextureRegion(game.getUiTheme().getSkin()
                .get("white-texture", com.badlogic.gdx.graphics.Texture.class));
        Table healthBar = new Table();
        healthBar.setBackground(new TextureRegionDrawable(white).tint(new Color(0.10f, 0.10f, 0.12f, 1f)));
        Image healthFill = new Image(new TextureRegionDrawable(white)
                .tint(new Color(0.25f, 0.78f, 0.38f, 1f)));
        healthFillCell = healthBar.add(healthFill).left().width(healthBarWidth).height(10f);
        hud.add(healthBar).width(healthBarWidth).height(10f).left().padBottom(8f).row();

        enemiesLabel = game.getUiTheme().label("");
        hud.add(enemiesLabel).left().padBottom(8f).row();
        Label controls = game.getUiTheme().label("Left click: attack   Right click: move   Mouse: aim   Move: "
                + ControlBindings.display("up") + ControlBindings.display("left")
                + ControlBindings.display("down") + ControlBindings.display("right"));
        hud.add(controls).left().padBottom(8f).row();
        bossLabel = game.getUiTheme().label("");
        bossHealthBar = new Table();
        bossHealthBar.setBackground(new TextureRegionDrawable(white)
                .tint(new Color(0.10f, 0.10f, 0.12f, 1f)));
        Image bossFill = new Image(new TextureRegionDrawable(white)
                .tint(new Color(0.82f, 0.16f, 0.22f, 1f)));
        bossHealthFillCell = bossHealthBar.add(bossFill).left().width(0f).height(12f);
        hud.add(bossLabel).left().padBottom(4f).row();
        hud.add(bossHealthBar).width(240f).height(12f).left().padBottom(8f).row();
        bossLabel.setVisible(false);
        bossHealthBar.setVisible(false);
        TextButton back = game.getUiTheme().button("BACK TO ARENA SELECT");
        back.addListener(new ChangeListener() {
            @Override
            public void changed(ChangeEvent event, Actor actor) {
                game.showArenaSelect();
            }
        });
        hud.add(back).left().width(190f).height(34f).padTop(3f);

        Table abilityHud = new Table();
        abilityHud.setFillParent(true);
        abilityHud.bottom().left().pad(14f);
        stage.addActor(abilityHud);
        shieldBashLabel = game.getUiTheme().label("");
        groundSlamLabel = game.getUiTheme().label("");
        veilGuardLabel = game.getUiTheme().label("");
        dodgeLabel = game.getUiTheme().label("");
        abilityHud.add(shieldBashLabel).left().padRight(14f);
        abilityHud.add(groundSlamLabel).left().padRight(14f);
        abilityHud.add(veilGuardLabel).left().padRight(14f);
        abilityHud.add(dodgeLabel).left();
        updateHud();
    }

    @Override
    public void show() {
        super.show();
        Gdx.input.setInputProcessor(new InputMultiplexer(stage, playerController,
                game.getRenderer().getCameraController()));
    }

    @Override
    public void render(float delta) {
        if (resultShown) return;
        float frameDelta = Math.min(delta, 0.05f);
        elapsedSeconds += frameDelta;
        playerCombat.update(frameDelta);
        playerController.update(frameDelta);
        enemyManager.update(player, frameDelta);
        try {
            waveManager.update(frameDelta, enemyManager);
        } catch (SQLException exception) {
            throw new GdxRuntimeException("Failed to spawn the next arena wave", exception);
        }
        game.getRenderer().getCameraController().setTargetPosition(player.getX(), player.getZ());
        updateHud();

        if (player.isDead()) {
            showResult(false);
            return;
        }
        if (waveManager.getState() == WaveManager.State.COMPLETE) {
            showResult(true);
            return;
        }

        renderInstances.clear();
        for (ModelInstance instance : player.getInstances()) {
            renderInstances.add(instance);
        }
        playerCombat.appendEffectInstances(renderInstances);
        enemyManager.appendInstances(renderInstances);
        game.getRenderer().render(renderInstances);
        drawStage(frameDelta);
    }

    private void updateHud() {
        updateWaveLabel();
        healthLabel.setText(character.getName() + " — " + weapon.getName() + " — "
                + playerCombat.getKit().getBasicAttack()
                + " — HP: " + player.getCurrentHealth()
                + " / " + player.getMaxHealth());
        enemiesLabel.setText("Enemies Remaining: " + enemyManager.getAliveCount()
                + "   •   " + enemyManager.getAliveSummary());
        healthFillCell.width(healthBarWidth * player.getCurrentHealth() / player.getMaxHealth());
        updateBossHud();
        CharacterKit kit = playerCombat.getKit();
        updateAbilityLabel(shieldBashLabel, ControlBindings.display("ability_q") + " " + kit.getAbilityQ(), playerCombat.getCooldownQ());
        updateAbilityLabel(groundSlamLabel, ControlBindings.display("ability_e") + " " + kit.getAbilityE(), playerCombat.getCooldownE());
        updateAbilityLabel(veilGuardLabel, ControlBindings.display("ability_r") + " " + kit.getAbilityR(), playerCombat.getCooldownR());
        updateAbilityLabel(dodgeLabel, ControlBindings.display("dodge") + " Dodge", playerCombat.getDodgeCooldownRemaining());
    }

    private void updateBossHud() {
        var currentWave = waveManager.getCurrentWave();
        Enemy boss = currentWave != null && currentWave.isBossWave() ? enemyManager.getBossEnemy() : null;
        boolean visible = boss != null;
        bossLabel.setVisible(visible);
        bossHealthBar.setVisible(visible);
        if (!visible) return;
        bossLabel.setText(boss.getData().getName() + (boss.isBossTelegraphing()
                ? " — " + boss.getBossAttackName() + "! DODGE" : ""));
        bossHealthFillCell.width(240f * boss.getCurrentHealth() / boss.getMaxHealth());
    }

    private void updateWaveLabel() {
        switch (waveManager.getState()) {
            case WAITING -> waveLabel.setText("WAVE 0 / " + waveManager.getTotalWaves());
            case SPAWNING, ACTIVE -> waveLabel.setText("WAVE " + waveManager.getCurrentWaveNumber()
                    + " / " + waveManager.getTotalWaves());
            case INTERMISSION -> {
                int seconds = (int) Math.ceil(waveManager.getIntermissionRemaining());
                waveLabel.setText(seconds > 0
                        ? "WAVE CLEARED — NEXT WAVE " + (waveManager.getCurrentWaveNumber() + 1)
                        + " IN " + seconds
                        : "WAVE CLEARED — START");
            }
            case COMPLETE -> waveLabel.setText("ALL WAVES CLEARED");
        }
    }

    private static void updateAbilityLabel(Label label, String name, float cooldownRemaining) {
        if (cooldownRemaining > 0f) {
            label.setText(String.format("%s (%.1f)", name, cooldownRemaining));
            label.setColor(Color.GRAY);
        } else {
            label.setText(name);
            label.setColor(Color.WHITE);
        }
    }

    private void showResult(boolean victory) {
        resultShown = true;
        game.showResult(new BattleOutcome(victory, character.getName(), arena.getName(),
                victory ? waveManager.getTotalWaves() : Math.max(0, waveManager.getCurrentWaveNumber() - 1),
                enemyManager.getEnemiesDefeated(), enemyManager.getBossesDefeated(), elapsedSeconds,
                arena.getId(), character.getId(), weapon.getId(), weapon.getName(), 0, 0, 1, 0));
    }

    @Override
    public void dispose() {
        super.dispose();
        player.dispose();
        playerCombat.dispose();
        enemyManager.dispose();
    }
}
