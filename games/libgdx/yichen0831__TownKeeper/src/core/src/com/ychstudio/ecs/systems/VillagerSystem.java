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
import com.ychstudio.ai.AStarPathFinding;
import com.ychstudio.builders.ActorBuilder;
import com.ychstudio.ecs.components.AnimationComponent;
import com.ychstudio.ecs.components.LifeComponent;
import com.ychstudio.ecs.components.RigidBodyComponent;
import com.ychstudio.ecs.components.StateComponent;
import com.ychstudio.ecs.components.VillagerComponent;
import com.ychstudio.gamesys.GameManager;
import com.ychstudio.jobsys.Job;
import com.ychstudio.jobsys.JobBulletin;
import com.ychstudio.utils.MyUtils;

public class VillagerSystem extends IteratingSystem {

    protected ComponentMapper<VillagerComponent> villagerM = ComponentMapper.getFor(VillagerComponent.class);
    protected ComponentMapper<LifeComponent> lifeM = ComponentMapper.getFor(LifeComponent.class);
    protected ComponentMapper<RigidBodyComponent> rigidBodyM = ComponentMapper.getFor(RigidBodyComponent.class);
    protected ComponentMapper<StateComponent> stateM = ComponentMapper.getFor(StateComponent.class);
    protected ComponentMapper<AnimationComponent> animationM = ComponentMapper.getFor(AnimationComponent.class);

    private final Vector2 tmpV1 = new Vector2();
    private final Vector2 tmpV2 = new Vector2();
    private boolean hitWall = false;

    public VillagerSystem() {
        super(Family.all(VillagerComponent.class, LifeComponent.class, RigidBodyComponent.class, AnimationComponent.class, StateComponent.class)
                .get());
    }

    @Override
    protected void processEntity(Entity entity, float deltaTime) {
        VillagerComponent villager = villagerM.get(entity);
        LifeComponent life = lifeM.get(entity);
        StateComponent state = stateM.get(entity);
        AnimationComponent animation = animationM.get(entity);
        RigidBodyComponent rigidBody = rigidBodyM.get(entity);
        Body body = rigidBody.body;

        villager.updateRandomTimer(deltaTime);
        if (villager.isRandomTimerUp()) {
            villager.resetRandomTimer();
            state.setState(MyUtils.chooseRandom(VillagerComponent.STATE_IDLE, VillagerComponent.STATE_WANDER));
            if (state.getState() == VillagerComponent.STATE_WANDER) {
                // set a random target position
                setRandomTargetPos(villager, body.getPosition(), 3f, 6f);
                villager.makeRandomTimerForever();
            }
        }
        
        villager.jobLookingTimer -= deltaTime;
        if (villager.jobLookingTimer <= 0) {
            villager.jobLookingTimer = 1f;
            
            // try to get a job
            Job job = JobBulletin.getInstance().fetchJob();
            if (job != null) {
                // head to the job location
                villager.makeRandomTimerForever();
                villager.targetPos.set(job.location);
                setTargetPos(villager, body.getPosition());
                state.setState(VillagerComponent.STATE_WANDER);
            }
        }
        
        if (villager.acquiredJob != null) {
            villager.jobLookingTimer = Float.MAX_VALUE;
            state.setState(VillagerComponent.STATE_RECRUIT);
        }

        switch (state.getState()) {
            case VillagerComponent.STATE_IDLE:
                body.setLinearVelocity(0, 0);
                switch (animation.getCurrentAnimation()) {
                    case VillagerComponent.ANIM_MOVE_DOWN:
                        animation.setCurrentAnimation(VillagerComponent.ANIM_IDLE_DOWN);
                        break;
                    case VillagerComponent.ANIM_MOVE_UP:
                        animation.setCurrentAnimation(VillagerComponent.ANIM_IDLE_UP);
                        break;
                    case VillagerComponent.ANIM_MOVE_LEFT:
                        animation.setCurrentAnimation(VillagerComponent.ANIM_IDLE_LEFT);
                        break;
                    case VillagerComponent.ANIM_MOVE_RIGHT:
                        animation.setCurrentAnimation(VillagerComponent.ANIM_IDLE_RIGHT);
                        break;
                    default:
                        break;
                }
                break;
            case VillagerComponent.STATE_RECRUIT:
                ActorBuilder actorBuilder = ActorBuilder.getInstance(body.getWorld(), getEngine());
                actorBuilder.createHunter(body.getPosition().x, body.getPosition().y);

                villager.tent.minusOneVillager();
                body.getWorld().destroyBody(body);
                getEngine().removeEntity(entity);
                break;
            case VillagerComponent.STATE_WANDER:

                if (villager.pathNode == null) {
                    villager.makeRandomTimerUp();
                    break;
                }

                if (body.getPosition().dst(villager.pathNode.getPosition()) < 0.1f) {
                    villager.pathNode = villager.pathNode.nextNode;
                    break;
                }

                villager.targetDir.set(villager.pathNode.getPosition().x - body.getPosition().x,
                        villager.pathNode.getPosition().y - body.getPosition().y);

                body.applyLinearImpulse(tmpV1.set(villager.targetDir).scl(villager.speed), body.getWorldCenter(), true);
                if (body.getLinearVelocity().len2() > villager.maxSpeed * villager.maxSpeed) {
                    tmpV1.set(body.getLinearVelocity());
                    tmpV1.setLength(villager.maxSpeed);
                    body.setLinearVelocity(tmpV1);
                }
                
                if (Math.abs(body.getLinearVelocity().x) > Math.abs(body.getLinearVelocity().y)) {
                    animation.setCurrentAnimation(body.getLinearVelocity().x > 0 ? VillagerComponent.ANIM_MOVE_RIGHT : VillagerComponent.ANIM_MOVE_LEFT);
                }
                else {
                    animation.setCurrentAnimation(body.getLinearVelocity().y > 0 ? VillagerComponent.ANIM_MOVE_UP : VillagerComponent.ANIM_MOVE_DOWN);
                }
                break;
            case VillagerComponent.STATE_DIE:
                animation.setCurrentAnimation(VillagerComponent.ANIM_DIE_1);
            default:
                break;
        }

    }

