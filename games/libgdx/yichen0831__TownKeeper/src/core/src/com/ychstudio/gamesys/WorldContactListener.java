package com.ychstudio.gamesys;

import com.badlogic.ashley.core.Entity;
import com.badlogic.gdx.physics.box2d.Contact;
import com.badlogic.gdx.physics.box2d.ContactImpulse;
import com.badlogic.gdx.physics.box2d.ContactListener;
import com.badlogic.gdx.physics.box2d.Fixture;
import com.badlogic.gdx.physics.box2d.Manifold;
import com.ychstudio.ecs.components.NPC_ItemComponent;
import com.ychstudio.ecs.components.VillagerComponent;

public class WorldContactListener implements ContactListener {

    @Override
    public void beginContact(Contact contact) {
        Fixture fixtureA = contact.getFixtureA();
        Fixture fixtureB = contact.getFixtureB();
        
        if (fixtureA.getFilterData().categoryBits == GameManager.NPC_BIT || fixtureB.getFilterData().categoryBits == GameManager.NPC_BIT) {
            if (fixtureA.getFilterData().categoryBits == GameManager.NPC_ITEM_BIT) {
                if (fixtureB.getFilterData().categoryBits == GameManager.NPC_BIT) {
                    Entity entityItem = (Entity) fixtureA.getBody().getUserData();
                    Entity entityNPC = (Entity) fixtureB.getBody().getUserData();
                    
                    NPC_ItemComponent npc_Item = entityItem.getComponent(NPC_ItemComponent.class);
                    VillagerComponent villager = entityNPC.getComponent(VillagerComponent.class);
                    if (villager != null) {
                        // villager gets the item
                        npc_Item.taken();
                        
                        // villager gets the job
                        villager.acquiredJob = npc_Item.job;
                    }
                }
            }
            else {
                if (fixtureA.getFilterData().categoryBits == GameManager.NPC_BIT) {
                    Entity entityItem = (Entity) fixtureB.getBody().getUserData();
                    Entity entityNPC = (Entity) fixtureA.getBody().getUserData();
                    
                    NPC_ItemComponent npc_Item = entityItem.getComponent(NPC_ItemComponent.class);
                    VillagerComponent villager = entityNPC.getComponent(VillagerComponent.class);
                    if (villager != null) {
                        // villager gets the item
                        npc_Item.taken();
                        
                        // villager gets the job
                        villager.acquiredJob = npc_Item.job;
                    }
                }
            }
        }
    }

    @Override
    public void endContact(Contact contact) {
        
    }

    @Override
    public void preSolve(Contact contact, Manifold oldManifold) {
        
    }

    @Override
    public void postSolve(Contact contact, ContactImpulse impulse) {
        
    }

}
