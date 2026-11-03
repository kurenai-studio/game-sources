package com.justy41.handdrawn.components;

import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.math.Vector2;

public class SpriteRenderer extends Component{
    public Texture texture;
    public Vector2 origin;
    public boolean flipX;
    public boolean flipY;

    public SpriteRenderer(String texturePath) {
        texture = new Texture(texturePath);
        origin = new Vector2(0, 0);
        flipX = false;
        flipY = false;
    }

    public SpriteRenderer(String texturePath, boolean centeredOrigin) {
        texture = new Texture(texturePath);
        if(centeredOrigin) {
            origin = new Vector2((float)texture.getWidth()/2, (float)texture.getHeight()/2);
        }
        else {
            origin = new Vector2(0, 0);
        }

        flipX = false;
        flipY = false;
    }
}