    protected boolean checkHitWall(VillagerComponent villager, Body body) {
        hitWall = false;
        RayCastCallback rayCastCallback = new RayCastCallback() {

            @Override
            public float reportRayFixture(Fixture fixture, Vector2 point, Vector2 normal, float fraction) {
                if (fixture.getFilterData().categoryBits == GameManager.WALL_BIT) {
                    hitWall = true;
                }
                return 0;
            }
        };

        tmpV1.set(body.getPosition());
        tmpV2.set(villager.targetDir).setLength(0.5f).add(tmpV1);

        body.getWorld().rayCast(rayCastCallback, tmpV1, tmpV2);
        if (hitWall) {
            return true;
        }

        if (villager.targetDir.x != 0) {
            tmpV2.set(villager.targetDir.x, 0).setLength(0.5f).add(tmpV1);
            body.getWorld().rayCast(rayCastCallback, tmpV1, tmpV2);
            if (hitWall) {
                return hitWall;
            }
        }

        if (villager.targetDir.y != 0) {
            tmpV2.set(0, villager.targetDir.y).setLength(0.5f).add(tmpV1);
            body.getWorld().rayCast(rayCastCallback, tmpV1, tmpV2);
        }

        return hitWall;
    }

    private void setRandomTargetPos(VillagerComponent villager, Vector2 currentPos, float minRadius, float maxRadius) {
        AStarPathFinding aStarPathFinding = AStarPathFinding.getInstance();

        float angle = MathUtils.random(360);
        float radius = MathUtils.random(minRadius, maxRadius);

        tmpV1.set(villager.tent.pos.x + MathUtils.sinDeg(angle) * radius,
                villager.tent.pos.y + MathUtils.cosDeg(angle) * radius);

        while (!aStarPathFinding.isWalkableAt(tmpV1)) {
            angle = MathUtils.random(360);
            radius = MathUtils.random(minRadius, maxRadius);
            tmpV1.set(villager.tent.pos.x + MathUtils.sinDeg(angle) * radius,
                    villager.tent.pos.y + MathUtils.cosDeg(angle) * radius);
        }

        villager.targetPos.set(tmpV1);
        villager.pathNode = aStarPathFinding.findPath(currentPos, tmpV1);
    }
    
    private void setTargetPos(VillagerComponent villager, Vector2 currentPos) {
        AStarPathFinding aStarPathFinding = AStarPathFinding.getInstance();
        villager.pathNode = aStarPathFinding.findPath(currentPos, villager.targetPos);
    }

}
