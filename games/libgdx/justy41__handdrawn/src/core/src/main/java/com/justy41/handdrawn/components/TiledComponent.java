package com.justy41.handdrawn.components;

import com.badlogic.gdx.maps.tiled.TiledMap;
import com.badlogic.gdx.maps.tiled.TmxMapLoader;

/**
 * Component that holds a TiledMap object.
 * An entity should be created and have this component before calling loadTiledObjects() function!
 */
public class TiledComponent extends Component{
    public TiledMap map;

    public TiledComponent(String path) {
        map = new TmxMapLoader().load(path);
    }
}
