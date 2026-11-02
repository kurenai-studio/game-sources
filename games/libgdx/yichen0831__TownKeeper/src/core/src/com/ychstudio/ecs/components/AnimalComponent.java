package com.ychstudio.ecs.components;

import com.badlogic.ashley.core.Component;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector2;

public class AnimalComponent implements Component {

    public static enum Kind {
        CHICKEN, COW, SHEEP;

        public static Kind getRandomKind() {
            return Kind.values()[MathUtils.random(Kind.values().length - 1)];
        }
    }
    
    public static enum Direction {
        UP(0, 1f),
        DOWN(0, -1f),
        LEFT(-1f, 0),
        RIGHT(1f, 0);
        
        private final Vector2 dir;
        
        private Direction(float x, float y) {
            dir = new Vector2(x, y);
        }
        
        public static Direction getRandomDirection() {
            return Direction.values()[MathUtils.random(Direction.values().length - 1)];
        }
        
        public Vector2 getDir() {
            return dir;
        }
    }
    
    public static final int STATE_IDLE = 0;
    public static final int STATE_MOVE = 1; 
    
    public static final int ANIM_IDLE_UP = 0;
    public static final int ANIM_IDLE_DOWN = 1;
    public static final int ANIM_IDLE_LEFT = 2;
    public static final int ANIM_IDLE_RIGHT = 3;
    public static final int ANIM_MOVE_UP = 4;
    public static final int ANIM_MOVE_DOWN = 5;
    public static final int ANIM_MOVE_LEFT = 6;
    public static final int ANIM_MOVE_RIGHT = 7;

    private Kind kind;

    public static float radius = 0.48f;

    public FarmComponent farm;

    public float speed = 1f;
    public float maxSpeed = 1f;
    
    private Direction currentDir;

    private float randomTimer;

    public AnimalComponent(FarmComponent farm) {
        this(farm, Kind.getRandomKind());
    }

    public AnimalComponent(FarmComponent farm, Kind kind) {
        this.farm = farm;
        this.kind = kind;

        currentDir = Direction.getRandomDirection();
        
        randomTimer = MathUtils.randomTriangular(1f, 3f);
    }

    public Kind getKind() {
        return kind;
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
    
    public Vector2 getCurrentDir() {
        return currentDir.getDir();
    }
    
    public Vector2 getNewDir() {
        currentDir = Direction.getRandomDirection();
        return currentDir.getDir();
    }

}
