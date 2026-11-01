package com.veilfall.game.screens;

import com.badlogic.gdx.scenes.scene2d.Actor;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.ScrollPane;
import com.badlogic.gdx.scenes.scene2d.ui.Table;
import com.badlogic.gdx.scenes.scene2d.ui.TextButton;
import com.badlogic.gdx.scenes.scene2d.utils.ChangeListener;
import com.badlogic.gdx.utils.GdxRuntimeException;
import com.veilfall.game.VeilfallGame;
import com.veilfall.game.data.ArenaData;
import com.veilfall.game.data.MobData;

import java.sql.SQLException;
import java.util.List;
import java.util.HashMap;
import java.util.Map;

public final class ArenaSelectScreen extends AbstractGameScreen {
    private final Table arenaList = new Table();
    private final Label details;
    private final TextButton startBattle;
    private ArenaData selectedArena;
    private final Map<Integer, TextButton> arenaButtons = new HashMap<>();
    private final Map<Integer, String> arenaNames = new HashMap<>();

    public ArenaSelectScreen(VeilfallGame game) {
        super(game);
        Table root = new Table();
        root.setFillParent(true);
        root.pad(18f);
        stage.addActor(root);
        Label title = game.getUiTheme().label("ARENA SELECT");
        title.setFontScale(1.4f);
        root.add(title).colspan(2).left().padBottom(16f).row();

        arenaList.top().left();
        root.add(arenaList).top().left().width(190f).padRight(20f);
        details = game.getUiTheme().label("Select an arena to view its details.");
        details.setWrap(true);
        ScrollPane detailScroll = new ScrollPane(details, new ScrollPane.ScrollPaneStyle());
        detailScroll.setFadeScrollBars(false);
        root.add(detailScroll).top().left().width(480f).fill().expand().row();

        Table actions = new Table();
        TextButton back = game.getUiTheme().button("BACK");
        back.addListener(new ChangeListener() {
            @Override
            public void changed(ChangeEvent event, Actor actor) {
                game.showLobby();
            }
        });
        actions.add(back).width(130f).height(40f).padRight(10f);

        startBattle = game.getUiTheme().button("START BATTLE");
        startBattle.setDisabled(true);
        startBattle.addListener(new ChangeListener() {
            @Override
            public void changed(ChangeEvent event, Actor actor) {
                if (selectedArena != null) {
                    game.startBattle(selectedArena);
                }
            }
        });
        actions.add(startBattle).width(170f).height(40f);
        root.add(actions).colspan(2).right().padTop(18f);
        loadArenas();
    }

    private void loadArenas() {
        try {
            List<ArenaData> arenas = game.getArenaRepository().getAll();
            if (arenas.isEmpty()) {
                arenaList.add(game.getUiTheme().label("No arenas available.")).left();
                return;
            }
            for (ArenaData arena : arenas) {
                TextButton select = game.getUiTheme().button("SELECT — " + arena.getName());
                select.addListener(new ChangeListener() {
                    @Override
                    public void changed(ChangeEvent event, Actor actor) {
                        selectArena(arena);
                    }
                });
                arenaButtons.put(arena.getId(), select);
                arenaNames.put(arena.getId(), arena.getName());
                arenaList.add(select).width(180f).height(40f).padBottom(8f).row();
            }
        } catch (SQLException exception) {
            throw new GdxRuntimeException("Failed to load arenas from SQLite", exception);
        }
    }

    private void selectArena(ArenaData arena) {
        try {
            MobData boss = game.getMobRepository().getById(arena.getBossMobId())
                    .orElseThrow(() -> new SQLException("Arena boss is missing: " + arena.getBossMobId()));
            selectedArena = arena;
            arenaButtons.forEach((id, button) -> button.setText((id == arena.getId() ? "SELECTED  ▶  " : "SELECT  •  ")
                    + arenaNames.getOrDefault(id, "Arena")));
            details.setText(arena.getName() + "\n\n" + arena.getDescription()
                    + "\n\nDifficulty: " + arena.getDifficulty()
                    + "\nEnvironment: " + arena.getEnvironment()
                    + "\nLoadout: " + game.getSelectedCharacter().getName() + " / "
                    + game.getSelectedWeapon().getName() + " (Damage " + game.getSelectedWeapon().getDamage()
                    + ", speed " + game.getSelectedWeapon().getAttackSpeed() + "/s, range "
                    + game.getSelectedWeapon().getRange() + ")"
                    + "\nFinal boss: " + boss.getName()
                    + "\n\nWAVE PLAN\n" + getWavePlan(arena));
            startBattle.setDisabled(false);
        } catch (SQLException exception) {
            throw new GdxRuntimeException("Failed to load arena details from SQLite", exception);
        }
    }

    private String getWavePlan(ArenaData arena) throws SQLException {
        StringBuilder plan = new StringBuilder();
        for (var wave : game.getWaveRepository().getWavesForArena(arena.getId())) {
            if (plan.length() > 0) plan.append('\n');
            plan.append("Wave ").append(wave.getWaveNumber());
            if (wave.isBossWave()) plan.append(" — BOSS");
            plan.append(": ");
            var enemies = game.getWaveRepository().getEnemiesForWave(wave.getId());
            plan.append(enemies.stream().map(enemy -> enemy.getQuantity() + "× " + enemy.getMobName())
                    .collect(java.util.stream.Collectors.joining(", ")));
        }
        return plan.toString();
    }
}
