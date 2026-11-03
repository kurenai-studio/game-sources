package com.justy41.handdrawn.core;

import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.PerspectiveCamera;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.justy41.handdrawn.components.*;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Set;

public class Ecs {
    int nextEntity;
    public SceneManager sceneManager;
    public OrthographicCamera camera;
    private Set<Integer> freeIDs;
    private Set<Integer> entitiesToDestroy;

    // COMPONENT HASHMAPS
    public HashMap<Integer, TransformComponent> transforms;
    public HashMap<Integer, RigidBody> rigidbodies;
    public HashMap<Integer, SpriteRenderer> spriteRenderers;
    public HashMap<Integer, BoxCollider> boxColliders;
    public HashMap<Integer, Player> players;
    public HashMap<Integer, TiledComponent> tiledComponents;

    public Ecs() {
        nextEntity = -1;
        freeIDs = new HashSet<>();
        entitiesToDestroy = new HashSet<>();
        transforms = new HashMap<>();
        rigidbodies = new HashMap<>();
        spriteRenderers = new HashMap<>();
        boxColliders = new HashMap<>();
        players = new HashMap<>();
        tiledComponents = new HashMap<>();
        // Add here...
    }

    // Creates a new entity ID and allocates a new spot for it in every component hashmap.
    // The Ecs is using a list of unused IDs when creating a new entity.
    // If we have a free ID, we use it. If we don't, we move on with the nextEntity counter.
    // Free IDs come from deleted entities.
    // It's like recycling :) .
    public int createEntity() {
        int id;
        if(freeIDs.isEmpty()) {
            nextEntity++;
            id = nextEntity;
        }
        else {
            id = freeIDs.iterator().next();
            freeIDs.remove(id);
        }

        transforms.put(id, null);
        rigidbodies.put(id, null);
        spriteRenderers.put(id, null);
        boxColliders.put(id, null);
        players.put(id, null);
        tiledComponents.put(id, null);
        // Add here...
        return id;
    }

    public void destroyEntity(int entity) {
        entitiesToDestroy.add(entity);
    }

    // Adds component to a specified hashmap (ecs.name_of_the_hashmap).
    public <T extends Component> void addComponent(int entity, HashMap<Integer, T> componentMap, T component) {
        component.key = entity;
        component.enabled = true;
        componentMap.put(entity, component);
    }

    // Remove a component from a specified hashmap.
    public <T extends Component> void removeComponent(HashMap<Integer, T> componentMap, T component) {
        componentMap.remove(component.key);
    }

    // Called at the end of every frame to not interfere with iterating.
    public void processDeletions() {
        for(int entity : entitiesToDestroy) {
            transforms.remove(entity);
            rigidbodies.remove(entity);
            spriteRenderers.remove(entity);
            boxColliders.remove(entity);
            players.remove(entity);
            tiledComponents.remove(entity);
            // ...
            freeIDs.add(entity);
        }

        entitiesToDestroy.clear();
    }
}
