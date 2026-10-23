package net.zachwalker.ballsort.entities;

import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import net.zachwalker.ballsort.util.Constants;
import net.zachwalker.ballsort.util.Enums;


public class Valve {

    float positionX;
    float positionY;
    float width;
    float height;
    Enums.ValveState valveState;

    public Valve(float positionX) {
        this.positionX = positionX;
        positionY = Constants.CHUTE_HEIGHT;
        width = Constants.VALVE_WIDTH;
        height = Constants.VALVE_HEIGHT;
        valveState = Enums.ValveState.CLOSED;
    }

    public void render(ShapeRenderer renderer) {
        switch (valveState) {
            case CLOSED:
                drawClosedValve(renderer);
                break;
            case OPEN:
                drawOpenValve(renderer);
                break;
        }
    }

    public void switchValveState() {
        switch (valveState) {
            case CLOSED:
                valveState = Enums.ValveState.OPEN;
                break;
            case OPEN:
                valveState = Enums.ValveState.CLOSED;
                break;
        }
    }

    private void drawClosedValve(ShapeRenderer renderer) {
        renderer.begin(ShapeRenderer.ShapeType.Filled);
        renderer.setColor(Constants.VALVE_COLOR);
        renderer.rect(positionX, positionY, width, height);
        renderer.end();
    }

    private void drawOpenValve(ShapeRenderer renderer) {
        renderer.begin(ShapeRenderer.ShapeType.Filled);
        renderer.setColor(Constants.VALVE_COLOR);
        renderer.rect(positionX, positionY, 0.0f, 0.0f, width, height, 1.0f, 1.0f, Constants.VALVE_ROTATION);
        renderer.end();
    }

}
