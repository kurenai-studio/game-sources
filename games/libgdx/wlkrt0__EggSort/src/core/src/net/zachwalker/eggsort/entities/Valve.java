package net.zachwalker.eggsort.entities;

import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Vector2;

import net.zachwalker.eggsort.util.Assets;
import net.zachwalker.eggsort.util.DrawingHelpers;
import net.zachwalker.eggsort.util.Enums;

public class Valve {

    private Vector2 position;
    Enums.ValveState valveState;
    private Enums.EggType eggType;

    public Valve(Vector2 position, Enums.EggType eggType) {
        this.position = new Vector2(position);
        this.eggType = eggType;
        valveState = Enums.ValveState.CLOSED;
    }

    public void render(SpriteBatch batch) {
        switch (eggType) {
            case WHITE:
                if (valveState == Enums.ValveState.CLOSED) {
                    DrawingHelpers.drawSprite(batch, Assets.singleton.images.valveLeftClosed, position);
                } else {
                    DrawingHelpers.drawSprite(batch, Assets.singleton.images.valveLeftOpen, position);
                }
                break;
            case BROWN:
                if (valveState == Enums.ValveState.CLOSED) {
                    DrawingHelpers.drawSprite(batch, Assets.singleton.images.valveRightClosed, position);
                } else {
                    DrawingHelpers.drawSprite(batch, Assets.singleton.images.valveRightOpen, position);
                }
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

}
