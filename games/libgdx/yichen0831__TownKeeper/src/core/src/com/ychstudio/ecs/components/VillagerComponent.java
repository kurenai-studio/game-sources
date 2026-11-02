package com.ychstudio.ecs.components;

import com.badlogic.ashley.core.Component;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector2;
import com.ychstudio.ai.Node;
import com.ychstudio.jobsys.Job;

public class VillagerComponent implements Component {

    public static final int STATE_IDLE = 0;
    public static final int STATE_WANDER = 1;
    public static final int STATE_RECRUIT = 2;
    public static final int STATE_DIE = 3;
    
    public static final int ANIM_IDLE_UP = 0;
    public static final int ANIM_IDLE_DOWN = 1;
    public static final int ANIM_IDLE_LEFT = 2;
    public static final int ANIM_IDLE_RIGHT = 3;
    public static final int ANIM_MOVE_UP = 4;
    public static final int ANIM_MOVE_DOWN = 5;
    public static final int ANIM_MOVE_LEFT = 6;
    public static final int ANIM_MOVE_RIGHT = 7;
    public static final int ANIM_DIE_1 = 8;
    public static final int ANIM_DIE_2 = 9;
    public static final int ANIM_DIE_3 = 10;
    
    public static float radius = 0.48f;

    public TentComponent tent;

    public float speed = 1f;
    public float maxSpeed = 2f;

    private float randomTimer;

    public Vector2 targetPos;
    public Vector2 targetDir;
    
    // looking for a job every 1 second
    public float jobLookingTimer = 1f;

    // current moving-toward position of A* path finding node
    public Node pathNode;
    
    public Job acquiredJob = null;

    public VillagerComponent(TentComponent tent) {
        this.tent = tent;

        randomTimer = MathUtils.random(1f, 5f);
        targetPos = new Vector2(tent.pos);
        targetDir = new Vector2();
    }

    public boolean isRandomTimerUp() {
        return randomTimer <= 0;
    }

    public void updateRandomTimer(float delta) {
        randomTimer -= delta;
    }

    public void resetRandomTimer() {
        randomTimer = MathUtils.random(1f, 5f);
    }

    public void makeRandomTimerUp() {
        randomTimer = 0;
    }

    public void makeRandomTimerForever() {
        randomTimer = Float.MAX_VALUE;
    }

}
