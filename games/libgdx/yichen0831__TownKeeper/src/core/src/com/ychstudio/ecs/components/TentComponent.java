package com.ychstudio.ecs.components;

import com.badlogic.ashley.core.Component;
import com.badlogic.gdx.math.Vector2;

public class TentComponent implements Component {

    private float spawnTime; // time span to spawn a new villager
    public float countDown; // counting time left to spawn a new villager

    private int maxVillagers; // max number of villagers the tent can hold
    public int currentVillagers; // current number of villagers the tent holds

    public final Vector2 pos = new Vector2();

    public TentComponent(Vector2 pos) {
        this(pos, 10f, 3);
    }

    public TentComponent(Vector2 pos, float spawnTime, int maxVillagers) {
        this.spawnTime = spawnTime;
        this.countDown = spawnTime;
        this.maxVillagers = maxVillagers;
        this.currentVillagers = 0;
        this.pos.set(pos);
    }

    public boolean isFull() {
        return currentVillagers >= maxVillagers;
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
    
    public void minusOneVillager() {
    	minusVillager(1);
    }
    
    public void minusVillager(int number) {
    	currentVillagers -= number;
    	if (currentVillagers < 0) {
			currentVillagers = 0;
		}
    }

}
