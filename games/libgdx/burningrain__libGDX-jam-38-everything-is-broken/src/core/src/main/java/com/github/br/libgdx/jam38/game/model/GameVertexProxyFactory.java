package com.github.br.libgdx.jam38.game.model;

import com.github.br.libgdx.jam38.game.model.vertex.GameVertex;
import com.github.br.libgdx.jam38.game.model.vertex.GameVertexData;

public interface GameVertexProxyFactory {

    GameVertex createProxy(GameVertexData gameVertex);

}
