package com.veilfall.game.screens;

import com.badlogic.gdx.scenes.scene2d.Actor;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.Table;
import com.badlogic.gdx.scenes.scene2d.ui.TextButton;
import com.badlogic.gdx.scenes.scene2d.utils.ChangeListener;
import com.badlogic.gdx.utils.Align;
import com.veilfall.game.VeilfallGame;

public final class ResultScreen extends AbstractGameScreen {
    public ResultScreen(VeilfallGame game, BattleOutcome outcome) {
        super(game);
        Table root = new Table();
        root.setFillParent(true);
        root.pad(20f);
        stage.addActor(root);

        Label title = game.getUiTheme().label(outcome.victory() ? "VICTORY" : "DEFEAT");
        title.setFontScale(1.7f);
        root.add(title).center().padBottom(18f).row();
        addLine(root, "Result: " + (outcome.victory() ? "Victory" : "Defeat"));
        addLine(root, "Character: " + outcome.characterName());
        addLine(root, "Arena: " + outcome.arenaName());
        addLine(root, "Weapon: " + outcome.weaponName());
        addLine(root, "Waves completed: " + outcome.wavesCompleted());
        addLine(root, "Enemies defeated: " + outcome.enemiesDefeated());
        addLine(root, "Bosses defeated: " + outcome.bossesDefeated());
        addLine(root, String.format("Duration: %.1f seconds", outcome.durationSeconds()));
        addLine(root, "XP earned: +" + outcome.experienceEarned() + "    Total XP: " + outcome.totalExperience());
        addLine(root, "Level: " + outcome.playerLevel() + "    Personal best wave: " + outcome.bestWave());

        TextButton returnButton = game.getUiTheme().button("RETURN TO LOBBY");
        returnButton.addListener(new ChangeListener() {
            @Override
            public void changed(ChangeEvent event, Actor actor) {
                game.showLobby();
            }
        });
        root.add(returnButton).width(190f).height(42f).padTop(18f);
    }

    private void addLine(Table root, String text) {
        Label label = game.getUiTheme().label(text);
        label.setAlignment(Align.center);
        root.add(label).center().padBottom(7f).row();
    }
}
