package com.blackbird.game;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;

public class Controles {
    private Player player;
    private Main main;

    public Controles(Player player, Main main) {
        this.player = player;
        this.main = main;
    }

    public void update() {
        if (Gdx.input.isKeyPressed(Input.Keys.W)) {
            player.speedUp = true;
            player.checkSpeed();
            player.accelerate();
        } else if (Gdx.input.isKeyPressed(Input.Keys.S)) {
            player.speedUp = false;
            player.checkSpeed();
            player.decelerate();
        } else {
            player.decelerate();
        }

        if (Gdx.input.isKeyPressed(Input.Keys.A)) {
            player.setAngle(player.getAngle() + 2.0f);
        }
        if (Gdx.input.isKeyPressed(Input.Keys.D)) {
            player.setAngle(player.getAngle() - 2.0f);
        }

        if (Gdx.input.isKeyJustPressed(Input.Keys.SPACE)) {
            main.atirar(); // Chama o método atirar na classe Main
        }
    }
}