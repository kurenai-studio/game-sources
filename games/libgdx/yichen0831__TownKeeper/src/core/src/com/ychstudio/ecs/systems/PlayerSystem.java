package com.ychstudio.ecs.systems;

import com.badlogic.ashley.core.ComponentMapper;
import com.badlogic.ashley.core.Entity;
import com.badlogic.ashley.core.Family;
import com.badlogic.ashley.systems.IteratingSystem;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.physics.box2d.Body;
import com.ychstudio.builders.ActorBuilder;
import com.ychstudio.ecs.components.AnimationComponent;
import com.ychstudio.ecs.components.LifeComponent;
import com.ychstudio.ecs.components.PlayerComponent;
import com.ychstudio.ecs.components.RigidBodyComponent;
import com.ychstudio.ecs.components.StateComponent;
import com.ychstudio.ecs.components.TransformComponent;
import com.ychstudio.gamesys.GameManager;
import com.ychstudio.jobsys.Job;
import com.ychstudio.jobsys.Job.Type;

public class PlayerSystem extends IteratingSystem {

    protected ComponentMapper<PlayerComponent> playerM = ComponentMapper.getFor(PlayerComponent.class);
    protected ComponentMapper<LifeComponent> lifeM = ComponentMapper.getFor(LifeComponent.class);
    protected ComponentMapper<RigidBodyComponent> rigidBodyM = ComponentMapper.getFor(RigidBodyComponent.class);
    protected ComponentMapper<StateComponent> stateM = ComponentMapper.getFor(StateComponent.class);
    protected ComponentMapper<AnimationComponent> animationM = ComponentMapper.getFor(AnimationComponent.class);

    private final Vector2 tmpV = new Vector2();

    public PlayerSystem() {
        super(Family.all(PlayerComponent.class, LifeComponent.class, RigidBodyComponent.class, StateComponent.class,
                TransformComponent.class, AnimationComponent.class).get());
    }

    @Override
    protected void processEntity(Entity entity, float deltaTime) {
        PlayerComponent player = playerM.get(entity);
        LifeComponent life = lifeM.get(entity);
        RigidBodyComponent rigidBody = rigidBodyM.get(entity);
        StateComponent state = stateM.get(entity);
        AnimationComponent animation = animationM.get(entity);

        Body body = rigidBody.body;

        if (life.isDead()) {
            state.setState(PlayerComponent.STATE_DIE);
        } else {

            // Controls
            if (Gdx.input.isKeyPressed(Input.Keys.UP) || Gdx.input.isKeyPressed(Input.Keys.W)) {
                body.applyLinearImpulse(tmpV.set(0, player.speed), body.getWorldCenter(), true);
            }

            if (Gdx.input.isKeyPressed(Input.Keys.DOWN) || Gdx.input.isKeyPressed(Input.Keys.S)) {
                body.applyLinearImpulse(tmpV.set(0, -player.speed), body.getWorldCenter(), true);
            }

            if (Gdx.input.isKeyPressed(Input.Keys.LEFT) || Gdx.input.isKeyPressed(Input.Keys.A)) {
                body.applyLinearImpulse(tmpV.set(-player.speed, 0), body.getWorldCenter(), true);
            }

            if (Gdx.input.isKeyPressed(Input.Keys.RIGHT) || Gdx.input.isKeyPressed(Input.Keys.D)) {
                body.applyLinearImpulse(tmpV.set(player.speed, 0), body.getWorldCenter(), true);
            }

            // make job vacancy
            if (Gdx.input.isKeyJustPressed(Input.Keys.SPACE)) {
                // job function
                if (player.gold > 0) {
                    player.gold--;
                    // TODO create job should be done by the store
                    Job job = new Job(Type.HUNTER, new Vector2(new Vector2(body.getPosition().x + 2, body.getPosition().y - 1)));
                    ActorBuilder actorBuilder = ActorBuilder.getInstance(body.getWorld(), getEngine());
                    actorBuilder.createNPCItem(body.getPosition(), job);
                }
            }

            // limit velocity
            if (body.getLinearVelocity().len2() > player.maxSpeed * player.maxSpeed) {
                tmpV.set(body.getLinearVelocity());
                tmpV.setLength(player.maxSpeed);
                body.setLinearVelocity(tmpV);
            }

            // limit player's moving area
            if (body.getPosition().x < GameManager.moveBound.x + PlayerComponent.radius) {
                body.setTransform(GameManager.moveBound.x + PlayerComponent.radius, body.getPosition().y,
                        body.getAngle());
            } else if (body.getPosition().x > GameManager.moveBound.width - PlayerComponent.radius) {
                body.setTransform(GameManager.moveBound.width - PlayerComponent.radius, body.getPosition().y,
                        body.getAngle());
            }
            if (body.getPosition().y < GameManager.moveBound.y + PlayerComponent.radius) {
                body.setTransform(body.getPosition().x, GameManager.moveBound.y + PlayerComponent.radius,
                        body.getAngle());
            } else if (body.getPosition().y > GameManager.moveBound.height - PlayerComponent.radius) {
                body.setTransform(body.getPosition().x, GameManager.moveBound.height - PlayerComponent.radius,
                        body.getAngle());
            }

            if (body.getLinearVelocity().len2() > 0.1f) {
                state.setState(PlayerComponent.STATE_MOVE);
            } else {
                state.setState(PlayerComponent.STATE_IDLE);
            }

            // update player's location to GameManager for the camera to follow
            GameManager.playerCurrentPos.set(body.getPosition().x, body.getPosition().y);

        }

        switch (state.getState()) {
            case PlayerComponent.STATE_MOVE:
                if (Math.abs(body.getLinearVelocity().x) > Math.abs(body.getLinearVelocity().y)) {
                    animation.setCurrentAnimation(body.getLinearVelocity().x > 0 ? PlayerComponent.ANIM_MOVE_RIGHT
                            : PlayerComponent.ANIM_MOVE_LEFT);
                } else {
                    animation.setCurrentAnimation(body.getLinearVelocity().y > 0 ? PlayerComponent.ANIM_MOVE_UP
                            : PlayerComponent.ANIM_MOVE_DOWN);
                }
                break;
            case PlayerComponent.STATE_DIE:
                animation.setCurrentAnimation(PlayerComponent.ANIM_DIE_1);
                break;
            case PlayerComponent.STATE_IDLE:
                switch (animation.getCurrentAnimation()) {
                    case PlayerComponent.ANIM_MOVE_UP:
                        animation.setCurrentAnimation(PlayerComponent.ANIM_IDLE_UP);
                        break;
                    case PlayerComponent.ANIM_MOVE_LEFT:
                        animation.setCurrentAnimation(PlayerComponent.ANIM_IDLE_LEFT);
                        break;
                    case PlayerComponent.ANIM_MOVE_DOWN:
                        animation.setCurrentAnimation(PlayerComponent.ANIM_IDLE_DOWN);
                        break;
                    case PlayerComponent.ANIM_MOVE_RIGHT:
                        animation.setCurrentAnimation(PlayerComponent.ANIM_IDLE_RIGHT);
                        break;
                    default:
                        break;
                }
            default:
                break;
        }
    }

}
