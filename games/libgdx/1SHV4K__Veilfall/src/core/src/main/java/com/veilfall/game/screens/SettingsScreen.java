package com.veilfall.game.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.InputAdapter;
import com.badlogic.gdx.InputMultiplexer;
import com.badlogic.gdx.scenes.scene2d.Actor;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.Table;
import com.badlogic.gdx.scenes.scene2d.ui.TextButton;
import com.badlogic.gdx.scenes.scene2d.utils.ChangeListener;
import com.veilfall.game.VeilfallGame;
import com.veilfall.game.player.ControlBindings;

import java.util.LinkedHashMap;
import java.util.Map;

public final class SettingsScreen extends AbstractGameScreen {
    private final Map<String, TextButton> buttons = new LinkedHashMap<>();
    private final InputAdapter rebinder = new InputAdapter() {
        @Override public boolean keyDown(int keycode) {
            if (waitingFor != null && keycode == Input.Keys.ESCAPE) {
                waitingFor = null;
                refreshBindings();
                return true;
            }
            if (waitingFor != null && keycode != Input.Keys.ESCAPE) {
                ControlBindings.set(waitingFor, keycode);
                waitingFor = null;
                refreshBindings();
                return true;
            }
            return false;
        }
    };
    private String waitingFor;

    public SettingsScreen(VeilfallGame game) {
        super(game);
        Table root = new Table(); root.setFillParent(true); root.pad(24f); stage.addActor(root);
        Label title = game.getUiTheme().label("SETTINGS & CONTROLS"); title.setFontScale(1.5f);
        root.add(title).colspan(2).padBottom(18f).row();
        addBinding(root, "Move up", "up"); addBinding(root, "Move down", "down");
        addBinding(root, "Move left", "left"); addBinding(root, "Move right", "right");
        addBinding(root, "Ability Q", "ability_q"); addBinding(root, "Ability E", "ability_e");
        addBinding(root, "Ability R", "ability_r"); addBinding(root, "Dodge", "dodge");
        TextButton fullscreen = game.getUiTheme().button("TOGGLE FULLSCREEN");
        fullscreen.addListener(new ChangeListener() { @Override public void changed(ChangeEvent event, Actor actor) {
            if (Gdx.graphics.isFullscreen()) Gdx.graphics.setWindowedMode(1280, 720);
            else Gdx.graphics.setFullscreenMode(Gdx.graphics.getDisplayMode());
        }});
        root.add(fullscreen).colspan(2).width(230f).height(40f).padTop(14f).row();
        TextButton audio = game.getUiTheme().button(audioText());
        audio.addListener(new ChangeListener() { @Override public void changed(ChangeEvent event, Actor actor) {
            game.getAudioDirector().setMuted(!game.getAudioDirector().isMuted());
            audio.setText(audioText());
        }});
        root.add(audio).colspan(2).width(230f).height(38f).padTop(8f).row();
        Label mouse = game.getUiTheme().label("Mouse: aim / left click attack / right click move — Touch: tap to move");
        root.add(mouse).colspan(2).padTop(10f).row();
        TextButton back = game.getUiTheme().button("BACK TO LOBBY");
        back.addListener(new ChangeListener() { @Override public void changed(ChangeEvent event, Actor actor) { game.showLobby(); }});
        root.add(back).colspan(2).width(190f).height(40f).padTop(20f);
        refreshBindings();
    }

    private void addBinding(Table root, String label, String action) {
        root.add(game.getUiTheme().label(label)).left().width(180f).padBottom(7f);
        TextButton button = game.getUiTheme().button("");
        button.addListener(new ChangeListener() { @Override public void changed(ChangeEvent event, Actor actor) {
            waitingFor = action; button.setText("PRESS A KEY...");
        }});
        buttons.put(action, button);
        root.add(button).width(140f).height(32f).padBottom(7f).row();
    }

    private void refreshBindings() {
        buttons.forEach((action, button) -> button.setText(ControlBindings.display(action)));
    }

    private String audioText() { return game.getAudioDirector().isMuted() ? "SOUND: MUTED" : "SOUND: ON"; }

    @Override public void show() {
        super.show();
        Gdx.input.setInputProcessor(new InputMultiplexer(stage, rebinder));
    }
}
