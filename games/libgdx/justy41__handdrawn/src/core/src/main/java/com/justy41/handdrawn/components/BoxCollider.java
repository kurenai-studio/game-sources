package com.justy41.handdrawn.components;

import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector2;

import java.util.HashMap;

public class BoxCollider extends Component{
    public Rectangle rect;
    public Vector2 relativePosition;
    public HashMap<String, Boolean> touching;
    public boolean isTrigger;
    public Texture debugTexture;

    public BoxCollider() {
        rect = null;
        touching = new HashMap<>();
        touching.put("right", false);
        touching.put("left", false);
        touching.put("up", false);
        touching.put("down", false);
        isTrigger = false;
        debugTexture = new Texture("red_pixel.png");
    }

    public BoxCollider(float relX, float relY, float width, float height) {
        rect = new Rectangle(relX, relY, width, height);
        relativePosition = new Vector2(relX, relY);
        touching = new HashMap<>();
        touching.put("right", false);
        touching.put("left", false);
        touching.put("up", false);
        touching.put("down", false);
        isTrigger = false;
        debugTexture = new Texture("red_pixel.png");
    }

    public BoxCollider(float relX, float relY, float width, float height, boolean isTrigger) {
        rect = new Rectangle(relX, relY, width, height);
        relativePosition = new Vector2(relX, relY);
        touching = new HashMap<>();
        touching.put("right", false);
        touching.put("left", false);
        touching.put("up", false);
        touching.put("down", false);
        this.isTrigger = isTrigger;
        debugTexture = new Texture("red_pixel.png");
    }
}
