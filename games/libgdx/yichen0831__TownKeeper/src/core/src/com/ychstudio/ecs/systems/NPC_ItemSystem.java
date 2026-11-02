package com.ychstudio.ecs.systems;

import com.badlogic.ashley.core.ComponentMapper;
import com.badlogic.ashley.core.Entity;
import com.badlogic.ashley.core.Family;
import com.badlogic.ashley.systems.IteratingSystem;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.physics.box2d.Body;
import com.badlogic.gdx.physics.box2d.Filter;
import com.badlogic.gdx.physics.box2d.Fixture;
import com.ychstudio.ecs.components.NPC_ItemComponent;
import com.ychstudio.ecs.components.RigidBodyComponent;
import com.ychstudio.ecs.components.StateComponent;
import com.ychstudio.gamesys.GameManager;
import com.ychstudio.jobsys.Job;
import com.ychstudio.jobsys.JobBulletin;

public class NPC_ItemSystem extends IteratingSystem {

    protected ComponentMapper<NPC_ItemComponent> npc_ItemComponentM = ComponentMapper.getFor(NPC_ItemComponent.class);
    protected ComponentMapper<RigidBodyComponent> rigidBodyM = ComponentMapper.getFor(RigidBodyComponent.class);
    protected ComponentMapper<StateComponent> stateM = ComponentMapper.getFor(StateComponent.class);
    
    private Vector2 tmpV = new Vector2();
    
    public NPC_ItemSystem() {
        super(Family.all(NPC_ItemComponent.class, RigidBodyComponent.class, StateComponent.class).get());
    }

    @Override
    protected void processEntity(Entity entity, float deltaTime) {
        NPC_ItemComponent npc_ItemComponent= npc_ItemComponentM.get(entity);
        StateComponent state = stateM.get(entity);
        RigidBodyComponent rigidBody = rigidBodyM.get(entity);
        Body body = rigidBody.body;
        Job job = npc_ItemComponent.job;
        
        switch (state.getState()) {
			case NPC_ItemComponent.STATE_CREATE:
				// move to destination location and add to JobBulletin list
				float duration = 1.0f;
				float alpha = state.getStateTime() / duration;
				if (state.getStateTime() <= duration) {
					float sX = npc_ItemComponent.spawnPos.x;
					float sY = npc_ItemComponent.spawnPos.y;
					float tX = job.location.x;
					float tY = job.location.y;
					
					float bX = Math.signum(tX - sX) * 0.2f;
					float bY = Math.signum(tY - sY) * 0.1f + MathUtils.cos((float) (Math.PI * alpha)) * 0.2f;
					
					body.applyLinearImpulse(tmpV.set(bX, bY), body.getWorldCenter(), true);
				}
				else {
					state.setState(NPC_ItemComponent.STATE_WAIT);
					JobBulletin jobBulletin = JobBulletin.getInstance();
					jobBulletin.addNewJob(job);
				}
				break;
			case NPC_ItemComponent.STATE_TAKE:
				// animate and remove from the JobBulletin list and engine
				if (state.getStateTime() <= 0.5f) {
					for (Fixture fixture : body.getFixtureList()) {
						Filter filter = fixture.getFilterData();
						filter.maskBits = GameManager.NOTHING_BIT;
						fixture.setFilterData(filter);
					}
					body.setTransform(body.getPosition().x, body.getPosition().y + 0.05f, 0);
				}
				else {
					// remove job from JobBulletin list, and remove entity from the engine
					JobBulletin jobBulletin = JobBulletin.getInstance();
					jobBulletin.removeJob(job);
					body.getWorld().destroyBody(body);
					getEngine().removeEntity(entity);
				}
				break;
			case NPC_ItemComponent.STATE_WAIT:
			default:
				job.location.set(body.getPosition());
				if (npc_ItemComponent.isTaken()) {
					state.setState(NPC_ItemComponent.STATE_TAKE);
				}
				break;
		}
    }
    
    protected float interpolate(float a) {
    	return 1 - MathUtils.cos(a * MathUtils.PI / 2);
    }

}
