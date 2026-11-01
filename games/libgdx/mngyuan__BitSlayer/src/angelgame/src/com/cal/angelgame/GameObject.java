package com.cal.angelgame;

import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector2;

public abstract class GameObject {
	/**
	 * Objects that will be seen on the screen as well as the background 
	 * will derive from GameObject
	 * 
	 */
	
	public final Vector2 position;
	public final Rectangle bounds;
	public float width; //quickfix
	public float height; //quickfix
	
	public GameObject(float x, float y, float width, float height)
	{
		this.position = new Vector2(x, y);
		this.bounds = new Rectangle(x - width/2, y - height/2, width, height);

        this.width = width;
        this.height = height;
	}
}
