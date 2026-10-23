package net.zachwalker.ballsort.entities;


import com.badlogic.gdx.InputAdapter;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer.ShapeType;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.viewport.Viewport;

import net.zachwalker.ballsort.BallSortScreen;
import net.zachwalker.ballsort.util.Assets;
import net.zachwalker.ballsort.util.Constants;


public class TouchTargets extends InputAdapter{

    private Viewport viewport;
    private Array<Rectangle> valveTargets;
    private Array<Valve> valves;
    private Assets assets;
    private Rectangle gotoLevelTarget;
    private Rectangle toggleSoundTarget;
    private BallSortScreen ballSortScreen;

    //note that touch targets must be initalized AFTER valves AND assets
    //also note that we need to pass the viewport to the touchtargets class since it will be
    //receiving touches and will need to unproject the touch input using the viewport
    //also need to pass in assets since it will be playing sounds when valves are toggled
    public TouchTargets(Viewport viewport, Array<Valve> valves, Assets assets, BallSortScreen ballSortScreen) {
        this.ballSortScreen = ballSortScreen;
        this.viewport = viewport;
        this.valves = valves;
        this.assets = assets;
        valveTargets = new Array<Rectangle>();
        //for every valve, add a corresponding touch target
        for (Valve valve : valves) {
            valveTargets.add(new Rectangle(
                    valve.positionX - (Constants.VALVE_WIDTH),
                    valve.positionY - (Constants.VALVE_WIDTH * 5.0f),
                    Constants.VALVE_WIDTH * 3.0f,
                    Constants.VALVE_WIDTH * 3.0f,
                    ShapeType.Line,
                    Constants.TOUCHTARGET_COLOR)
            );
        }

        //add the gotoHighLevel button
        gotoLevelTarget = new Rectangle(
                Constants.WORLD_WIDTH - Constants.CHUTE_MARGIN,
                Constants.WORLD_HEIGHT / 2.0f,
                Constants.VALVE_WIDTH,
                Constants.VALVE_WIDTH,
                ShapeType.Line,
                Constants.TOUCHTARGET_COLOR
        );


        //add the mute button
        toggleSoundTarget = new Rectangle(
                Constants.WORLD_WIDTH - Constants.CHUTE_MARGIN,
                Constants.WORLD_HEIGHT / 2.0f - 2.0f * Constants.VALVE_WIDTH,
                Constants.VALVE_WIDTH,
                Constants.VALVE_WIDTH,
                ShapeType.Line,
                Constants.TOUCHTARGET_COLOR
        );
    }

    @Override
    public boolean touchDown(int screenX, int screenY, int pointer, int button) {
        //get the coordinates of the touchDown event in OUR world coords (not screen coords)
        Vector2 viewportPosition = viewport.unproject(new Vector2(screenX, screenY));

        //check the gotoLevel target to see if it was hit (touch point was within its radius)
        if (targetWasHit(viewportPosition, gotoLevelTarget)) {
            assets.sounds.playSound(assets.sounds.button);
            ballSortScreen.gotoHighLevel();
        }

        //check the toggleSound target to see if it was hit (touch point was within its radius)
        if (targetWasHit(viewportPosition, toggleSoundTarget)) {
            if (toggleSoundTarget.color.equals(Constants.TOUCHTARGET_COLOR)) {
                toggleSoundTarget.color = Color.RED;
            } else {
                toggleSoundTarget.color = Constants.TOUCHTARGET_COLOR;
            }
            assets.sounds.playSound(assets.sounds.button);
            assets.sounds.toggleMute();
        }

        //check each touchTarget to see if any were hit (touch point was within its radius)
        for (int i = 0; i < valveTargets.size; i++) {
            if (targetWasHit(viewportPosition, valveTargets.get(i))) {
                //since our touchTargets and valves arrays are aligned, we can use the same iterator
                valves.get(i).switchValveState();
                assets.sounds.playSound(assets.sounds.valve);
            }
        }
        return true;
    }

    //no update method on the TouchTargets, since they aren't going anywhere

    public void render(ShapeRenderer renderer) {
        for (Rectangle valveTarget : valveTargets) {
            valveTarget.render(renderer);
        }
        gotoLevelTarget.render(renderer);
        toggleSoundTarget.render(renderer);
        drawIconDetails(renderer);
    }

    private boolean targetWasHit(Vector2 viewportPosition, Rectangle touchTarget) {
        Vector2 targetCenter = new Vector2(
                touchTarget.positionX + touchTarget.width / 2.0f,
                touchTarget.positionY + touchTarget.height / 2.0f
        );
        float targetRadius = Math.min(touchTarget.width, touchTarget.height) / 2.0f;
        //check the touchTarget to see if it was hit (touch point was within its radius)
        return (viewportPosition.dst(targetCenter) <= targetRadius);
    }

    /* draw insides of gotoLevel and mute buttons.
    verbose but avoids use of textures altogether in this version */
    private void drawIconDetails(ShapeRenderer renderer) {
        renderer.begin(ShapeType.Line);
        renderer.setColor(Constants.TOUCHTARGET_COLOR);

        //draw fast forward icon (two triangles)
        renderer.triangle(
                gotoLevelTarget.positionX + 3.0f,
                gotoLevelTarget.positionY + 5.0f,
                gotoLevelTarget.positionX + 3.0f,
                gotoLevelTarget.positionY + 15.0f,
                gotoLevelTarget.positionX + 10.0f,
                gotoLevelTarget.positionY + 10.0f
        );
        renderer.triangle(
                gotoLevelTarget.positionX + 10.0f,
                gotoLevelTarget.positionY + 5.0f,
                gotoLevelTarget.positionX + 10.0f,
                gotoLevelTarget.positionY + 15.0f,
                gotoLevelTarget.positionX + 17.0f,
                gotoLevelTarget.positionY + 10.0f
        );

        //draw mute / toggle sound icon (six lines)
        //left line
        renderer.line(
                toggleSoundTarget.positionX + 5.0f,
                toggleSoundTarget.positionY + 8.0f,
                toggleSoundTarget.positionX + 5.0f,
                toggleSoundTarget.positionY + 12.0f
        );
        //right line
        renderer.line(
                toggleSoundTarget.positionX + 13.0f,
                toggleSoundTarget.positionY + 3.0f,
                toggleSoundTarget.positionX + 13.0f,
                toggleSoundTarget.positionY + 17.0f
        );
        //top line
        renderer.line(
                toggleSoundTarget.positionX + 5.0f,
                toggleSoundTarget.positionY + 12.0f,
                toggleSoundTarget.positionX + 8.0f,
                toggleSoundTarget.positionY + 12.0f
        );
        //bottom line
        renderer.line(
                toggleSoundTarget.positionX + 5.0f,
                toggleSoundTarget.positionY + 8.0f,
                toggleSoundTarget.positionX + 8.0f,
                toggleSoundTarget.positionY + 8.0f
        );
        //top diagonal
        renderer.line(
                toggleSoundTarget.positionX + 8.0f,
                toggleSoundTarget.positionY + 12.0f,
                toggleSoundTarget.positionX + 13.0f,
                toggleSoundTarget.positionY + 17.0f
        );
        //bottom diagonal
        renderer.line(
                toggleSoundTarget.positionX + 8.0f,
                toggleSoundTarget.positionY + 8.0f,
                toggleSoundTarget.positionX + 13.0f,
                toggleSoundTarget.positionY + 3.0f
        );
        renderer.end();
    }

}
