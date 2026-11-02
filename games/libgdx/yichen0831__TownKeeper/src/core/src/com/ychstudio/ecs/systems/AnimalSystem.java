package com.ychstudio.ecs.systems;

import com.badlogic.ashley.core.ComponentMapper;
import com.badlogic.ashley.core.Entity;
import com.badlogic.ashley.core.Family;
import com.badlogic.ashley.systems.IteratingSystem;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.physics.box2d.Body;
import com.badlogic.gdx.physics.box2d.Fixture;
import com.badlogic.gdx.physics.box2d.RayCastCallback;
import com.ychstudio.ecs.components.AnimalComponent;
import com.ychstudio.ecs.components.AnimationComponent;
import com.ychstudio.ecs.components.LifeComponent;
import com.ychstudio.ecs.components.RigidBodyComponent;
import com.ychstudio.ecs.components.StateComponent;
import com.ychstudio.gamesys.GameManager;
import com.ychstudio.utils.MyUtils;

public class AnimalSystem extends IteratingSystem {

    protected ComponentMapper<AnimalComponent> animalM = ComponentMapper.getFor(AnimalComponent.class);
    protected ComponentMapper<RigidBodyComponent> rigidBodyM = ComponentMapper.getFor(RigidBodyComponent.class);
    protected ComponentMapper<LifeComponent> lifeM = ComponentMapper.getFor(LifeComponent.class);
    protected ComponentMapper<StateComponent> stateM = ComponentMapper.getFor(StateComponent.class);
    protected ComponentMapper<AnimationComponent> animationM = ComponentMapper.getFor(AnimationComponent.class);
    
    private Vector2 tmpV1 = new Vector2(); 
    private Vector2 tmpV2 = new Vector2();
    
    private boolean hitWall = false;

    public AnimalSystem() {
        super(Family.all(AnimalComponent.class, RigidBodyComponent.class, LifeComponent.class, AnimationComponent.class, StateComponent.class)
                .get());
    }

    @Override
    protected void processEntity(Entity entity, float deltaTime) {
        AnimalComponent animal = animalM.get(entity);
        RigidBodyComponent rigidBody = rigidBodyM.get(entity);
        LifeComponent life = lifeM.get(entity);
        StateComponent state = stateM.get(entity);
        AnimationComponent animation = animationM.get(entity);
        
        Body body = rigidBody.body;
        
        animal.updateRandomTimer(deltaTime);
        if (animal.isRandomTimerUp()) {
            animal.resetRandomTimer();
            
            state.setState(MyUtils.chooseRandom(AnimalComponent.STATE_IDLE, AnimalComponent.STATE_MOVE));
            
            if (state.getState() == AnimalComponent.STATE_MOVE) {
                animal.getNewDir();
            }
        }
        
        switch (state.getState()) {
            case AnimalComponent.STATE_MOVE:
                tmpV1.set(animal.getCurrentDir());
                body.applyLinearImpulse(tmpV1.scl(animal.speed), body.getWorldCenter(), true);
                
                if (body.getLinearVelocity().len2() > animal.maxSpeed * animal.maxSpeed) {
                    tmpV1.set(body.getLinearVelocity());
                    tmpV1.setLength(animal.maxSpeed);
                    body.setLinearVelocity(tmpV1);
                }
                
                if (checkHitWall(body, animal.getCurrentDir())) {
                    animal.makeRandomTimerUp();
                }
                
                if (Math.abs(body.getLinearVelocity().x) > Math.abs(body.getLinearVelocity().y)) {
                    animation.setCurrentAnimation(body.getLinearVelocity().x > 0 ? AnimalComponent.ANIM_MOVE_RIGHT : AnimalComponent.ANIM_MOVE_LEFT);
                } else {
                    animation.setCurrentAnimation(body.getLinearVelocity().y > 0 ? AnimalComponent.ANIM_MOVE_UP : AnimalComponent.ANIM_MOVE_DOWN);
                }
                break;
            case AnimalComponent.STATE_IDLE:
                body.setLinearVelocity(0, 0);
                switch (animation.getCurrentAnimation()) {
                    case AnimalComponent.ANIM_MOVE_DOWN:
                        animation.setCurrentAnimation(AnimalComponent.ANIM_IDLE_DOWN);
                        break;
                    case AnimalComponent.ANIM_MOVE_UP:
                        animation.setCurrentAnimation(AnimalComponent.ANIM_IDLE_UP);
                        break;
                    case AnimalComponent.ANIM_MOVE_LEFT:
                        animation.setCurrentAnimation(AnimalComponent.ANIM_IDLE_LEFT);
                        break;
                    case AnimalComponent.ANIM_MOVE_RIGHT:
                        animation.setCurrentAnimation(AnimalComponent.ANIM_IDLE_RIGHT);
                        break;
                    default:
                        break;
                }
            default:
                break;
        }
        
        // limit the animal moving area
        if (body.getPosition().x < 0 + AnimalComponent.radius 
                || body.getPosition().x > GameManager.moveBound.width - AnimalComponent.radius
                || body.getPosition().y < 0 + AnimalComponent.radius
                || body.getPosition().y > GameManager.moveBound.height - AnimalComponent.radius) {
            body.setLinearVelocity(0, 0);
            body.setTransform(MathUtils.clamp(body.getPosition().x, 0 + AnimalComponent.radius, GameManager.moveBound.width - AnimalComponent.radius), 
                    MathUtils.clamp(body.getPosition().y, 0 + AnimalComponent.radius, GameManager.moveBound.height - AnimalComponent.radius), 0);
            animal.makeRandomTimerUp();
        }
    }

    private boolean checkHitWall(Body body, Vector2 dir) {
        hitWall = false;
        
        RayCastCallback rayCastCallBack = new RayCastCallback() {
            
            @Override
            public float reportRayFixture(Fixture fixture, Vector2 point, Vector2 normal, float fraction) {
                if (fixture.getFilterData().categoryBits == GameManager.WALL_BIT) {
                    hitWall = true;
                }
                return 0;
            }
        };
        
        body.getWorld().rayCast(rayCastCallBack, tmpV1.set(body.getPosition()), tmpV2.set(body.getPosition().x + dir.x / 2f, body.getPosition().y + dir.y / 2f));
        
        return hitWall;
    }

}
