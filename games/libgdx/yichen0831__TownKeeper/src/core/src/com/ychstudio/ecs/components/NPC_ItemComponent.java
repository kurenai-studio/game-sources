package com.ychstudio.ecs.components;

import com.badlogic.ashley.core.Component;
import com.badlogic.gdx.math.Vector2;
import com.ychstudio.jobsys.Job;

public class NPC_ItemComponent implements Component {
    
    public static final int STATE_CREATE = 0;
    public static final int STATE_WAIT = 1;
    public static final int STATE_TAKE = 2;
    
    public static final float radius = 0.36f;
    public Job job;
    
    private boolean taken;
    
    public Vector2 spawnPos;

    public NPC_ItemComponent(Vector2 pos, Job job) {
        this.job = job;
        taken = false;
        spawnPos = new Vector2(pos);
    }
    
    public void taken() {
        taken = true;
    }
    
    public boolean isTaken() {
        return taken;
    }
}
