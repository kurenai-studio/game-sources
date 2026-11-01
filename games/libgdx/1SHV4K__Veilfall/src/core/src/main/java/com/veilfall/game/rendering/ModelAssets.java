package com.veilfall.game.rendering;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.g3d.Model;
import com.badlogic.gdx.graphics.g3d.loader.ObjLoader;
import com.badlogic.gdx.utils.ObjectMap;
import com.badlogic.gdx.utils.Disposable;

/** Process-wide cache for the small static CC0 models shared by every fighter. */
public final class ModelAssets implements Disposable {
    private final ObjectMap<String, Model> models = new ObjectMap<>();
    private final ObjLoader loader = new ObjLoader();

    public Model get(String pack, String name) {
        String key = pack + "/" + name;
        Model model = models.get(key);
        if (model == null) {
            model = loader.loadModel(Gdx.files.internal("models/" + pack + "/" + name + ".obj"));
            models.put(key, model);
        }
        return model;
    }

    @Override public void dispose() {
        for (Model model : models.values()) model.dispose();
        models.clear();
    }
}
