# handdrawn

A little experiment project I've worked for a bit to see how to implement Tiled Parallax Scrolling backgrounds in libgdx. The art is hand-drawn in [Krita](https://krita.org/en/) and [Tiled](https://www.mapeditor.org/) was used for level editing (specifically the image layers and the object layers).

## Structure

The [Libgdx framework](https://libgdx.com/) for rendering and textures and it already has a Tiled importer built-in.  
The code structure is as follows:  

### Core
- a simple ECS class:
  - holds a handle of the OrthographicCamera and a handle to the SceneManager;
  - hashmaps that need to be manually added with every new component you make;
  - functions that act on the hashmaps (createEntity, addComponent);
- a StartScene that inherits from Scene class:
  - start function;
  - update function;
  - render function;
  - every scene holds an ECS class instance, a SceneManager instance and an OrthogonalTiledMapRenderer instance;
- a simple SceneManager:
  - manages the scenes in an ArrayList.

Ecs file:
```
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
```

### Components
- a base Component class:
  - has a handle for the hashmap key (the entity);
  - a boolean "enabled";
- TransformComponent;
- BoxCollider (Axis-Aligned-Bounding-Boxes -> AABB. Can be solid or just a trigger zone);
- RigidBody (velocity and gravity;
- SpriteRenderer;
- TiledComponent (holds a TiledMap);
- Player (data for the player character).

### Systems
- LoadSystems (handles importing the Object Layers from Tiled based on a "Type" custom property);
- UpdateSystem (handles physics and AABB collision resolutions);
- RenderSystems (handles texture drawing, debug drawing and Tiled Parallax Layer rendering);
- CameraSystems (handles cameraFollow function to follow a position);
- PlayerSystems (handles the player movement).

## Assets

The assets were drawn by me with the mouse, on my laptop. They are a simple sketch of a few hills using a simple collor pallete.  
The "red_pixel.png" assets is made for debug drawing of the colliders (since libgdx doesnt have a rectangle draw function).
The "tilemaps" and "tilesets" folders were made to better organise the tilemaps and tilesets loaded in Tiled.

The background was exported as individual layers and assembled in Tiled with Image Layers (one image/layer).  
The parallax value can be set for each Image Layer.

## Result
![handdrawn3](https://github.com/user-attachments/assets/cf37c81d-5ffe-4f16-aef5-dcef48e80185)
