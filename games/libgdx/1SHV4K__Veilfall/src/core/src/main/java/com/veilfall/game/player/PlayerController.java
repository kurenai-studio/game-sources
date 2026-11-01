package com.veilfall.game.player;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.InputAdapter;
import com.badlogic.gdx.math.Intersector;
import com.badlogic.gdx.math.Plane;
import com.badlogic.gdx.math.Vector3;
import com.veilfall.game.enemies.EnemyManager;
import com.veilfall.game.rendering.CameraController;

public final class PlayerController extends InputAdapter {
    private final Player player;
    private final PlayerCombat combat;
    private final EnemyManager enemies;
    private final CameraController cameraController;
    private final Plane groundPlane = new Plane(Vector3.Y, 0f);
    private final Vector3 worldPoint = new Vector3();
    private final Vector3 moveTarget = new Vector3();
    private boolean movingToClick;

    public PlayerController(Player player, PlayerCombat combat, EnemyManager enemies,
                            CameraController cameraController) {
        this.player = player;
        this.combat = combat;
        this.enemies = enemies;
        this.cameraController = cameraController;
    }

    public void update(float delta) {
        float horizontal = 0f;
        float depth = 0f;
        if (Gdx.input.isKeyPressed(ControlBindings.get("left"))) horizontal -= 1f;
        if (Gdx.input.isKeyPressed(ControlBindings.get("right"))) horizontal += 1f;
        if (Gdx.input.isKeyPressed(ControlBindings.get("up"))) depth -= 1f;
        if (Gdx.input.isKeyPressed(ControlBindings.get("down"))) depth += 1f;

        if (horizontal != 0f || depth != 0f) {
            movingToClick = false;
            float length = (float) Math.sqrt(horizontal * horizontal + depth * depth);
            float step = (float) player.getCharacter().getSpeed() * delta / length;
            player.move(horizontal * step, depth * step);
        } else if (movingToClick && player.moveToward(moveTarget.x, moveTarget.z, delta)) {
            movingToClick = false;
        }
        if (Gdx.input.isButtonJustPressed(Input.Buttons.LEFT)) {
            combat.attack(enemies);
        }
        if (Gdx.input.isKeyJustPressed(ControlBindings.get("ability_q"))) {
            combat.abilityQ(enemies);
        }
        if (Gdx.input.isKeyJustPressed(ControlBindings.get("ability_e"))) {
            combat.abilityE(enemies);
        }
        if (Gdx.input.isKeyJustPressed(ControlBindings.get("ability_r"))) {
            combat.abilityR();
        }
        if (Gdx.input.isKeyJustPressed(ControlBindings.get("dodge"))) {
            combat.dodge(horizontal, depth);
        }
    }

    @Override
    public boolean touchDown(int screenX, int screenY, int pointer, int button) {
        boolean touchMove = Gdx.input.isPeripheralAvailable(Input.Peripheral.MultitouchScreen)
                && button == Input.Buttons.LEFT;
        if (button != Input.Buttons.RIGHT && !touchMove) return false;
        if (!projectToGround(screenX, screenY, worldPoint)) return false;
        moveTarget.set(worldPoint);
        movingToClick = true;
        player.faceTowards(worldPoint.x, worldPoint.z);
        return true;
    }

    @Override
    public boolean mouseMoved(int screenX, int screenY) {
        if (projectToGround(screenX, screenY, worldPoint)) {
            player.faceTowards(worldPoint.x, worldPoint.z);
        }
        return false;
    }

    private boolean projectToGround(int screenX, int screenY, Vector3 destination) {
        return Intersector.intersectRayPlane(cameraController.getCamera().getPickRay(screenX, screenY),
                groundPlane, destination);
    }
}
