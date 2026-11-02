package com.ychstudio.ecs.components;

import com.badlogic.ashley.core.Component;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector2;

public class FarmComponent implements Component {

    private float spawnTime; // time span to spawn a new animal
    public float countDown; // counting time left to spawn a new animal

    private int maxAnimals; // max animals the farms can hold
    public int currentAnimals; // current animals the farm holds

    public Rectangle rectangle; // the rectangle area of the farm

    public final Vector2 pos = new Vector2();

    public FarmComponent(Rectangle rectangle) {
        this(rectangle, 10f, 8);
    }

    public FarmComponent(Rectangle rectangle, float spawnTime, int maxAnimals) {
        this.maxAnimals = maxAnimals;
        this.spawnTime = spawnTime;
        this.rectangle = rectangle;

        countDown = 0;
        currentAnimals = 0;

        pos.set(rectangle.x + rectangle.width / 2f, rectangle.y + rectangle.height / 2f);
    }

    public boolean isFull() {
        return currentAnimals >= maxAnimals;
    }

    public boolean isTimeUp() {
        return countDown <= 0;
    }

    public boolean canSpawn() {
        return !isFull() && isTimeUp();
    }

    public void resetCountDown() {
        countDown = spawnTime;
    }
}
