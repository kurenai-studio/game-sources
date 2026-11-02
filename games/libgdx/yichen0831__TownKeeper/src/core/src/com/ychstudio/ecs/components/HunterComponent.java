package com.ychstudio.ecs.components;

import com.badlogic.ashley.core.Component;

public class HunterComponent implements Component {
    
    public static final int STATE_IDLE = 0;
    public static final int STATE_WALK = 1;
    public static final int STATE_ATTACK = 2;
    public static final int STATE_DIE = 3;
    
    public static final int ANIM_IDLE_UP = 0;
    public static final int ANIM_IDLE_DOWN = 1;
    public static final int ANIM_IDLE_LEFT = 2;
    public static final int ANIM_IDLE_RIGHT = 3;
    public static final int ANIM_WALK_UP = 4;
    public static final int ANIM_WALK_DOWN = 5;
    public static final int ANIM_WALK_LEFT = 6;
    public static final int ANIM_WALK_RIGHT = 7;
    public static final int ANIM_DIE_1 = 8;
    public static final int ANIM_DIE_2 = 9;
    public static final int ANIM_DIE_3 = 10;
    
    public static final float radius = 0.45f;
    
    public float speed = 1f;
    public float maxSpeed = 2f;

}
