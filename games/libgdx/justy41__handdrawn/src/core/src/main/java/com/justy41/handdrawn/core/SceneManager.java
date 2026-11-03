package com.justy41.handdrawn.core;

import java.util.ArrayList;

public class SceneManager {
    public ArrayList<Scene> scenes;
    int currentSceneId;
    int newId;
    boolean isChangingScenes;

    public SceneManager() {
        scenes = new ArrayList<>();
        currentSceneId = 0;
        isChangingScenes = false;
    }

    public <T extends Scene> void addScene(T scene) {
        scene.sceneManager = this;
        scene.ecs.sceneManager = this;

        scenes.add(scene);
        if(scenes.size() == 1) {
            currentSceneId = 0;
        }
    }

    public void changeScene(int id) {
        isChangingScenes = true;
        newId = id;
    }

    public Scene getCurrentScene() {
        return scenes.get(currentSceneId);
    }

    public void loopEnd() {
        if(isChangingScenes) {
            currentSceneId = newId;
            isChangingScenes = false;
        }
    }
}
